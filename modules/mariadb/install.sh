#!/bin/bash
#================================================
# Panda Script v2.0 - MariaDB Installation
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

mariadb_install() {
    local version="${1:-11.4}"
    
    log_info "Installing MariaDB $version..."
    
    if is_debian; then
        apt-get install -y mariadb-server mariadb-client
    elif is_rhel; then
        dnf install -y mariadb-server
    fi
    
    systemctl enable mariadb
    systemctl start mariadb
    
    secure_mariadb
    optimize_mariadb
    
    log_success "MariaDB installed"
}

secure_mariadb() {
    log_info "Securing MariaDB..."
    
    local root_pass=$(generate_password 16)
    
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$root_pass';"
    mysql -u root -p"$root_pass" -e "DELETE FROM mysql.user WHERE User='';"
    mysql -u root -p"$root_pass" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -u root -p"$root_pass" -e "DROP DATABASE IF EXISTS test;"
    mysql -u root -p"$root_pass" -e "FLUSH PRIVILEGES;"
    
    # Save credentials
    cat > /root/.my.cnf << EOF
[client]
user=root
password=$root_pass
EOF
    chmod 600 /root/.my.cnf
    
    echo ""
    log_success "MariaDB secured. Root password: $root_pass"
    echo "Credentials saved to /root/.my.cnf"
}

optimize_mariadb() {
    local ram_mb=$(get_ram_mb)
    local buffer_pool="256M"
    local max_connections=100
    
    if [[ $ram_mb -lt 1024 ]]; then
        buffer_pool="128M"
        max_connections=50
    elif [[ $ram_mb -ge 4096 ]]; then
        buffer_pool="1G"
        max_connections=200
    fi
    
    cat > /etc/mysql/mariadb.conf.d/99-panda.cnf << EOF
[mysqld]
# Performance
innodb_buffer_pool_size = $buffer_pool
max_connections = $max_connections
key_buffer_size = 32M
query_cache_size = 0
query_cache_type = 0

# InnoDB
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_file_size = 128M

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
EOF

    systemctl restart mariadb
}

create_database() {
    local db_name="$1"
    local db_user="${2:-$db_name}"
    local db_pass="${3:-$(generate_password 16)}"
    
    mysql -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;"
    mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    mysql -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    
    echo "Database: $db_name"
    echo "User: $db_user"
    echo "Password: $db_pass"
}

delete_database() {
    local db_name="$1"
    
    if confirm "Delete database $db_name?"; then
        mysql -e "DROP DATABASE IF EXISTS \`$db_name\`;"
        log_success "Database deleted: $db_name"
    fi
}

list_databases() {
    echo "Databases:"
    mysql -e "SHOW DATABASES;" | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$"
}

mariadb_status() {
    echo "MariaDB Status:"
    print_status "MariaDB" "$(get_service_status mariadb)"
    mysql -V 2>/dev/null | head -1
}
