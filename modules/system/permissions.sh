#!/bin/bash
#================================================
# Panda Script v2.0 - Fix Permissions Tool
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

fix_web_permissions() {
    local domain="$1"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    if [[ ! -d "/home/$domain" ]]; then
        log_error "Directory /home/$domain not found!"
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
    chown -R "$username:www-data" "/home/$domain"
    
    # Directories: 755, Files: 644
    find "/home/$domain" -type d -exec chmod 755 {} \;
    find "/home/$domain" -type f -exec chmod 644 {} \;
    
    # --- Framework Awareness ---
    
    # Laravel Detection
    if [[ -f "/home/$domain/artisan" ]]; then
        log_info "Framework: Laravel detected. Optimizing storage and cache permissions..."
        if [[ -d "/home/$domain/storage" ]]; then
            chmod -R 775 "/home/$domain/storage"
        fi
        if [[ -d "/home/$domain/bootstrap/cache" ]]; then
            chmod -R 775 "/home/$domain/bootstrap/cache"
        fi
    fi
    
    # WordPress Detection
    if [[ -f "/home/$domain/public/wp-config.php" ]]; then
        log_info "Framework: WordPress detected. Hardening wp-config.php..."
        chmod 440 "/home/$domain/public/wp-config.php"
    elif [[ -f "/home/$domain/wp-config.php" ]]; then
        log_info "Framework: WordPress detected. Hardening wp-config.php..."
        chmod 440 "/home/$domain/wp-config.php"
    fi
    
    log_success "Permissions fixed for $domain."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    fix_web_permissions "$1"
fi
