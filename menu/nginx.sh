#!/bin/bash
#================================================
# Panda Script v2.0 - Nginx Menu
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

nginx_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ 🔧 Nginx Management                                     ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. Nginx Status"
        echo "  2. Restart Nginx"
        echo "  3. Test Configuration"
        echo "  4. Optimize Nginx"
        echo "  5. 🔀 Redirect & Alias Manager"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        source "$PANDA_DIR/modules/nginx/install.sh"
        
        case $choice in
            1) nginx_status; pause ;;
            2) systemctl restart nginx; log_success "Nginx restarted"; pause ;;
            3) nginx -t; pause ;;
            4) nginx_optimize; pause ;;
            5) source "$PANDA_DIR/modules/nginx/redirect.sh"; redirect_menu ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    nginx_menu
fi
