#!/bin/bash
#================================================
# Panda Script v2.2 - Multi-Log Debugger
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

tail_logs() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        # Global logs if no domain specified
        log_info "Monitoring global server logs..."
        multitail -s 2 \
            --label "[NGINX]" /var/log/nginx/access.log \
            --label "[NGINX ERR]" /var/log/nginx/error.log \
            --label "[PHP ERR]" /var/log/php8.3-fpm.log \
            --label "[AUTH]" /var/log/auth.log 2>/dev/null || \
        tail -f /var/log/nginx/error.log /var/log/php*fpm.log
    else
        # Domain specific logs
        log_info "Monitoring logs for $domain..."
        local access_log="/var/log/nginx/${domain}.access.log"
        local error_log="/var/log/nginx/${domain}.error.log"
        local app_log="/var/www/${domain}/storage/logs/laravel.log"
        
        [[ ! -f "$access_log" ]] && access_log="/var/log/nginx/access.log"
        [[ ! -f "$error_log" ]] && error_log="/var/log/nginx/error.log"
        
        if command -v multitail &>/dev/null; then
            multitail -s 2 \
                --label "[ACCESS]" "$access_log" \
                --label "[ERROR]" "$error_log" \
                $([[ -f "$app_log" ]] && echo "--label [APP] $app_log")
        else
            log_warning "multitail not installed. Using standard tail..."
            tail -f "$access_log" "$error_log" $([[ -f "$app_log" ]] && echo "$app_log")
        fi
    fi
}

install_multitail() {
    if ! command -v multitail &>/dev/null; then
        log_info "Installing multitail for better log viewing..."
        apt-get install -y multitail &>/dev/null || true
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_multitail
    tail_logs "$1"
fi
