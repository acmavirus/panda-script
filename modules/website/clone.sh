#!/bin/bash
#================================================
# Panda Script v2.0 - Website Clone & Staging
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

clone_website() {
    local source_domain="$1"
    local target_domain="$2"
    
    [[ -z "$source_domain" ]] || [[ -z "$target_domain" ]] && { log_error "Source and Target domains required"; return 1; }
    
    if [[ ! -d "/var/www/$source_domain" ]]; then
        log_error "Source website /var/www/$source_domain not found!"
        return 1
    fi
    
    log_info "Cloning $source_domain to $target_domain..."
    
    # 1. Create target website structure
    source "$PANDA_DIR/modules/website/create.sh"
    create_website "$target_domain"
    
    local source_root="/var/www/$source_domain/public"
    local target_root="/var/www/$target_domain/public"
    local target_user=$(echo "$target_domain" | tr '.' '_' | cut -c1-16)
    
    # 2. Copy files
    log_info "Copying files..."
    cp -rp "$source_root/." "$target_root/"
    chown -R "$target_user:$target_user" "/var/www/$target_domain"
    
    # 3. Clone Database (Optional - search for wp-config or similar)
    if [[ -f "$target_root/wp-config.php" ]]; then
        log_info "Detected WordPress, cloning database..."
        clone_wordpress_db "$source_domain" "$target_domain" "$target_root"
    fi
    
    log_success "Website $source_domain successfully cloned to $target_domain!"
}

clone_wordpress_db() {
    local source_domain="$1"
    local target_domain="$2"
    local target_root="$3"
    
    # Get source DB info
    local source_root="/var/www/$source_domain/public"
    local db_name=$(grep DB_NAME "$source_root/wp-config.php" | cut -d\' -f4)
    
    # Create new DB
    local target_db_name=$(echo "$target_domain" | tr '.' '_' | cut -c1-16)_wp
    local target_db_user=$(echo "$target_domain" | tr '.' '_' | cut -c1-16)
    local target_db_pass=$(generate_password)
    
    source "$PANDA_DIR/modules/mariadb/install.sh"
    create_database "$target_db_name" "$target_db_user" "$target_db_pass"
    
    # Export and Import
    mysqldump "$db_name" > "/tmp/${target_db_name}.sql"
    mysql "$target_db_name" < "/tmp/${target_db_name}.sql"
    rm -f "/tmp/${target_db_name}.sql"
    
    # Update wp-config.php
    sed -i "s/define( 'DB_NAME', .*/define( 'DB_NAME', '$target_db_name' );/" "$target_root/wp-config.php"
    sed -i "s/define( 'DB_USER', .*/define( 'DB_USER', '$target_db_user' );/" "$target_root/wp-config.php"
    sed -i "s/define( 'DB_PASSWORD', .*/define( 'DB_PASSWORD', '$target_db_pass' );/" "$target_root/wp-config.php"
    
    # Search and Replace domain in DB
    if command -v wp &>/dev/null; then
        sudo -u "$(echo "$target_domain" | tr '.' '_' | cut -c1-16)" -i -- wp search-replace "$source_domain" "$target_domain" --path="$target_root" --allow-root
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    clone_website "$1" "$2"
fi
