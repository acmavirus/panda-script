#!/bin/bash
source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

security_menu() {
    while true; do
        clear
        print_header "🛡️ Security Center"
        echo "  1. Firewall Status"
        echo "  2. fail2ban Status"
        echo "  3. Block IP Address"
        echo "  4. Unblock IP Address"
        echo "  5. List Blocked IPs"
        echo "  6. SSH Hardening"
        echo "  7. Run Security Scan"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) source "$PANDA_DIR/security/firewall/firewall.sh"; firewall_status; pause ;;
            2) source "$PANDA_DIR/security/intrusion/fail2ban.sh"; fail2ban_status; pause ;;
            3)
                local ip=$(prompt "IP to block")
                source "$PANDA_DIR/security/ddos/blacklist.sh"
                add_to_blacklist "$ip"
                pause
                ;;
            4)
                local ip=$(prompt "IP to unblock")
                source "$PANDA_DIR/security/ddos/blacklist.sh"
                remove_from_blacklist "$ip"
                pause
                ;;
            5) source "$PANDA_DIR/security/ddos/blacklist.sh"; list_blacklist; pause ;;
            6) source "$PANDA_DIR/security/hardening/ssh_harden.sh"; harden_ssh; pause ;;
            7) source "$PANDA_DIR/security/ddos/detector.sh"; detect_ddos; pause ;;
            0) return ;;
        esac
    done
}
