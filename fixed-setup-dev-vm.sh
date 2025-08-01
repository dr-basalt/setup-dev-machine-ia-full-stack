#!/bin/bash
# Fixed VM Development Environment Setup Script
# Usage: curl -fsSL https://raw.githubusercontent.com/your-repo/fixed-setup-dev-vm.sh | bash

set -e

echo "🚀 Starting Development VM Setup (Fixed Version)..."

# Variables
DOMAIN="${DOMAIN:-dev.infra.ori3com.cloud}"
USER="${DEV_USER:-developer}"
PASSWORD=$(openssl rand -base64 16)

# Update system
echo "📦 Updating system..."
apt update && apt upgrade -y
apt install -y curl wget git vim htop tree unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Create developer user
echo "👤 Creating developer user..."
if ! id "$USER" &>/dev/null; then
    useradd -m -s /bin/bash $USER
    usermod -aG sudo $USER
    echo "$USER:$PASSWORD" | chpasswd
    echo "Created user: $USER with password: $PASSWORD"
else
    echo "User $USER already exists"
fi

# Install Docker (already done based on your output)
echo "🐳 Docker already installed, ensuring proper setup..."
usermod -aG docker $USER
systemctl enable docker
systemctl start docker

# Install Docker Compose (already done)
echo "🔧 Docker Compose already installed"

# Install NEW Kubernetes repository
echo "☸️ Installing Kubernetes tools (NEW REPOSITORY)..."

# Remove old repository if exists
rm -f /etc/apt/sources.list.d/kubernetes.list

# Add new Kubernetes repository (pkgs.k8s.io)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# Update and install kubectl
apt update
apt install -y kubectl

# Verify kubectl installation
kubectl version --client || echo "kubectl installed successfully"

# Install k3s (lightweight Kubernetes)
echo "🎯 Installing k3s..."
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
systemctl enable k3s

# Wait for k3s to be ready
echo "⏳ Waiting for k3s to be ready..."
sleep 10

# Copy k3s config for regular user
mkdir -p /home/$USER/.kube
cp /etc/rancher/k3s/k3s.yaml /home/$USER/.kube/config
chown $USER:$USER /home/$USER/.kube/config
chmod 600 /home/$USER/.kube/config

# Install Node.js via NodeSource
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install -g yarn pnpm

# Install Python and dependencies
echo "🐍 Installing Python..."
apt install -y python3 python3-pip python3-venv python3-dev build-essential
pip3 install --break-system-packages poetry uvicorn fastapi sqlalchemy alembic

# Install Go
echo "🚀 Installing Go..."
GO_VERSION="1.21.5"
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/$USER/.bashrc

# Install additional development tools
echo "🛠️ Installing additional development tools..."

# VS Code Server
echo "📝 Installing VS Code Server..."
curl -fsSL https://code-server.dev/install.sh | sh
systemctl enable code-server@$USER

# Configure VS Code Server
mkdir -p /home/$USER/.config/code-server
CODE_PASSWORD=$(openssl rand -base64 16)
cat > /home/$USER/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8443
auth: password
password: $CODE_PASSWORD
cert: false
EOF

chown -R $USER:$USER /home/$USER/.config

# Install VS Code extensions
echo "🔌 Installing VS Code extensions..."
sudo -u $USER code-server --install-extension ms-python.python
sudo -u $USER code-server --install-extension bradlc.vscode-tailwindcss
sudo -u $USER code-server --install-extension ms-vscode.vscode-typescript-next
sudo -u $USER code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
sudo -u $USER code-server --install-extension continue.continue

# Install JupyterLab
echo "🧪 Installing JupyterLab..."
pip3 install --break-system-packages jupyterlab notebook ipywidgets

# Configure JupyterLab for the user
sudo -u $USER jupyter lab --generate-config

JUPYTER_PASSWORD=$(openssl rand -base64 12)
JUPYTER_HASH=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")

