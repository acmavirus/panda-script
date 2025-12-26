#!/bin/bash
#================================================
# Panda Script v2.0 - PHP Menu
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

php_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ 🐘 PHP Management                                        ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. PHP Status"
        echo "  2. Install PHP Version"
        echo "  3. Switch PHP Version"
        echo "  4. Restart PHP-FPM"
        echo "  5. 📦 Composer Management"
        echo "  6. 📦 PHP Extension Manager"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        source "$PANDA_DIR/modules/php/install.sh"
        
        case $choice in
            1) php_status; pause ;;
            2)
                local ver=$(prompt "PHP version (8.2/8.3/8.4)" "8.3")
                php_install "$ver"
                pause
                ;;
            3)
                local ver=$(prompt "Switch to version")
                switch_php_version "$ver"
                pause
                ;;
            4)
                systemctl restart php*-fpm
                log_success "PHP-FPM restarted"
                pause
                ;;
            5) source "$PANDA_DIR/modules/php/composer.sh"; manage_composer ;;
            6) source "$PANDA_DIR/modules/php/php_ext.sh"; php_ext_menu ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    php_menu
fi
