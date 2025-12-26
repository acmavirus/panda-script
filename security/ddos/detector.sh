#!/bin/bash
#================================================
# Panda Script v2.0 - DDoS Detection Engine
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

DDOS_LOG="${PANDA_LOG_DIR:-/opt/panda/data/logs}/ddos.log"
BLOCKED_IPS_FILE="${PANDA_DATA_DIR:-/opt/panda/data}/blocked_ips.txt"

get_connection_count() {
    ss -ntu 2>/dev/null | wc -l
}

get_connections_per_ip() {
    ss -ntu 2>/dev/null | awk '{print $6}' | cut -d: -f1 | sort | uniq -c | sort -rn
}

get_top_ips() {
    local limit="${1:-10}"
    get_connections_per_ip | head -n "$limit"
}

detect_high_conn_ips() {
    local threshold=$(get_config "ddos" "conn_per_ip_warning" "100")
    
    get_connections_per_ip | while read count ip; do
        if [[ -n "$ip" && "$count" -gt "$threshold" && "$ip" != "Address" ]]; then
            echo "$count $ip"
        fi
    done
}

detect_ddos() {
    log_info "Scanning for DDoS activity..."
    
    local conn_warning=$(get_config "ddos" "conn_per_ip_warning" "100")
    local conn_critical=$(get_config "ddos" "conn_per_ip_critical" "300")
    local conn_block=$(get_config "ddos" "conn_per_ip_block" "500")
    
    local attack_detected=false
    local attack_level=0
    local suspicious_ips=()
    
    while read count ip; do
        [[ -z "$ip" || "$ip" == "Address" ]] && continue
        
        if [[ "$count" -gt "$conn_block" ]]; then
            attack_level=3
            attack_detected=true
            suspicious_ips+=("$ip:$count")
            block_attacker "$ip" "DDoS: $count connections"
        elif [[ "$count" -gt "$conn_critical" ]]; then
            attack_level=$((attack_level > 2 ? attack_level : 2))
            attack_detected=true
            suspicious_ips+=("$ip:$count")
        elif [[ "$count" -gt "$conn_warning" ]]; then
            attack_level=$((attack_level > 1 ? attack_level : 1))
            suspicious_ips+=("$ip:$count")
        fi
    done <<< "$(get_connections_per_ip)"
    
    if [[ "$attack_detected" == true ]]; then
        local message="DDoS detected! Level: $attack_level. IPs: ${suspicious_ips[*]}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$DDOS_LOG"
        
        source "${PANDA_DIR}/monitoring/alerts/alert_manager.sh" 2>/dev/null
        send_alert "ddos" "critical" "$message"
        
        return 1
    fi
    
    return 0
}

block_attacker() {
    local ip="$1"
    local reason="$2"
    
    is_whitelisted "$ip" && return 0
    
    source "${PANDA_DIR}/security/firewall/firewall.sh"
    firewall_block_ip "$ip"
    
    echo "$ip|$(date +%s)|$reason" >> "$BLOCKED_IPS_FILE"
    
    db_query "INSERT OR REPLACE INTO blocked_ips (ip_address, reason, blocked_at) VALUES ('$ip', '$reason', datetime('now'))"
    
    log_warning "Blocked attacker: $ip - $reason"
}

is_whitelisted() {
    local ip="$1"
    local whitelist="${PANDA_DATA_DIR}/whitelist.txt"
    
    [[ -f "$whitelist" ]] && grep -q "^$ip$" "$whitelist"
}

get_ddos_status() {
    echo "DDoS Detection Status:"
    echo ""
    print_line "Total Connections" "$(get_connection_count)"
    echo ""
    echo "Top 10 IPs by Connection:"
    get_top_ips 10
}

auto_unblock_expired() {
    local now=$(date +%s)
    local block_duration=$(get_config "ddos" "block_duration_level1" "300")
    
    while IFS='|' read -r ip timestamp reason; do
        local age=$((now - timestamp))
        if [[ $age -gt $block_duration ]]; then
            source "${PANDA_DIR}/security/firewall/firewall.sh"
            firewall_unblock_ip "$ip"
            log_info "Auto-unblocked: $ip (expired)"
        fi
    done < "$BLOCKED_IPS_FILE" 2>/dev/null
}