cat > /home/$USER/.jupyter/jupyter_lab_config.py << EOF
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.password = '$JUPYTER_HASH'
c.ServerApp.allow_root = False
c.ServerApp.allow_remote_access = True
EOF

chown -R $USER:$USER /home/$USER/.jupyter

# Install Portainer
echo "🐳 Installing Portainer..."
docker volume create portainer_data
docker run -d -p 9443:9443 -p 8000:8000 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# Install GitHub CLI
echo "🐙 Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update && apt install -y gh

# Install Nginx
echo "🌐 Installing Nginx..."
apt install -y nginx

# Basic Nginx configuration
cat > /etc/nginx/sites-available/dev-vm << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:8443;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Accept-Encoding gzip;
    }

    location /jupyter {
        proxy_pass http://localhost:8888;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
    }

    location /portainer/ {
        proxy_pass https://localhost:9443/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/dev-vm /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl enable nginx && systemctl start nginx

# Create docker-compose file for development services
echo "📦 Creating development services docker-compose..."
cat > /home/$USER/docker-compose.dev.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: dev_postgres
    environment:
      POSTGRES_DB: social_media_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: dev_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

  n8n:
    image: n8nio/n8n
    container_name: dev_n8n
    ports:
      - "5678:5678"
    environment:
      N8N_BASIC_AUTH_ACTIVE: true
      N8N_BASIC_AUTH_USER: admin
      N8N_BASIC_AUTH_PASSWORD: admin123
      N8N_HOST: localhost
      N8N_PORT: 5678
      N8N_PROTOCOL: http
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped

  adminer:
    image: adminer
    container_name: dev_adminer
    ports:
      - "8080:8080"
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  n8n_data:
EOF

chown $USER:$USER /home/$USER/docker-compose.dev.yml

# Start services
echo "🚀 Starting services..."
systemctl start code-server@$USER
cd /home/$USER && sudo -u $USER docker-compose -f docker-compose.dev.yml up -d

# Create startup script for user services
cat > /home/$USER/start-services.sh << EOF
#!/bin/bash
echo "🚀 Starting development services..."
docker-compose -f docker-compose.dev.yml up -d
sudo systemctl start code-server@$USER
sudo systemctl start nginx
echo "✅ Services started!"
echo ""
echo "🌐 Access URLs:"
echo "  VS Code: http://$DOMAIN (password: $CODE_PASSWORD)"
echo "  JupyterLab: http://$DOMAIN/jupyter (password: $JUPYTER_PASSWORD)"
echo "  Portainer: http://$DOMAIN/portainer"
echo "  N8N: http://$DOMAIN:5678 (admin/admin123)"
echo "  Database Admin: http://$DOMAIN:8080"
EOF

chmod +x /home/$USER/start-services.sh
chown $USER:$USER /home/$USER/start-services.sh

# Firewall configuration
echo "🔥 Configuring UFW firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 5678  # N8N
ufw allow 8080  # Adminer

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "🌐 Access URLs:"
echo "  VS Code: http://$DOMAIN"
echo "  JupyterLab: http://$DOMAIN/jupyter"
echo "  Portainer: http://$DOMAIN/portainer"
echo "  N8N: http://$DOMAIN:5678"
echo "  Database Admin: http://$DOMAIN:8080"
echo ""
echo "🔐 Credentials:"
echo "  System User: $USER"
echo "  System Password: $PASSWORD"
echo "  VS Code Password: $CODE_PASSWORD"
echo "  JupyterLab Password: $JUPYTER_PASSWORD"
echo "  N8N: admin/admin123"
echo ""
echo "📁 Project directory: /home/$USER"
echo "🚀 Start services: /home/$USER/start-services.sh"
echo ""
echo "🔧 Next steps:"
echo "  1. Configure DNS: $DOMAIN -> $(curl -s ifconfig.me)"
echo "  2. Setup SSL with: certbot --nginx -d $DOMAIN"
echo "  3. Login to VS Code and start coding!"
