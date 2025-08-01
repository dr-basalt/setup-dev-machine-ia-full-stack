#!/bin/bash
# Install WireGuard VPN Server

echo "🔐 Installing WireGuard VPN..."

# Install WireGuard
apt install -y wireguard

# Generate server keys
cd /etc/wireguard
wg genkey | tee server-private.key | wg pubkey > server-public.key
chmod 600 server-private.key

# Create server config
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat server-private.key)
Address = 10.8.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client configuration will be added here
EOF

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# Start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Generate client config
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)

cat > client.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.8.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat server-public.key)
Endpoint = YOUR_SERVER_IP:51820
AllowedIPs = 10.8.0.0/24
PersistentKeepalive = 25
EOF

# Add client to server config
echo "" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = $CLIENT_PUBLIC_KEY" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = 10.8.0.2/32" >> /etc/wireguard/wg0.conf

systemctl restart wg-quick@wg0

echo "✅ WireGuard configured! Client config saved to client.conf"
