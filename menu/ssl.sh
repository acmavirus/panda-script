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
        
        case $choice in
            1)
                local domain=$(prompt "Enter domain")
                source "$PANDA_DIR/modules/ssl/install.sh"; issue_ssl "$domain"
                pause
                ;;
            2)
                local domain=$(prompt "Enter domain")
                source "$PANDA_DIR/modules/ssl/install.sh"; renew_ssl "$domain"
                pause
                ;;
            3) source "$PANDA_DIR/security/ssl_check.sh"; check_all_ssl ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}
