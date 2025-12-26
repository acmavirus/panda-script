#!/bin/bash
source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

website_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ 🌐 Website Management                                  ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. Create Website"
        echo "  2. Delete Website (Numeric Selection)"
        echo "  3. List Websites"
        echo "  4. Install WordPress (Auto)"
        echo "  5. 🌐 WP-CLI Management"
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
            2) delete_website_numeric ;;
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
            5) source "$PANDA_DIR/modules/website/wp_cli.sh"; manage_wp_cli ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

delete_website_numeric() {
    source "$PANDA_DIR/modules/website/create.sh"
    echo "Select website to delete:"
    local domains=($(ls /etc/nginx/sites-available | grep -v "default" | grep ".conf" | sed 's/\.conf//'))
    
    if [ ${#domains[@]} -eq 0 ]; then
        log_warning "No websites found."
        pause
        return
    fi

    for i in "${!domains[@]}"; do
        echo "  $((i+1)). ${domains[$i]}"
    done
    echo "  0. Back"
    echo ""
    read -p "Enter number: " selection
    
    if [[ "$selection" == "0" ]]; then return; fi
    
    local idx=$((selection-1))
    if [[ -n "${domains[$idx]}" ]]; then
        delete_website "${domains[$idx]}"
    else
        log_error "Invalid selection"
    fi
    pause
}
