import torch
import ollama
import os
import pickle

## Создает embeddings для начального датасета
def load_vault_embeddings(file_path):
    if not os.path.exists(file_path):
        print("There is no such file")
        return torch.tensor([]), []

    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.read().splitlines()

    embeddings = []
    for line in lines:
        try:
            embedding = get_embedding(line)
            embeddings.append(embedding)
        except Exception as e:
            print(f"Failed to get embedding for: {line}\nError: {e}")
            
    return torch.tensor(embeddings), lines

def get_embedding(text):
    model = 'mxbai-embed-large'
    return ollama.embeddings(model=model, prompt=text)["embedding"]


text_file = "vault.txt"
vault_embeddings_tensor, vault_content = load_vault_embeddings(text_file)

torch.save(vault_embeddings_tensor, 'vault_embeddings_tensor.pth')

with open('vault_content.pkl', 'wb') as f:
    pickle.dump(vault_content, f)