#!/bin/bash
#================================================
# Panda Script v2.0 - Nginx Virtual Host
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

create_vhost() {
    local domain="$1"
    local php_version="${2:-8.3}"
    local doc_root="${3:-/var/www/$domain/public}"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    log_info "Creating virtual host for $domain..."
    
    # Create directories
    mkdir -p "$doc_root"
    mkdir -p "/var/www/$domain/logs"
    
    # Create vhost config
    cat > "/etc/nginx/sites-available/$domain" << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $domain www.$domain;
    root $doc_root;
    index index.php index.html;
    
    access_log /var/www/$domain/logs/access.log;
    error_log /var/www/$domain/logs/error.log;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\. {
        deny all;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    # Enable site
    mkdir -p /etc/nginx/sites-enabled
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
    
    # Test and reload
    if nginx -t &>/dev/null; then
        systemctl reload nginx
        log_success "Virtual host created: $domain"
    else
        log_error "Nginx config test failed"
        nginx -t
        return 1
    fi
    
    # Create default index
    echo "<?php phpinfo();" > "$doc_root/index.php"
    
    # Set permissions
    chown -R www-data:www-data "/var/www/$domain"
}

delete_vhost() {
    local domain="$1"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    if confirm "Delete virtual host $domain?"; then
        rm -f "/etc/nginx/sites-available/$domain"
        rm -f "/etc/nginx/sites-enabled/$domain"
        systemctl reload nginx
        log_success "Virtual host deleted: $domain"
    fi
}

list_vhosts() {
    echo "Virtual Hosts:"
    echo ""
    ls -1 /etc/nginx/sites-available/ 2>/dev/null | grep -v default
}

enable_ssl_vhost() {
    local domain="$1"
    local cert_path="${2:-/etc/letsencrypt/live/$domain}"
    
    cat > "/etc/nginx/sites-available/${domain}-ssl" << EOF
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name $domain www.$domain;
    root /var/www/$domain/public;
    index index.php index.html;
    
    ssl_certificate $cert_path/fullchain.pem;
    ssl_certificate_key $cert_path/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}

server {
    listen 80;
    server_name $domain www.$domain;
    return 301 https://\$server_name\$request_uri;
}
EOF

    ln -sf "/etc/nginx/sites-available/${domain}-ssl" "/etc/nginx/sites-enabled/"
    systemctl reload nginx
}
