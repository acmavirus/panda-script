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
        echo "  8. 🔒 Change SSH Port"
        echo "  9. 👤 Create SFTP User (Jailed)"
        echo "  10. 🛡️  Enable WAF (7G)"
        echo "  11. 🔍  Malware Scanner"
        echo "  12. 🛡️  WP Security Hardening"
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
            8) source "$PANDA_DIR/modules/security/ssh_port.sh"; change_ssh_port ;;
            9)
                local domain=$(prompt "Enter domain")
                local user=$(prompt "Enter SFTP username")
                local pass=$(prompt "Enter SFTP password")
                source "$PANDA_DIR/security/sftp.sh"; create_sftp_user "$domain" "$user" "$pass"
                pause
                ;;
            10)
                local domain=$(prompt "Enter domain")
                source "$PANDA_DIR/security/waf.sh"; enable_waf_on_site "$domain"
                pause
                ;;
            11)
                clear
                echo "1. Install Scanner"
                echo "2. Scan Website"
                read -p "Choice: " sc
                source "$PANDA_DIR/security/malware_scan.sh"
                if [[ "$sc" == "1" ]]; then install_clamav; 
                elif [[ "$sc" == "2" ]]; then 
                    local domain=$(prompt "Enter domain")
                    scan_web_directory "$domain"
                fi
                ;;
            12) source "$PANDA_DIR/security/wp_fail2ban.sh"; harden_wordpress_security ;;
            0) return ;;
        esac
    done
}
