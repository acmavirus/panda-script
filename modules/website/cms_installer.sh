#!/bin/bash
#================================================
# Panda Script v2.3 - One-Click CMS Deployment
# Install popular CMS in seconds
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

# CMS Installer Menu
cms_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ 🚀 One-Click CMS Deployment                             ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. 📝 WordPress (Most Popular)"
        echo "  2. 🛒 WooCommerce (E-commerce)"
        echo "  3. 🎨 Joomla"
        echo "  4. 💧 Drupal"
        echo "  5. 🛍️ PrestaShop (E-commerce)"
        echo "  6. 🎯 OpenCart (E-commerce)"
        echo "  7. 📚 MediaWiki"
        echo "  8. 💬 phpBB (Forum)"
        echo "  9. 🗃️ phpMyAdmin"
        echo "  0. Back"
        echo ""
        read -p "Select CMS to install: " choice
        
        case $choice in
            1) install_cms "wordpress" ;;
            2) install_cms "woocommerce" ;;
            3) install_cms "joomla" ;;
            4) install_cms "drupal" ;;
            5) install_cms "prestashop" ;;
            6) install_cms "opencart" ;;
            7) install_cms "mediawiki" ;;
            8) install_cms "phpbb" ;;
            9) install_cms "phpmyadmin" ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

install_cms() {
    local cms_type="$1"
    local domain=$(prompt "Enter domain for $cms_type")
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    # Ensure website exists
    if [[ ! -d "/var/www/$domain" ]]; then
        log_info "Creating website for $domain..."
        source "$PANDA_DIR/modules/website/create.sh"
        create_website "$domain"
    fi
    
    local doc_root="/var/www/$domain/public"
    local username=$(echo "$domain" | tr '.' '_' | cut -c1-16)
    
    # Database config
    local db_name=$(echo "$domain" | tr '.' '_' | cut -c1-16)_db
    local db_user=$(echo "$domain" | tr '.' '_' | cut -c1-16)
    local db_pass=$(generate_password)
    
    log_info "Creating database..."
    source "$PANDA_DIR/modules/mariadb/install.sh"
    create_database "$db_name" "$db_user" "$db_pass"
    
    case $cms_type in
        wordpress) _install_wordpress "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass" ;;
        woocommerce) _install_woocommerce "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass" ;;
        joomla) _install_joomla "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass" ;;
        drupal) _install_drupal "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass" ;;
        prestashop) _install_prestashop "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass" ;;
        opencart) _install_opencart "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass" ;;
        mediawiki) _install_mediawiki "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass" ;;
        phpbb) _install_phpbb "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass" ;;
        phpmyadmin) _install_phpmyadmin "$domain" "$doc_root" "$username" ;;
    esac
}

_install_wordpress() {
    local domain="$1" doc_root="$2" username="$3" db_name="$4" db_user="$5" db_pass="$6"
    
    log_info "Installing WordPress..."
    
    # Ensure WP-CLI exists
    if ! command -v wp &>/dev/null; then
        source "$PANDA_DIR/modules/website/wp_cli.sh"
        install_wp_cli
    fi
    
    cd "$doc_root"
    rm -rf * 2>/dev/null
    
    sudo -u "$username" -i -- wp core download --path="$doc_root" --allow-root
    sudo -u "$username" -i -- wp config create --path="$doc_root" --dbname="$db_name" --dbuser="$db_user" --dbpass="$db_pass" --allow-root
    
    _show_install_complete "$domain" "WordPress" "$db_name" "$db_user" "$db_pass"
}

_install_woocommerce() {
    local domain="$1" doc_root="$2" username="$3" db_name="$4" db_user="$5" db_pass="$6"
    
    # Install WordPress first
    _install_wordpress "$domain" "$doc_root" "$username" "$db_name" "$db_user" "$db_pass"
    
    log_info "Installing WooCommerce plugin..."
    sudo -u "$username" -i -- wp plugin install woocommerce --activate --path="$doc_root" --allow-root
    sudo -u "$username" -i -- wp plugin install storefront --activate --path="$doc_root" --allow-root
    
    log_success "WooCommerce installed with Storefront theme!"
}

_install_joomla() {
    local domain="$1" doc_root="$2" username="$3" db_name="$4" db_user="$5" db_pass="$6"
    
    log_info "Installing Joomla..."
    
    cd "$doc_root"
    rm -rf * 2>/dev/null
    
    # Download latest Joomla
    local joomla_url="https://downloads.joomla.org/cms/joomla4/4-4-0/Joomla_4-4-0-Stable-Full_Package.zip"
    wget -q --show-progress "$joomla_url" -O joomla.zip
    unzip -q joomla.zip && rm joomla.zip
    
    chown -R "$username:www-data" "$doc_root"
    chmod -R 755 "$doc_root"
    
    _show_install_complete "$domain" "Joomla" "$db_name" "$db_user" "$db_pass"
}

