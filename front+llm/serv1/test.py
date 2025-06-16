import requests
import json

# Replace with your API endpoint URL
url = "http://192.168.1.96:5001/chat"

# Define your test prompt
prompt = "what do you know about NUSQAU team?"

# Prepare data for JSON request
data = {"prompt": prompt}

# Send POST request with JSON data
response = requests.post(url, json=data)

# Check for successful response
if response.status_code == 200:
  # Parse JSON response
  response_data = json.loads(response.text)
  generated_response = response_data.get("response")
  
  # Print the generated response
  print(f"API Response: {generated_response}")
else:
  print(f"Error: API returned status code {response.status_code}")