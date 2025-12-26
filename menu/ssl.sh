#!/bin/bash
source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

ssl_menu() {
    while true; do
        clear
        print_header "🔒 SSL/HTTPS Management"
        echo "  1. Obtain SSL Certificate"
        echo "  2. Renew All Certificates"
        echo "  3. Check Certificate Status"
        echo "  4. List Certificates"
        echo "  5. Revoke Certificate"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        source "$PANDA_DIR/modules/ssl/letsencrypt.sh"
        
        case $choice in
            1)
                local domain=$(prompt "Enter domain")
                local email=$(prompt "Admin email")
                obtain_ssl "$domain" "$email"
                pause
                ;;
            2) renew_ssl; pause ;;
            3)
                local domain=$(prompt "Enter domain")
                check_ssl_expiry "$domain"
                pause
                ;;
            4) list_ssl_certs; pause ;;
            5)
                local domain=$(prompt "Enter domain")
                revoke_ssl "$domain"
                pause
                ;;
            0) return ;;
        esac
    done
}