_install_drupal() {
    local domain="$1" doc_root="$2" username="$3" db_name="$4" db_user="$5" db_pass="$6"
    
    log_info "Installing Drupal..."
    
    cd "$doc_root"
    rm -rf * 2>/dev/null
    
    # Install via Composer
    if command -v composer &>/dev/null; then
        composer create-project drupal/recommended-project . --no-interaction
    else
        # Fallback: download Drupal directly
        local drupal_url="https://www.drupal.org/download-latest/tar.gz"
        wget -q --show-progress "$drupal_url" -O drupal.tar.gz
        tar -xzf drupal.tar.gz --strip-components=1 && rm drupal.tar.gz
    fi
    
    chown -R "$username:www-data" "$doc_root"
    
    _show_install_complete "$domain" "Drupal" "$db_name" "$db_user" "$db_pass"
}

_install_prestashop() {
    local domain="$1" doc_root="$2" username="$3" db_name="$4" db_user="$5" db_pass="$6"
    
    log_info "Installing PrestaShop..."
    
    cd "$doc_root"
    rm -rf * 2>/dev/null
    
    local ps_url="https://github.com/PrestaShop/PrestaShop/releases/download/8.1.3/prestashop_8.1.3.zip"
    wget -q --show-progress "$ps_url" -O prestashop.zip
    unzip -q prestashop.zip && rm prestashop.zip
    unzip -q prestashop.zip -d . 2>/dev/null || true
    
    chown -R "$username:www-data" "$doc_root"
    chmod -R 755 "$doc_root"
    
    _show_install_complete "$domain" "PrestaShop" "$db_name" "$db_user" "$db_pass"
}

_install_opencart() {
    local domain="$1" doc_root="$2" username="$3" db_name="$4" db_user="$5" db_pass="$6"
    
    log_info "Installing OpenCart..."
    
    cd "$doc_root"
    rm -rf * 2>/dev/null
    
    local oc_url="https://github.com/opencart/opencart/releases/download/4.0.2.3/opencart-4.0.2.3.zip"
    wget -q --show-progress "$oc_url" -O opencart.zip
    unzip -q opencart.zip && rm opencart.zip
    mv upload/* . 2>/dev/null || true
    
    chown -R "$username:www-data" "$doc_root"
    
    _show_install_complete "$domain" "OpenCart" "$db_name" "$db_user" "$db_pass"
}

_install_mediawiki() {
    local domain="$1" doc_root="$2" username="$3" db_name="$4" db_user="$5" db_pass="$6"
    
    log_info "Installing MediaWiki..."
    
    cd "$doc_root"
    rm -rf * 2>/dev/null
    
    local mw_url="https://releases.wikimedia.org/mediawiki/1.41/mediawiki-1.41.0.tar.gz"
    wget -q --show-progress "$mw_url" -O mediawiki.tar.gz
    tar -xzf mediawiki.tar.gz --strip-components=1 && rm mediawiki.tar.gz
    
    chown -R "$username:www-data" "$doc_root"
    
    _show_install_complete "$domain" "MediaWiki" "$db_name" "$db_user" "$db_pass"
}

_install_phpbb() {
    local domain="$1" doc_root="$2" username="$3" db_name="$4" db_user="$5" db_pass="$6"
    
    log_info "Installing phpBB..."
    
    cd "$doc_root"
    rm -rf * 2>/dev/null
    
    local phpbb_url="https://download.phpbb.com/pub/release/3.3/3.3.11/phpBB-3.3.11.zip"
    wget -q --show-progress "$phpbb_url" -O phpbb.zip
    unzip -q phpbb.zip && rm phpbb.zip
    mv phpBB3/* . 2>/dev/null || true
    rmdir phpBB3 2>/dev/null || true
    
    chown -R "$username:www-data" "$doc_root"
    
    _show_install_complete "$domain" "phpBB" "$db_name" "$db_user" "$db_pass"
}

_install_phpmyadmin() {
    local domain="$1" doc_root="$2" username="$3"
    
    log_info "Installing phpMyAdmin..."
    
    cd "$doc_root"
    rm -rf * 2>/dev/null
    
    local pma_url="https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz"
    wget -q --show-progress "$pma_url" -O phpmyadmin.tar.gz
    tar -xzf phpmyadmin.tar.gz --strip-components=1 && rm phpmyadmin.tar.gz
    
    # Create config
    cp config.sample.inc.php config.inc.php
    local blowfish=$(generate_password 32)
    sed -i "s/\$cfg\['blowfish_secret'\] = ''/\$cfg['blowfish_secret'] = '$blowfish'/" config.inc.php
    
    chown -R "$username:www-data" "$doc_root"
    
    log_success "phpMyAdmin installed successfully!"
    log_important "Access at: http://$domain"
    log_important "Use your MySQL/MariaDB credentials to login"
    pause
}

_show_install_complete() {
    local domain="$1" cms="$2" db_name="$3" db_user="$4" db_pass="$5"
    
    echo ""
    log_success "$cms installed successfully!"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ Installation Complete                                    ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║ URL: http://$domain"
    echo "║ Database: $db_name"
    echo "║ DB User: $db_user"
    echo "║ DB Password: $db_pass"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    log_important "Complete the web-based installation at http://$domain"
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cms_menu
fi
