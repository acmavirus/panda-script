#!/bin/bash
#================================================
# Panda Script v2.0 - SSL Expiry Checker
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

check_ssl_expiry() {
    local domain="$1"
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    log_info "Checking SSL expiry for $domain..."
    
    local expiry_date=$(echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
    
    if [[ -z "$expiry_date" ]]; then
        log_error "Could not retrieve SSL info for $domain."
        return 1
    fi
    
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local now_epoch=$(date +%s)
    local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
    
    if [[ $days_left -lt 7 ]]; then
        log_warning "$domain SSL expires in $days_left days! Consider renewing."
    else
        log_success "$domain SSL is valid for $days_left more days."
    fi
}

check_all_ssl() {
    log_info "Checking all domains..."
    ls /etc/nginx/sites-available | grep -v "default" | while read domain; do
        check_ssl_expiry "$domain"
    done
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_all_ssl
fi
