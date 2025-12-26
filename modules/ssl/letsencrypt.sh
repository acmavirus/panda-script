#!/bin/bash
#================================================
# Panda Script v2.0 - Let's Encrypt SSL
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_certbot() {
    log_info "Installing Certbot..."
    
    if is_debian; then
        apt-get install -y certbot python3-certbot-nginx
    elif is_rhel; then
        dnf install -y certbot python3-certbot-nginx
    fi
    
    log_success "Certbot installed"
}

obtain_ssl() {
    local domain="$1"
    local email="${2:-admin@$domain}"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    command -v certbot &>/dev/null || install_certbot
    
    log_info "Obtaining SSL certificate for $domain..."
    
    certbot --nginx -d "$domain" -d "www.$domain" \
        --non-interactive --agree-tos --email "$email" \
        --redirect
    
    if [[ $? -eq 0 ]]; then
        db_query "UPDATE websites SET ssl_enabled=1 WHERE domain='$domain'"
        log_success "SSL certificate obtained for $domain"
        setup_auto_renew
    else
        log_error "Failed to obtain SSL certificate"
        return 1
    fi
}

renew_ssl() {
    log_info "Renewing SSL certificates..."
    certbot renew --quiet
    log_success "SSL renewal complete"
}

setup_auto_renew() {
    # Add cron job for auto-renewal
    (crontab -l 2>/dev/null | grep -v certbot; echo "0 3 * * * /usr/bin/certbot renew --quiet") | crontab -
    log_info "Auto-renewal configured"
}

check_ssl_expiry() {
    local domain="$1"
    local cert_file="/etc/letsencrypt/live/$domain/cert.pem"
    
    if [[ -f "$cert_file" ]]; then
        local expiry=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry" +%s)
        local now_epoch=$(date +%s)
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        
        echo "Domain: $domain"
        echo "Expires: $expiry"
        echo "Days left: $days_left"
        
        if [[ $days_left -lt 7 ]]; then
            log_warning "Certificate expiring soon!"
        fi
    else
        echo "No certificate found for $domain"
    fi
}

list_ssl_certs() {
    echo "SSL Certificates:"
    echo ""
    
    certbot certificates 2>/dev/null || echo "No certificates found"
}

revoke_ssl() {
    local domain="$1"
    
    if confirm "Revoke SSL certificate for $domain?"; then
        certbot revoke --cert-name "$domain" --non-interactive
        certbot delete --cert-name "$domain" --non-interactive
        db_query "UPDATE websites SET ssl_enabled=0 WHERE domain='$domain'"
        log_success "SSL certificate revoked for $domain"
    fi
}
