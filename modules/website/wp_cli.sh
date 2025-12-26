#!/bin/bash
#================================================
# Panda Script v2.0 - WP-CLI Integration
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

manage_wp_cli() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ 🌐 WP-CLI Management                                     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    if command -v wp &>/dev/null; then
        echo "WP-CLI is installed:"
        wp --info | head -n 3
    else
        echo "WP-CLI is NOT installed."
    fi
    echo ""
    
    echo "  1. Install/Update WP-CLI"
    echo "  2. Common WP-CLI Commands (Menu)"
    echo "  0. Back"
    echo ""
    read -p "Enter choice: " choice
    
    case $choice in
        1) install_wp_cli ;;
        2) wp_commands_menu ;;
        0) return ;;
        *) manage_wp_cli ;;
    esac
}

install_wp_cli() {
    log_info "Downloading and installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &>/dev/null
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    log_success "WP-CLI installed successfully!"
    wp --version
    [[ "$1" != "--no-pause" ]] && pause
}

wp_commands_menu() {
    if ! command -v wp &>/dev/null; then
        log_error "WP-CLI not installed!"
        pause
        return
    fi
    
    echo "Note: Commands should be run from inside a WordPress directory."
    echo "  1. Update all plugins"
    echo "  2. Update all themes"
    echo "  3. Update/Install WordPress Core"
    echo "  4. Reset User Password"
    echo "  0. Back"
    echo ""
    read -p "Enter command choice: " cmd_choice
    
    case $cmd_choice in
        1) wp plugin update --all --allow-root; pause ;;
        2) wp theme update --all --allow-root; pause ;;
        3) wp core update --allow-root; pause ;;
        4)
            read -p "Username: " wp_user
            read -s -p "New Password: " wp_pass
            echo ""
            wp user update "$wp_user" --user_pass="$wp_pass" --allow-root
            pause
            ;;
        0) return ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    manage_wp_cli
fi
