#!/bin/bash
#================================================
# Panda Script v2.0 - Website Create
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

create_website() {
    local domain="$1"
    local php_version="${2:-8.3}"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    is_valid_domain "$domain" || { log_error "Invalid domain: $domain"; return 1; }
    
    log_info "Creating website: $domain"
    
    local username=$(echo "$domain" | tr '.' '_' | cut -c1-16)
    local doc_root="/home/$domain/public"
    
    # Create user
    if ! id "$username" &>/dev/null; then
        useradd -m -d "/home/$domain" -s /bin/bash "$username"
    fi
    
    # Create directories
    mkdir -p "$doc_root"
    mkdir -p "/home/$domain/logs"
    mkdir -p "/home/$domain/tmp"
    
    # Create vhost
    source "$PANDA_DIR/modules/nginx/vhost.sh"
    create_vhost "$domain" "$php_version" "$doc_root"
    
    # Create PHP-FPM pool
    create_php_pool "$domain" "$username" "$php_version"
    
    # Set permissions
    chown -R "$username:$username" "/home/$domain"
    chmod 755 "/home/$domain"
    
    # Save to database
    db_query "INSERT INTO websites (domain, username, document_root, php_version) VALUES ('$domain', '$username', '$doc_root', '$php_version')"
    
    log_success "Website created: $domain"
    echo "Document root: $doc_root"
    echo "User: $username"
}

create_php_pool() {
    local domain="$1"
    local username="$2"
    local php_version="${3:-8.3}"
    
    local pool_dir="/etc/php/${php_version}/fpm/pool.d"
    [[ ! -d "$pool_dir" ]] && pool_dir="/etc/php-fpm.d"
    
    cat > "$pool_dir/${domain}.conf" << EOF
[$domain]
user = $username
group = $username
listen = /var/run/php/php-${domain}.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500
php_admin_value[open_basedir] = /home/$domain:/tmp
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen
EOF

    systemctl reload php${php_version}-fpm 2>/dev/null || systemctl reload php-fpm
}

delete_website() {
    local domain="$1"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    if confirm_danger "Delete website $domain and all data?" "$domain"; then
        local username=$(echo "$domain" | tr '.' '_' | cut -c1-16)
        
        rm -f "/etc/nginx/sites-enabled/$domain"*
        rm -f "/etc/nginx/sites-available/$domain"*
        rm -rf "/home/$domain"
        userdel -r "$username" 2>/dev/null
        
        db_query "DELETE FROM websites WHERE domain='$domain'"
        
        systemctl reload nginx
        log_success "Website deleted: $domain"
    fi
}

list_websites() {
    echo "Websites:"
    echo ""
    db_query "SELECT domain, php_version, ssl_enabled, status FROM websites" | while IFS='|' read -r domain php ssl status; do
        echo "  • $domain (PHP $php, SSL: $([[ $ssl == 1 ]] && echo Yes || echo No))"
    done
}
