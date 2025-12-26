#!/bin/bash
#================================================
# Panda Script v2.0 - PHP Installation
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

php_install() {
    local version="${1:-8.3}"
    
    log_info "Installing PHP $version..."
    
    if is_debian; then
        add_php_repo_debian
        apt-get update -y
        apt-get install -y \
            php${version}-fpm php${version}-cli php${version}-common \
            php${version}-mysql php${version}-curl php${version}-gd \
            php${version}-mbstring php${version}-xml php${version}-zip \
            php${version}-bcmath php${version}-intl php${version}-opcache \
            php${version}-redis php${version}-imagick
    elif is_rhel; then
        add_php_repo_rhel "$version"
        dnf install -y \
            php php-fpm php-cli php-common php-mysqlnd php-curl \
            php-gd php-mbstring php-xml php-zip php-bcmath \
            php-intl php-opcache php-redis php-imagick
    fi
    
    systemctl enable php${version}-fpm 2>/dev/null || systemctl enable php-fpm
    systemctl start php${version}-fpm 2>/dev/null || systemctl start php-fpm
    
    configure_php "$version"
    
    log_success "PHP $version installed"
}

add_php_repo_debian() {
    if is_ubuntu; then
        add-apt-repository -y ppa:ondrej/php &>/dev/null
    else
        apt-get install -y apt-transport-https lsb-release ca-certificates curl
        curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor > /usr/share/keyrings/php.gpg
        echo "deb [signed-by=/usr/share/keyrings/php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    fi
}

add_php_repo_rhel() {
    local version="$1"
    dnf install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm &>/dev/null
    dnf module reset php -y &>/dev/null
    dnf module enable php:remi-${version} -y &>/dev/null
}

configure_php() {
    local version="${1:-8.3}"
    local ram_mb=$(get_ram_mb)
    
    # Calculate limits based on RAM
    local memory_limit="256M"
    local opcache_memory="128"
    
    if [[ $ram_mb -lt 1024 ]]; then
        memory_limit="128M"
        opcache_memory="64"
    elif [[ $ram_mb -ge 4096 ]]; then
        memory_limit="512M"
        opcache_memory="256"
    fi
    
    local ini_file="/etc/php/${version}/fpm/php.ini"
    [[ ! -f "$ini_file" ]] && ini_file="/etc/php.ini"
    
    if [[ -f "$ini_file" ]]; then
        sed -i "s/^memory_limit =.*/memory_limit = $memory_limit/" "$ini_file"
        sed -i "s/^max_execution_time =.*/max_execution_time = 300/" "$ini_file"
        sed -i "s/^upload_max_filesize =.*/upload_max_filesize = 100M/" "$ini_file"
        sed -i "s/^post_max_size =.*/post_max_size = 100M/" "$ini_file"
        sed -i "s/^;*opcache.enable=.*/opcache.enable=1/" "$ini_file"
        sed -i "s/^;*opcache.memory_consumption=.*/opcache.memory_consumption=$opcache_memory/" "$ini_file"
    fi
    
    systemctl restart php${version}-fpm 2>/dev/null || systemctl restart php-fpm
}

php_status() {
    echo "PHP Status:"
    php -v | head -1
    
    for ver in 8.4 8.3 8.2 8.1; do
        if systemctl is-active --quiet php${ver}-fpm 2>/dev/null; then
            print_status "PHP-FPM $ver" "running"
        fi
    done
}

switch_php_version() {
    local version="$1"
    
    update-alternatives --set php /usr/bin/php${version} 2>/dev/null
    log_success "Switched to PHP $version"
}
