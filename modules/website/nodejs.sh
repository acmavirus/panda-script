#!/bin/bash
#================================================
# Panda Script v2.0 - Node.js & PM2 Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_node_env() {
    log_info "Installing Node.js environment (NVM, Node, PM2)..."
    
    # Install NVM if not exists
    if [[ ! -d "$HOME/.nvm" ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    nvm install --lts
    nvm use --lts
    
    # Install PM2 globally
    npm install -g pm2
    
    log_success "Node.js $(node -v) and PM2 installed successfully!"
}

create_node_website() {
    local domain="$1"
    local port="$2"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    [[ -z "$port" ]] && { log_error "Port required (e.g., 3000)"; return 1; }
    
    is_valid_domain "$domain" || { log_error "Invalid domain: $domain"; return 1; }
    
    log_info "Creating Node.js website (Reverse Proxy) for $domain on port $port"
    
    local doc_root="/var/www/$domain/public"
    mkdir -p "$doc_root"
    
    # Create Nginx Reverse Proxy Config
    cat > "/etc/nginx/sites-available/$domain" << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root $doc_root;

    index index.html index.htm;

    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    access_log /var/www/$domain/logs/access.log;
    error_log /var/www/$domain/logs/error.log;
}
EOF

    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    nginx -t && systemctl reload nginx
    
    # Create sample app.js if directory is empty
    if [[ ! -f "$doc_root/app.js" ]]; then
        cat > "$doc_root/app.js" << EOF
const http = require('http');
const port = $port;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World from Panda Script Node.js App\\n');
});

server.listen(port, () => {
  console.log(\`Server running at http://localhost:\${port}/\`);
});
EOF
        log_info "Created sample app.js in $doc_root"
    fi
    
    log_success "Node.js website $domain created! Use PM2 to start your app."
    echo "Example: cd $doc_root && pm2 start app.js --name $domain"
}

manage_pm2() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ 🚀 PM2 Process Manager                                   ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    pm2 status
    echo ""
    echo "  1. Restart All Apps"
    echo "  2. Stop All Apps"
    echo "  3. Save PM2 List (for auto-boot)"
    echo "  4. View Logs"
    echo "  0. Back"
    echo ""
    read -p "Choice: " pchoice
    case $pchoice in
        1) pm2 restart all; pause ;;
        2) pm2 stop all; pause ;;
        3) pm2 save; pm2 startup; pause ;;
        4) pm2 logs --lines 50; pause ;;
        *) return ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_node_website "$1" "$2"
fi
