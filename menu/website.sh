#!/bin/bash
source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

website_menu() {
    while true; do
        clear
        print_header "🌐 Website Management"
        echo "  1. Create Website"
        echo "  2. Delete Website"
        echo "  3. List Websites"
        echo "  4. Install WordPress"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                local domain=$(prompt "Enter domain")
                source "$PANDA_DIR/modules/website/create.sh"
                create_website "$domain"
                pause
                ;;
            2)
                local domain=$(prompt "Enter domain to delete")
                source "$PANDA_DIR/modules/website/create.sh"
                delete_website "$domain"
                pause
                ;;
            3)
                source "$PANDA_DIR/modules/website/create.sh"
                list_websites
                pause
                ;;
            4)
                local domain=$(prompt "Enter domain for WordPress")
                source "$PANDA_DIR/modules/website/wordpress.sh" 2>/dev/null
                install_wordpress "$domain"
                pause
                ;;
            0) return ;;
        esac
    done
}
