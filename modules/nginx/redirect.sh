#!/bin/bash
#================================================
# Panda Script v2.2.1 - Domain Redirect Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

setup_www_redirect() {
    local domain="$1"
    local type="$2" # "www-to-non" or "non-to-www"
    
    local conf_file="/etc/nginx/sites-available/$domain"
    
    if [[ ! -f "$conf_file" ]]; then
        log_error "Nginx config not found for $domain"
        return 1
    fi
    
    log_info "Configuring redirect for $domain ($type)..."
    
    # This is a complex sed operation, often safer to have templates
    # For now, we'll provide a warning and manual snippet or basic sed
    log_warning "Automatic Nginx redirection is coming in v2.3. Please use manual snippets for now."
    echo "Snippet for non-www to www:"
    echo "server { listen 80; server_name $domain; return 301 \$scheme://www.$domain\$request_uri; }"
    pause
}

redirect_menu() {
    local domain=$(prompt "Enter domain to manage redirect")
    
    while true; do
        clear
        print_header "🔀 Redirect & Alias Manager: $domain"
        echo "  1. View Current Nginx Config"
        echo "  2. Non-WWW to WWW (Snippet)"
        echo "  3. WWW to Non-WWW (Snippet)"
        echo "  4. Add Server Alias (Shared Vhost)"
        echo "  0. Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) cat "/etc/nginx/sites-available/$domain"; pause ;;
            2) setup_www_redirect "$domain" "non-to-www" ;;
            3) setup_www_redirect "$domain" "www-to-non" ;;
            4) 
                local alias=$(prompt "Enter alias domain")
                log_info "Adding alias $alias to $domain..."
                sed -i "s/server_name /server_name $alias /" "/etc/nginx/sites-available/$domain"
                systemctl reload nginx
                log_success "Alias added."
                pause
                ;;
            0) return ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    redirect_menu
fi
