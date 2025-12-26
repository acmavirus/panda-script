#!/bin/bash
#================================================
# Panda Script v2.0 - Nginx Installation
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

nginx_install() {
    log_info "Installing Nginx..."
    
    if is_debian; then
        apt-get update -y
        apt-get install -y nginx
    elif is_rhel; then
        dnf install -y nginx
    fi
    
    systemctl enable nginx
    systemctl start nginx
    
    configure_nginx_security
    
    log_success "Nginx installed"
}

configure_nginx_security() {
    log_info "Configuring Nginx security..."
    
    mkdir -p /etc/nginx/conf.d
    
    cat > /etc/nginx/conf.d/security.conf << 'EOF'
# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Hide Nginx version
server_tokens off;

# Limit request size
client_max_body_size 100M;
client_body_timeout 60s;
client_header_timeout 60s;

# Rate limiting zone
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=addr:10m;
EOF

    systemctl reload nginx
}

nginx_optimize() {
    log_info "Optimizing Nginx..."
    
    local ram_mb=$(get_ram_mb)
    local cpu_cores=$(get_cpu_cores)
    
    local worker_processes="auto"
    local worker_connections=4096
    
    if [[ $ram_mb -lt 1024 ]]; then
        worker_connections=1024
    elif [[ $ram_mb -lt 2048 ]]; then
        worker_connections=2048
    fi
    
    cat > /etc/nginx/nginx.conf << EOF
user www-data;
worker_processes $worker_processes;
worker_rlimit_nofile 65535;
pid /run/nginx.pid;

events {
    worker_connections $worker_connections;
    use epoll;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml;
    
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    systemctl reload nginx
    log_success "Nginx optimized"
}

nginx_status() {
    echo "Nginx Status:"
    print_status "Nginx" "$(get_service_status nginx)"
    nginx -v 2>&1 | grep "nginx version"
}
