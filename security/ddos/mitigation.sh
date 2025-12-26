#!/bin/bash
#================================================
# Panda Script v2.0 - DDoS Mitigation
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

MITIGATION_ACTIVE=false

activate_mitigation() {
    local level="${1:-1}"
    
    log_warning "Activating DDoS mitigation level $level"
    MITIGATION_ACTIVE=true
    
    case "$level" in
        1)
            enable_rate_limiting
            ;;
        2)
            enable_rate_limiting
            enable_aggressive_blocking
            ;;
        3)
            enable_rate_limiting
            enable_aggressive_blocking
            enable_emergency_mode
            ;;
    esac
    
    log_success "Mitigation level $level activated"
}

deactivate_mitigation() {
    log_info "Deactivating DDoS mitigation"
    MITIGATION_ACTIVE=false
    
    disable_rate_limiting
    disable_emergency_mode
    
    log_success "Mitigation deactivated"
}

enable_rate_limiting() {
    log_info "Enabling rate limiting..."
    
    # Nginx rate limiting
    if [[ -f /etc/nginx/conf.d/rate_limit.conf ]]; then
        sed -i 's/^#.*limit_req/limit_req/' /etc/nginx/conf.d/rate_limit.conf
        systemctl reload nginx 2>/dev/null
    fi
    
    # IPTables rate limiting
    source "${PANDA_DIR}/security/firewall/rate_limit.sh"
    setup_rate_limiting
}

disable_rate_limiting() {
    log_info "Disabling aggressive rate limiting..."
    
    if [[ -f /etc/nginx/conf.d/rate_limit.conf ]]; then
        sed -i 's/^limit_req/#limit_req/' /etc/nginx/conf.d/rate_limit.conf
        systemctl reload nginx 2>/dev/null
    fi
}

enable_aggressive_blocking() {
    log_info "Enabling aggressive blocking..."
    
    # Lower connection threshold
    iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above 30 -j DROP
    iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above 30 -j DROP
    
    # Block common attack patterns
    iptables -I INPUT -p tcp --tcp-flags ALL NONE -j DROP
    iptables -I INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
    iptables -I INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
}

enable_emergency_mode() {
    log_warning "Enabling EMERGENCY mode!"
    
    # Very aggressive limits
    iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above 10 -j DROP
    iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above 10 -j DROP
    
    # Rate limit all new connections
    iptables -I INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
    iptables -I INPUT -p tcp --syn -j DROP
}

disable_emergency_mode() {
    # Remove emergency rules
    iptables -D INPUT -p tcp --dport 80 -m connlimit --connlimit-above 10 -j DROP 2>/dev/null
    iptables -D INPUT -p tcp --dport 443 -m connlimit --connlimit-above 10 -j DROP 2>/dev/null
    iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
}

block_country() {
    local country_code="$1"
    
    log_info "Blocking country: $country_code"
    
    if command -v geoipupdate &>/dev/null; then
        iptables -I INPUT -m geoip --src-cc "$country_code" -j DROP
    else
        log_warning "GeoIP module not available"
    fi
}

get_mitigation_status() {
    echo "Mitigation Status:"
    echo ""
    print_status "Mitigation" "$([[ "$MITIGATION_ACTIVE" == true ]] && echo "active" || echo "inactive")"
    echo ""
    echo "Active IPTables Rules:"
    iptables -L INPUT -n | grep -E "(DROP|connlimit|limit)" | head -10
}
