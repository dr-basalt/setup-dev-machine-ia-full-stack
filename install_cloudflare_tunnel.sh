#!/bin/bash
# Setup Cloudflare Tunnel (recommandé)

echo "☁️ Installing Cloudflare Tunnel..."

# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb

# Login and create tunnel (interactive)
echo "Run these commands manually:"
echo "cloudflared tunnel login"
echo "cloudflared tunnel create dev-vm"
echo "cloudflared tunnel route dns dev-vm dev.infra.ori3com.cloud"

# Create config
mkdir -p /home/$USER/.cloudflared
cat > /home/$USER/.cloudflared/config.yml << EOF
tunnel: YOUR_TUNNEL_ID
credentials-file: /home/$USER/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: dev.infra.ori3com.cloud
    service: http://localhost:8443
  - hostname: jupyter.dev.infra.ori3com.cloud
    service: http://localhost:8888
  - hostname: portainer.dev.infra.ori3com.cloud
    service: https://localhost:9443
  - service: http_status:404
EOF

# Install as service
cloudflared service install
systemctl enable cloudflared
