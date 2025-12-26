#!/bin/bash
#================================================
# Panda Script v2.0 - Rate Limiting
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

setup_rate_limiting() {
    log_info "Setting up rate limiting..."
    
    # Load connlimit module
    modprobe nf_conntrack 2>/dev/null
    modprobe xt_connlimit 2>/dev/null
    
    # SSH rate limiting
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 10 --name SSH -j DROP
    
    # HTTP connection limit per IP
    local http_limit=$(get_config "rate_limit" "conn_limit_per_ip_http" "50")
    iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above "$http_limit" -j DROP
    iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above "$http_limit" -j DROP
    
    # New connections rate limit
    local new_conn_rate=$(get_config "rate_limit" "new_conn_rate" "50")
    iptables -A INPUT -p tcp --syn -m limit --limit ${new_conn_rate}/s --limit-burst 100 -j ACCEPT
    
    log_success "Rate limiting configured"
}

set_connection_limit() {
    local port="$1"
    local limit="$2"
    
    iptables -I INPUT -p tcp --dport "$port" -m connlimit --connlimit-above "$limit" -j DROP
    log_info "Connection limit set: port $port, max $limit"
}

remove_connection_limit() {
    local port="$1"
    
    iptables -D INPUT -p tcp --dport "$port" -m connlimit --connlimit-above 50 -j DROP 2>/dev/null
}

setup_syn_flood_protection() {
    log_info "Setting up SYN flood protection..."
    
    # Enable SYN cookies
    echo 1 > /proc/sys/net/ipv4/tcp_syncookies
    
    # Limit SYN backlog
    echo 2048 > /proc/sys/net/ipv4/tcp_max_syn_backlog
    
    # Reduce SYN-ACK retries
    echo 2 > /proc/sys/net/ipv4/tcp_synack_retries
    
    # SYN flood protection via iptables
    iptables -N SYN_FLOOD 2>/dev/null
    iptables -A INPUT -p tcp --syn -j SYN_FLOOD
    iptables -A SYN_FLOOD -m limit --limit 1/s --limit-burst 3 -j RETURN
    iptables -A SYN_FLOOD -j DROP
    
    log_success "SYN flood protection enabled"
}

show_rate_limit_status() {
    echo "Rate Limiting Status:"
    echo ""
    
    echo "IPTables Rate Limit Rules:"
    iptables -L INPUT -n -v | grep -E "(limit|connlimit|recent)"
    
    echo ""
    echo "Kernel Parameters:"
    echo "  tcp_syncookies: $(cat /proc/sys/net/ipv4/tcp_syncookies)"
    echo "  tcp_max_syn_backlog: $(cat /proc/sys/net/ipv4/tcp_max_syn_backlog)"
}
