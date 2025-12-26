#!/bin/bash
#================================================
# Panda Script v2.0 - Network Utilities
# Website: https://panda-script.com
#================================================

get_public_ip() {
    curl -s --connect-timeout 5 https://ifconfig.me 2>/dev/null || \
    curl -s --connect-timeout 5 https://ipinfo.io/ip 2>/dev/null || \
    echo "unknown"
}

get_private_ip() {
    hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1"
}

get_primary_interface() {
    ip route | grep default | awk '{print $5}' | head -1
}

is_port_open() {
    local port="$1"
    local host="${2:-localhost}"
    nc -z "$host" "$port" &>/dev/null
}

is_port_in_use() {
    ss -tuln 2>/dev/null | grep -q ":$1 "
}

get_active_connections() {
    ss -s 2>/dev/null | grep "TCP:" | awk '{print $4}' | tr -d ','
}

get_connections_by_ip() {
    local limit="${1:-10}"
    ss -ntu | awk '{print $6}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -n "$limit"
}

check_internet() {
    ping -c 1 -W 2 google.com &>/dev/null || ping -c 1 -W 2 cloudflare.com &>/dev/null
}

is_valid_ip() {
    [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

is_valid_domain() {
    [[ "$1" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]
}

resolve_domain() {
    dig +short "$1" 2>/dev/null | head -1
}

get_listening_ports() {
    ss -tlnp 2>/dev/null | awk 'NR>1 {print $4}' | grep -oP ':\K[0-9]+' | sort -n | uniq
}

get_network_summary() {
    echo "Network Info:"
    print_line "Public IP" "$(get_public_ip)"
    print_line "Private IP" "$(get_private_ip)"
    print_line "Interface" "$(get_primary_interface)"
    print_line "Connections" "$(get_active_connections)"
}
