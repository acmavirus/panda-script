#!/bin/bash
#================================================
# Panda Script v2.2 - Webhook Setup Tool
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

setup_webhook() {
    local domain="$1"
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    local public_root="/var/www/$domain/public"
    [[ ! -d "$public_root" ]] && { log_error "Public root $public_root not found."; return 1; }
    
    local secret=$(generate_password 16)
    
    log_info "Setting up Webhook for $domain..."
    
    cp "$PANDA_DIR/templates/panda-webhook.php" "$public_root/panda-webhook.php"
    
    # Configure PHP template
    sed -i "s/YOUR_PANDA_SECRET/$secret/" "$public_root/panda-webhook.php"
    sed -i "s/YOUR_DOMAIN/$domain/" "$public_root/panda-webhook.php"
    
    # Set permissions
    local username=$(echo "$domain" | tr '.' '_' | cut -c1-16)
    chown "$username:www-data" "$public_root/panda-webhook.php"
    
    # Allow www-data to run panda deploy for this domain
    if ! grep -q "www-data ALL=(ALL) NOPASSWD: /usr/local/bin/panda deploy" /etc/sudoers; then
        echo "www-data ALL=(ALL) NOPASSWD: /usr/local/bin/panda deploy *" >> /etc/sudoers
        log_info "Added www-data to sudoers for panda deploy."
    fi
    
    log_success "Webhook setup completed!"
    echo "URL: http://$domain/panda-webhook.php"
    echo "Secret Token: $secret"
    echo "Instruction: Add this URL and Secret to your GitHub/GitLab Webhook settings."
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_webhook "$1"
fi
