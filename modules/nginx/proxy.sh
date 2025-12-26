#!/bin/bash
#================================================
# Panda Script v2.2.1 - Nginx Proxy Bridge
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

create_proxy_config() {
    local domain=$1
    local port=$2
    
    [[ -z "$domain" || -z "$port" ]] && { log_error "Domain and Port required."; return 1; }
    
    local conf_file="/etc/nginx/sites-available/$domain"
    
    log_info "Creating Nginx Reverse Proxy for $domain -> 127.0.0.1:$port..."
    
    cat <<EOF > "$conf_file"
server {
    listen 80;
    server_name $domain;

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
}
EOF

    ln -sf "$conf_file" "/etc/nginx/sites-enabled/"
    nginx -t &>/dev/null && systemctl reload nginx
    log_success "Reverse Proxy configured for $domain."
}

proxy_bridge_wizard() {
    local domain=$(prompt "Enter domain for proxy")
    local port=$(prompt "Enter internal port (e.g. 3000, 8080)")
    
    create_proxy_config "$domain" "$port"
    pause
}
