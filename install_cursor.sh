#!/bin/bash
# Install Cursor-like environment

echo "🤖 Setting up AI Development Environment..."

# Install Continue.dev extension for VS Code Server
sudo -u $USER code-server --install-extension continue.continue

# Configure Continue.dev
mkdir -p /home/$USER/.continue
cat > /home/$USER/.continue/config.json << EOF
{
  "models": [
    {
      "title": "Claude 3.5 Sonnet",
      "provider": "anthropic",
      "model": "claude-3-5-sonnet-20241022",
      "apiKey": "YOUR_ANTHROPIC_API_KEY"
    },
    {
      "title": "GPT-4",
      "provider": "openai",
      "model": "gpt-4",
      "apiKey": "YOUR_OPENAI_API_KEY"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Codestral",
    "provider": "mistral",
    "model": "codestral-latest",
    "apiKey": "YOUR_MISTRAL_API_KEY"
  }
}
EOF

# Install Ollama for local AI
echo "🦙 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh
systemctl enable ollama

# Pull useful models
ollama pull codellama:7b
ollama pull llama2:7b
ollama pull mistral:7b

# Install Open WebUI for Ollama
echo "🌐 Installing Open WebUI..."
docker run -d --network=host -v open-webui:/app/backend/data \
  --name open-webui --restart always \
  -e OLLAMA_API_BASE_URL=http://127.0.0.1:11434/api \
  ghcr.io/open-webui/open-webui:main
