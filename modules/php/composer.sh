#!/bin/bash
#================================================
# Panda Script v2.0 - Composer Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

manage_composer() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ 📦 Composer Management                                   ║"
    ╚══════════════════════════════════════════════════════════╝
    echo ""
    
    if command -v composer &>/dev/null; then
        echo "Composer is installed:"
        composer --version
    else
        echo "Composer is NOT installed."
    fi
    echo ""
    
    echo "  1. Install/Update Global Composer"
    echo "  2. Self-update Composer"
    echo "  0. Back"
    echo ""
    read -p "Enter choice: " choice
    
    case $choice in
        1) install_composer ;;
        2) 
            if command -v composer &>/dev/null; then
                composer self-update
            else
                log_error "Composer not installed!"
            fi
            pause 
            ;;
        0) return ;;
        *) manage_composer ;;
    esac
}

install_composer() {
    log_info "Downloading and installing Composer..."
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    log_success "Composer installed successfully!"
    composer --version
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    manage_composer
fi
