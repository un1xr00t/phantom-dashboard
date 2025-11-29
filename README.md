# Phantom C2 API Server

FastAPI-based Command & Control API that bridges the Flutter app to Phantom Printer dropboxes via SSH tunnel.

## Quick Setup

```bash
# On your Linode VPS
cd /opt
git clone https://github.com/un1xr00t/phantom-dashboard.git
cd phantom-dashboard/server

# Run the setup script
chmod +x setup.sh
./setup.sh
```

## Manual Setup

### 1. Install Dependencies

```bash
apt update && apt install -y python3 python3-pip python3-venv netcat-openbsd rsync
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn pydantic
```

### 2. Generate SSL Certificates

```bash
mkdir -p /opt/phantom-c2/certs
openssl req -x509 -newkey rsa:4096 \
  -keyout /opt/phantom-c2/certs/key.pem \
  -out /opt/phantom-c2/certs/cert.pem \
  -days 365 -nodes -subj "/CN=phantom-c2"
```

### 3. Generate API Key

```bash
API_KEY=$(openssl rand -hex 32)
cat > /opt/phantom-c2/.env << EOF
PHANTOM_API_KEY=${API_KEY}
SSH_TUNNEL_PORT=2222
DROPBOX_USER=kali
EOF

echo "Save this API key: ${API_KEY}"
```

### 4. SSH Key for Dropbox Access

```bash
ssh-keygen -t ed25519 -f /root/.ssh/id_dropbox -N ""
# Copy public key to your Pi dropbox
ssh-copy-id -i /root/.ssh/id_dropbox.pub kali@PI_IP
```

### 5. Install Systemd Service

```bash
cat > /etc/systemd/system/phantom-c2.service << 'EOF'
[Unit]
Description=Phantom Printer C2 API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/phantom-c2
EnvironmentFile=/opt/phantom-c2/.env
ExecStart=/opt/phantom-c2/venv/bin/python /opt/phantom-c2/c2_api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable phantom-c2
systemctl start phantom-c2
```

### 6. Open Firewall

```bash
ufw allow 8443/tcp comment 'Phantom C2 API'
ufw allow 2222/tcp comment 'SSH Tunnel'
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/dropboxes` | GET | List dropboxes |
| `/api/dropboxes/{id}` | GET | Dropbox details |
| `/api/dropboxes/{id}/command` | POST | Execute command |
| `/api/dropboxes/{id}/commands` | GET | Command history |
| `/api/dropboxes/{id}/loot/summary` | GET | Loot stats |
| `/api/dropboxes/{id}/loot/credentials` | GET | Credentials |
| `/api/dropboxes/{id}/loot/hashes` | GET | Hashes |
| `/api/dropboxes/{id}/loot/hosts` | GET | Discovered hosts |

## Testing

```bash
# Health check
curl -sk -H "X-API-Key: YOUR_KEY" https://localhost:8443/api/health

# List dropboxes
curl -sk -H "X-API-Key: YOUR_KEY" https://localhost:8443/api/dropboxes

# Execute command
curl -sk -X POST -H "X-API-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"command": "execute_shell", "args": {"cmd": "whoami"}}' \
  https://localhost:8443/api/dropboxes/DROPBOX_ID/command
```

## Logs

```bash
# View logs
journalctl -u phantom-c2 -f

# Check status
systemctl status phantom-c2
```
