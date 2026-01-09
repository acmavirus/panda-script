---
description: Install Panda Script on VPS 15.235.199.163 (ubuntu)
---

## VPS Information
- **IP**: 15.235.199.163
- **User**: ubuntu (sudo required)
- **SSH**: `ssh ubuntu@15.235.199.163`

## Prerequisites
Ensure SSH key is already added to the VPS.

## Workflow Steps

### 1. Connect and Check System
// turbo
```bash
ssh ubuntu@15.235.199.163 "uname -a && cat /etc/os-release | head -5"
```

### 2. Install Dependencies
Install essential packages needed for Panda Script:
```bash
ssh ubuntu@15.235.199.163 "sudo apt-get update -qq && sudo apt-get install -y curl wget git sqlite3 unzip jq gnupg2 ca-certificates lsb-release software-properties-common"
```

### 3. Install Nginx
```bash
ssh ubuntu@15.235.199.163 "sudo apt-get install -y nginx && sudo systemctl start nginx && sudo systemctl enable nginx && sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled"
```

### 4. Install PHP 8.3
```bash
ssh ubuntu@15.235.199.163 "sudo add-apt-repository -y ppa:ondrej/php && sudo apt-get update -qq && sudo apt-get install -y php8.3 php8.3-fpm php8.3-cli php8.3-common php8.3-mysql php8.3-zip php8.3-gd php8.3-mbstring php8.3-curl php8.3-xml php8.3-bcmath php8.3-intl php8.3-readline php8.3-opcache php8.3-soap php8.3-imagick php8.3-redis && sudo systemctl start php8.3-fpm && sudo systemctl enable php8.3-fpm"
```

### 5. Install MariaDB
```bash
ssh ubuntu@15.235.199.163 "sudo apt-get install -y mariadb-server mariadb-client && sudo systemctl start mariadb && sudo systemctl enable mariadb"
```

### 6. Install Go 1.24+
```bash
ssh ubuntu@15.235.199.163 "wget -q https://go.dev/dl/go1.24.0.linux-amd64.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz && rm go1.24.0.linux-amd64.tar.gz && echo 'export PATH=\$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile.d/go.sh && source /etc/profile.d/go.sh && /usr/local/go/bin/go version"
```

### 7. Install Node.js 20+
```bash
ssh ubuntu@15.235.199.163 "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs && node -v && npm -v"
```

### 8. Install Additional Tools (Certbot, Composer, WP-CLI)
```bash
ssh ubuntu@15.235.199.163 "sudo apt-get install -y certbot python3-certbot-nginx && curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp"
```

### 9. Clone Panda Script Repository
```bash
ssh ubuntu@15.235.199.163 "sudo git clone https://github.com/acmavirus/panda-script.git /opt/panda && sudo mkdir -p /opt/panda/data /opt/panda/logs /opt/panda/databases /opt/panda/backups /etc/panda /var/log/panda /home && sudo chmod +x /opt/panda/menu/*.sh /opt/panda/core/*.sh 2>/dev/null || true"
```

### 10. Build Panda Panel (Go Backend)
```bash
ssh ubuntu@15.235.199.163 "cd /opt/panda/v3 && sudo /usr/local/go/bin/go mod tidy && sudo /usr/local/go/bin/go build -o panda-linux main.go && sudo chmod +x panda-linux && sudo ln -sf /opt/panda/v3/panda-linux /usr/local/bin/panda-panel"
```

### 11. Build Web Panel (Frontend)
```bash
ssh ubuntu@15.235.199.163 "cd /opt/panda/v3/web && sudo npm install && sudo npm run build"
```

### 12. Create Systemd Service
```bash
ssh ubuntu@15.235.199.163 "sudo tee /etc/systemd/system/panda.service > /dev/null <<'EOF'
[Unit]
Description=Panda Panel v3
After=network.target nginx.service mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/panda/v3
ExecStart=/opt/panda/v3/panda-linux serve
Restart=always
RestartSec=5
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF"
```

### 13. Start Panda Service
// turbo
```bash
ssh ubuntu@15.235.199.163 "sudo systemctl daemon-reload && sudo systemctl enable panda && sudo systemctl start panda && sleep 3 && sudo systemctl status panda"
```

### 14. Create CLI Symlink
// turbo
```bash
ssh ubuntu@15.235.199.163 "sudo ln -sf /opt/panda/menu/main.sh /usr/local/bin/panda"
```

### 15. Verify Installation
// turbo
```bash
ssh ubuntu@15.235.199.163 "curl -s http://localhost:8888/api/health && echo '' && echo 'Panel URL: http://15.235.199.163:8888/panda' && echo 'Login: admin / admin'"
```

## Quick Deploy/Update (After Initial Install)
// turbo
```bash
ssh ubuntu@15.235.199.163 "cd /opt/panda && sudo git fetch origin && sudo git reset --hard origin/main && cd v3/web && sudo npm run build && cd .. && sudo /usr/local/go/bin/go mod tidy && sudo /usr/local/go/bin/go build -o panda-linux main.go && sudo chmod +x panda-linux && sudo systemctl restart panda"
```

## Troubleshooting

### Check Service Status
```bash
ssh ubuntu@15.235.199.163 "sudo systemctl status panda && sudo journalctl -u panda -n 50"
```

### Check Ports
```bash
ssh ubuntu@15.235.199.163 "sudo netstat -tlnp | grep -E '8888|80|443|3306'"
```

### Restart Services
```bash
ssh ubuntu@15.235.199.163 "sudo systemctl restart nginx php8.3-fpm mariadb panda"
```

## Access Information
- **Panel URL**: http://15.235.199.163:8888/panda
- **Default Login**: admin / admin
- **CLI Command**: `panda` (on VPS)
- **MySQL Credentials**: `/etc/panda/.mysql_credentials`
