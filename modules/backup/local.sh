#!/bin/bash
#================================================
# Panda Script v2.0 - Local Backup
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

BACKUP_DIR="/opt/panda/backups"

run_backup() {
    local domain="${1:-all}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$BACKUP_DIR"
    
    if [[ "$domain" == "all" ]]; then
        backup_all "$timestamp"
    else
        backup_website "$domain" "$timestamp"
    fi
}

backup_all() {
    local timestamp="$1"
    local backup_file="$BACKUP_DIR/full_backup_$timestamp.tar.gz"
    
    log_info "Creating full backup..."
    
    # Backup websites
    tar -czf "$backup_file" /var/www 2>/dev/null
    
    # Backup databases
    backup_all_databases "$timestamp"
    
    # Backup configs
    tar -czf "$BACKUP_DIR/config_backup_$timestamp.tar.gz" /etc/nginx /etc/php 2>/dev/null
    
    log_success "Full backup created: $backup_file"
}

backup_website() {
    local domain="$1"
    local timestamp="$2"
    local backup_file="$BACKUP_DIR/${domain}_$timestamp.tar.gz"
    
    log_info "Backing up $domain..."
    
    if [[ -d "/var/www/$domain" ]]; then
        tar -czf "$backup_file" -C /var/www "$domain"
        log_success "Website backup: $backup_file"
    else
        log_error "Website not found: $domain"
        return 1
    fi
}

backup_database() {
    local db_name="$1"
    local timestamp="${2:-$(date +%Y%m%d_%H%M%S)}"
    local backup_file="$BACKUP_DIR/${db_name}_db_$timestamp.sql.gz"
    
    log_info "Backing up database: $db_name"
    
    mysqldump "$db_name" 2>/dev/null | gzip > "$backup_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "Database backup: $backup_file"
    else
        log_error "Database backup failed"
        return 1
    fi
}

backup_all_databases() {
    local timestamp="$1"
    
    mysql -e "SHOW DATABASES" | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$" | while read db; do
        backup_database "$db" "$timestamp"
    done
}

list_backups() {
    echo "Backups:"
    echo ""
    ls -lh "$BACKUP_DIR" 2>/dev/null | tail -20 || echo "No backups found"
}

cleanup_old_backups() {
    local days="${1:-7}"
    
    log_info "Removing backups older than $days days..."
    find "$BACKUP_DIR" -type f -mtime +$days -delete
    log_success "Cleanup complete"
}

restore_backup() {
    local backup_file="$1"
    
    [[ ! -f "$backup_file" ]] && { log_error "Backup file not found"; return 1; }
    
    if confirm "Restore from $backup_file?"; then
        if [[ "$backup_file" == *.sql.gz ]]; then
            local db_name=$(basename "$backup_file" | cut -d'_' -f1)
            gunzip -c "$backup_file" | mysql "$db_name"
        else
            tar -xzf "$backup_file" -C /
        fi
        log_success "Restore complete"
    fi
}
