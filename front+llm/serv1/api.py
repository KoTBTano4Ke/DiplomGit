from flask import Flask, request, jsonify
import pickle
import torch
from openai import OpenAI
from vectordb import get_embedding

def get_relevant_context(rewritten_input, vault_embeddings, vault_content, top_k=5):
    if vault_embeddings.nelement() == 0:  
        return []
    input_embedding = get_embedding(rewritten_input)
    cos_scores = torch.cosine_similarity(torch.tensor(input_embedding).unsqueeze(0), vault_embeddings)
    top_k = min(top_k, len(cos_scores))
    top_indices = torch.topk(cos_scores, k=top_k)[1].tolist()
    relevant_context = []
    for idx in top_indices:
        context = vault_content[idx].strip()
        relevant_context.append(context)

    return relevant_context

def rewrite_query(user_input, conversation_history, ollama_model):
    last_two_messages = conversation_history[-2:]

    context = ""
    for msg in last_two_messages:
        message = f"{msg['role']}: {msg['content']}"
        context += message + "\n"

    prompt = f"""Rewrite the following query by incorporating relevant context from the conversation history.
    The rewritten query should:
    
    - Preserve the core intent and meaning of the original query
    - Expand and clarify the query to make it more specific and informative for retrieving relevant context
    - Avoid introducing new topics or queries that deviate from the original query
    - DONT EVER ANSWER the Original query, but instead focus on rephrasing and expanding it into a new query
    
    Return ONLY the rewritten query text, without any additional formatting or explanations.
    
    Conversation History:
    {context}
    
    Original query: [{user_input}]
    
    Rewritten query: 
    """
    response = client.chat.completions.create(
        model=ollama_model,
        messages=[{"role": "system", "content": prompt}],
        max_tokens=200,
        n=1,
        temperature=0.1,
    )
    return response.choices[0].message.content.strip()

def ollama_chat(user_input, system_message, vault_embeddings, vault_content, ollama_model, conversation_history): 

    conversation_history.append({"role": "user", "content": user_input})

    if len(conversation_history) > 1:
        rewritten_query = rewrite_query(user_input, conversation_history, ollama_model)
    else:
        rewritten_query = user_input
    print(f"REWRITTEN QUERY: {rewritten_query}")

    relevant_context = get_relevant_context(rewritten_query, vault_embeddings, vault_content)
    if relevant_context:
        context_str = "\n".join(relevant_context)
    else:
        print("No relevant context found.")
    print(f"RELEVANT CONTEXT: {relevant_context}")
    
    user_input_with_context = user_input
    if relevant_context:
        user_input_with_context = user_input + "\n\nRelevant Context:\n" + context_str
    
    conversation_history[-1]["content"] = user_input_with_context
    
    messages = [
        {"role": "system", "content": system_message},
        *conversation_history
    ]
    
    response = client.chat.completions.create(
        model=ollama_model,
        messages=messages,
        max_tokens=2000,
    )
    
    conversation_history.append({"role": "assistant", "content": response.choices[0].message.content})
    
    return response.choices[0].message.content

with open('vault_content.pkl', 'rb') as f:
    vault_content = pickle.load(f)

vault_embeddings_tensor = torch.load('vault_embeddings_tensor.pth')

ollama_model = "llama3"


client = OpenAI(
    base_url='http://localhost:11434/v1',
    api_key='llama3'
)
system_message = "You are a helpful assistant, your name is VeiderGPT, people use you for asking questions about Gym, also you are helpful assistant that is an expert at extracting the most useful information from a given text. Also bring in extra relevant infromation to the user query from outside the given context."

conversation_history = []


app = Flask(__name__)

@app.route('/chat', methods=['POST'])
def chat():
  data = request.get_json()
  prompt = data.get('prompt')
  
  if prompt:
    response = ollama_chat(prompt, system_message, vault_embeddings_tensor, vault_content, ollama_model, conversation_history)
    
    response_data = {'response': response}
    
    return jsonify(response_data)
  
  return jsonify({'error': 'Please provide a prompt in the request body'})

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=5000, debug=True)