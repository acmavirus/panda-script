#!/bin/bash
#================================================
# Panda Script v2.0 - MariaDB Installation
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

# MySQL command wrapper - uses credentials from /root/.my.cnf if available
mysql_cmd() {
    if [[ -f /root/.my.cnf ]]; then
        mysql --defaults-file=/root/.my.cnf "$@"
    else
        mysql "$@"
    fi
}

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
    
    # Save credentials for future use
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

# Configure MySQL credentials manually
configure_mysql_credentials() {
    echo "Configure MySQL/MariaDB Credentials"
    echo ""
    
    if [[ -f /root/.my.cnf ]]; then
        echo "Current credentials file exists: /root/.my.cnf"
        if ! confirm "Overwrite with new credentials?"; then
            return 0
        fi
    fi
    
    read -p "MySQL Username [root]: " mysql_user
    mysql_user=${mysql_user:-root}
    
    read -sp "MySQL Password: " mysql_pass
    echo ""
    
    # Test connection
    if mysql -u "$mysql_user" -p"$mysql_pass" -e "SELECT 1;" &>/dev/null; then
        cat > /root/.my.cnf << EOF
[client]
user=$mysql_user
password=$mysql_pass
EOF
        chmod 600 /root/.my.cnf
        log_success "Credentials saved and tested successfully!"
    else
        log_error "Connection failed. Please check username and password."
        return 1
    fi
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
    
    mysql_cmd -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;"
    mysql_cmd -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    mysql_cmd -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';"
    mysql_cmd -e "FLUSH PRIVILEGES;"
    
    echo ""
    echo "Database: $db_name"
    echo "User: $db_user"
    echo "Password: $db_pass"
    
    # Save to panda database
    db_query "INSERT OR REPLACE INTO databases (name, username, created_at) VALUES ('$db_name', '$db_user', datetime('now'))" 2>/dev/null
}

delete_database() {
    local db_name="$1"
    
    if confirm "Delete database $db_name?"; then
        mysql_cmd -e "DROP DATABASE IF EXISTS \`$db_name\`;"
        mysql_cmd -e "DROP USER IF EXISTS '$db_name'@'localhost';" 2>/dev/null
        db_query "DELETE FROM databases WHERE name='$db_name'" 2>/dev/null
        log_success "Database deleted: $db_name"
    fi
}

list_databases() {
    echo "Databases:"
    echo ""
    
    # Check if credentials exist
    if [[ ! -f /root/.my.cnf ]]; then
        log_warning "MySQL credentials not configured!"
        echo "Run: panda → Database Management → Configure Credentials"
        echo ""
        return 1
    fi
    
    mysql_cmd -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$" | while read db; do
        echo "  • $db"
    done
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to connect to MySQL. Check credentials in /root/.my.cnf"
    fi
}

mariadb_status() {
    echo "MariaDB Status:"
    print_status "MariaDB" "$(get_service_status mariadb)"
    mysql_cmd -V 2>/dev/null | head -1
    
    if [[ -f /root/.my.cnf ]]; then
        echo "Credentials: /root/.my.cnf ✓"
    else
        echo "Credentials: Not configured ✗"
    fi
}
