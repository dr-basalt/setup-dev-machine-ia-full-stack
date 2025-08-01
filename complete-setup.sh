#!/bin/bash
# complete-setup.sh - Master setup script

set -e

echo "🎯 Starting Complete Development VM Setup..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Get configuration
read -p "Enter your domain (e.g., dev.infra.ori3com.cloud): " DOMAIN
read -p "Enter developer username: " DEV_USER
read -s -p "Enter password for $DEV_USER: " DEV_PASSWORD
echo

# Run setup scripts
echo "📦 Running base setup..."
bash setup-dev-vm.sh

echo "🛠️ Installing development tools..."
bash dev-tools.sh

echo "🔐 Setting up security..."
bash setup-security.sh

echo "🌐 Configuring web services..."
bash setup-nginx.sh

echo "🧠 Setting up AI tools..."
bash setup-ai-tools.sh

# Start services
echo "🚀 Starting services..."
systemctl enable --now nginx
systemctl enable --now code-server@$DEV_USER
docker-compose -f docker-compose.dev.yml up -d

# Display access information
echo "✅ Setup completed!"
echo ""
echo "🌐 Access URLs:"
echo "  VS Code: https://$DOMAIN"
echo "  JupyterLab: https://$DOMAIN/jupyter"
echo "  Portainer: https://$DOMAIN/portainer"
echo "  N8N: http://$DOMAIN:5678"
echo "  Database Admin: http://$DOMAIN:8080"
echo ""
echo "👤 Credentials:"
echo "  User: $DEV_USER"
echo "  Password: $DEV_PASSWORD"
echo ""
echo "🔐 VPN Config: /root/client.conf (if WireGuard selected)"
