#!/bin/bash
#================================================
# Panda Script v2.0 - Fix Permissions Tool
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

fix_web_permissions() {
    local domain="$1"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    if [[ ! -d "/var/www/$domain" ]]; then
        log_error "Directory /var/www/$domain not found!"
        return 1
    fi
    
    log_info "Fixing permissions for $domain..."
    
    local username=$(echo "$domain" | tr '.' '_' | cut -c1-16)
    
    # Ensure user exists
    if ! id "$username" &>/dev/null; then
        log_warning "User $username not found. Using www-data."
        username="www-data"
    fi
    
    # Ownership
    chown -R "$username:www-data" "/var/www/$domain"
    
    # Directories: 755
    find "/var/www/$domain" -type d -exec chmod 755 {} \;
    
    # Files: 644
    find "/var/www/$domain" -type f -exec chmod 644 {} \;
    
    # Sensitive files (wp-config.php etc)
    if [[ -f "/var/www/$domain/public/wp-config.php" ]]; then
        chmod 600 "/var/www/$domain/public/wp-config.php"
    fi
    
    log_success "Permissions fixed for $domain."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    fix_web_permissions "$1"
fi
