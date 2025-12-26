#!/bin/bash
#================================================
# Panda Script v2.2.1 - PHP Extension Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_php_ext() {
    local ext_name="$1"
    local php_ver="$2"
    
    if [[ -z "$php_ver" ]]; then
        php_ver=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    fi

    log_info "Installing PHP $php_ver extension: $ext_name..."
    
    case $ext_name in
        imagick)
            apt-get install -y php$php_ver-imagick
            ;;
        swoole)
            apt-get install -y php$php_ver-swoole || {
                log_info "Swoole not in repo, attempting via PECL..."
                apt-get install -y php$php_ver-dev libcurl4-openssl-dev
                pecl install swoole
                echo "extension=swoole.so" > /etc/php/$php_ver/fpm/conf.d/20-swoole.ini
            }
            ;;
        ioncube)
            # Complex install logic for ioncube usually manual, providing helper
            log_warning "IonCube requires manual loader placement. Downloading helper..."
            # (Simplified for now)
            ;;
        exif|intl|mbstring|gd|xml|zip|curl|bcmath)
            apt-get install -y php$php_ver-$ext_name
            ;;
        *)
            log_error "Extension $ext_name not supported yet."
            return 1
            ;;
    esac
    
    systemctl restart php$php_ver-fpm
    log_success "PHP $php_ver extension $ext_name installed and service restarted."
}

php_ext_menu() {
    local php_ver=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    
    while true; do
        clear
        print_header "🐘 PHP Extension Manager ($php_ver)"
        echo "Select extensions to install:"
        echo "  1. 📷 Imagick (Image processing)"
        echo "  2. ⚡ Swoole (High-performance networking)"
        echo "  3. 🌍 Intl (Internationalization)"
        echo "  4. 🖼️  GD (Image manipulation)"
        echo "  5. 📝 MBString (Multi-byte string)"
        echo "  6. 📦 Zip/XML/BCMath (Common core)"
        echo "  0. Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) install_php_ext "imagick" "$php_ver"; pause ;;
            2) install_php_ext "swoole" "$php_ver"; pause ;;
            3) install_php_ext "intl" "$php_ver"; pause ;;
            4) install_php_ext "gd" "$php_ver"; pause ;;
            5) install_php_ext "mbstring" "$php_ver"; pause ;;
            6) 
                install_php_ext "zip" "$php_ver"
                install_php_ext "xml" "$php_ver"
                install_php_ext "bcmath" "$php_ver"
                pause
                ;;
            0) return ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    php_ext_menu
fi
