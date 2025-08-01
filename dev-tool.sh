#!/bin/bash
# Development Tools Installation

echo "🛠️ Installing Development Tools..."

# VS Code Server
echo "📝 Installing VS Code Server..."
curl -fsSL https://code-server.dev/install.sh | sh
systemctl enable --now code-server@$USER

# Configure VS Code Server
mkdir -p /home/$USER/.config/code-server
cat > /home/$USER/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8443
auth: password
password: $(openssl rand -base64 16)
cert: false
EOF

# Install VS Code extensions for your stack
sudo -u $USER code-server --install-extension ms-python.python
sudo -u $USER code-server --install-extension bradlc.vscode-tailwindcss
sudo -u $USER code-server --install-extension ms-vscode.vscode-typescript-next
sudo -u $USER code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

# JupyterLab pour AI/Data Science
echo "🧪 Installing JupyterLab..."
pip3 install jupyterlab notebook
jupyter lab --generate-config

# Configure JupyterLab
cat >> /home/$USER/.jupyter/jupyter_lab_config.py << EOF
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.password = '$(python3 -c "from jupyter_server.auth import passwd; print(passwd('jupyter123'))")'
EOF

# Portainer for Docker management
echo "🐳 Installing Portainer..."
docker volume create portainer_data
docker run -d -p 9443:9443 -p 8000:8000 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# Install GitHub CLI
echo "🐙 Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update && apt install -y gh

echo "✅ Development tools installed!"
