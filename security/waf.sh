#!/bin/bash
#================================================
# Panda Script v2.0 - 7G Firewall / WAF
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_7g_waf() {
    log_info "Installing 7G Firewall (WAF) for Nginx..."
    
    mkdir -p "/etc/nginx/panda/waf"
    
    # Download 7G Firewall (Example URL, in real world might need specific link)
    # For this script, we'll create a basic include file
    curl -s https://raw.githubusercontent.com/perishablepress/7G-Firewall/master/7G-Firewall.conf -o "/etc/nginx/panda/waf/7g.conf"
    
    if [[ ! -f "/etc/nginx/panda/waf/7g.conf" ]]; then
        log_error "Failed to download 7G Firewall. Creating basic rules..."
        cat > "/etc/nginx/panda/waf/7g.conf" << EOF
# Basic WAF Rules
if (\$query_string ~* "union.*select.*\(") { return 403; }
if (\$query_string ~* "concat.*\(") { return 403; }
if (\$query_string ~* "base64_encode.*\(") { return 403; }
if (\$query_string ~* "(<|%3C).*script.*(>|%3E)") { return 403; }
if (\$query_string ~* "GLOBALS(=|\[|\%[0-9A-Z]{0,2})") { return 403; }
if (\$query_string ~* "_REQUEST(=|\[|\%[0-9A-Z]{0,2})") { return 403; }
EOF
    fi
    
    log_success "7G Firewall rules downloaded/created."
}

enable_waf_on_site() {
    local domain="$1"
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    if [[ ! -f "/etc/nginx/sites-available/$domain" ]]; then
        log_error "Site config for $domain not found."
        return 1
    fi
    
    if grep -q "7g.conf" "/etc/nginx/sites-available/$domain"; then
        log_warning "WAF already enabled for $domain."
        return 0
    fi
    
    # Inject include into server block
    sed -i "/server_name/a \    include /etc/nginx/panda/waf/7g.conf;" "/etc/nginx/sites-available/$domain"
    
    nginx -t && systemctl reload nginx
    log_success "7G Firewall enabled for $domain."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_7g_waf
fi
