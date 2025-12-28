#!/bin/bash
#================================================
# Panda Script v2.0 - WordPress Auto-Installer
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_wordpress() {
    local domain="$1"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    # Ensure website exists first
    if [[ ! -d "/home/$domain" ]]; then
        log_info "Website directory not found. Creating website first..."
        source "$PANDA_DIR/modules/website/create.sh"
        create_website "$domain"
    fi
    
    # Ensure WP-CLI is installed
    if ! command -v wp &>/dev/null; then
        log_info "WP-CLI not found. Installing..."
        source "$PANDA_DIR/modules/website/wp_cli.sh"
        install_wp_cli
    fi
    
    local doc_root="/home/$domain/public"
    local username=$(echo "$domain" | tr '.' '_' | cut -c1-16)
    
    # Database config
    local db_name=$(echo "$domain" | tr '.' '_' | cut -c1-16)_wp
    local db_user=$(echo "$domain" | tr '.' '_' | cut -c1-16)
    local db_pass=$(generate_password)
    
    log_info "Preparing Database for WordPress: $db_name"
    source "$PANDA_DIR/modules/mariadb/install.sh"
    create_database "$db_name" "$db_user" "$db_pass"
    
    log_info "Downloading and installing WordPress in $doc_root..."
    
    # Download WP
    sudo -u "$username" -i -- wp core download --path="$doc_root" --allow-root
    
    # Config WP
    sudo -u "$username" -i -- wp config create --path="$doc_root" --dbname="$db_name" --dbuser="$db_user" --dbpass="$db_pass" --allow-root
    
    log_success "WordPress core installed for $domain!"
    log_important "Database: $db_name | User: $db_user | Pass: $db_pass"
    log_important "Complete the installation at: http://$domain"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_wordpress "$1"
fi
