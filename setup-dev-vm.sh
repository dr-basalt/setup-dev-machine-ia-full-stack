#!/bin/bash
# VM Development Environment Setup Script
# Usage: curl -fsSL https://raw.githubusercontent.com/your-repo/setup-dev-vm.sh | bash

set -e

echo "🚀 Starting Development VM Setup..."

# Variables
DOMAIN="dev.infra.ori3com.cloud"
USER="developer"
PASSWORD=$(openssl rand -base64 32)

# Update system
echo "📦 Updating system..."
apt update && apt upgrade -y
apt install -y curl wget git vim htop tree unzip software-properties-common

# Create developer user
echo "👤 Creating developer user..."
useradd -m -s /bin/bash $USER
usermod -aG sudo $USER
echo "$USER:$PASSWORD" | chpasswd

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER
systemctl enable docker

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Kubernetes tools
echo "☸️ Installing Kubernetes tools..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt install -y kubectl

# Install k3s (lightweight Kubernetes)
echo "🎯 Installing k3s..."
curl -sfL https://get.k3s.io | sh -
systemctl enable k3s

# Install Node.js via NodeSource
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install -g yarn pnpm

# Install Python and dependencies
echo "🐍 Installing Python..."
apt install -y python3 python3-pip python3-venv
pip3 install poetry uvicorn fastapi sqlalchemy alembic

# Install Go
echo "🚀 Installing Go..."
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

echo "✅ Base installation completed!"
echo "Password for user '$USER': $PASSWORD"
