#!/bin/bash
#================================================
# Panda Script v2.2 - Database Sync Tool
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

sync_database() {
    local source_db="$1"
    local target_db="$2"
    
    [[ -z "$source_db" ]] || [[ -z "$target_db" ]] && { log_error "Source and Target DB required."; return 1; }
    
    # Check if DBs exist
    if ! mysql -e "USE $source_db" &>/dev/null; then
        log_error "Source DB $source_db does not exist."
        return 1
    fi
    
    if ! mysql -e "USE $target_db" &>/dev/null; then
        log_info "Target DB $target_db does not exist. Creating it..."
        mysql -e "CREATE DATABASE $target_db"
    fi
    
    log_info "Syncing $source_db -> $target_db..."
    mysqldump "$source_db" | mysql "$target_db"
    
    log_success "Database sync completed."
}

sql_playground() {
    local db="$1"
    local sql_file="$2"
    
    if [[ -z "$db" ]]; then
        log_info "Available Databases:"
        mysql -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys"
        db=$(prompt "Enter database name")
    fi
    
    if [[ -f "$sql_file" ]]; then
        log_info "Executing $sql_file on $db..."
        mysql "$db" < "$sql_file"
        log_success "Script executed."
    else
        log_info "Entering SQL Playground for $db (type 'exit' to quit)..."
        mysql "$db"
    fi
    pause
}

sync_menu() {
    while true; do
        clear
        print_header "🗄️ Database Tools"
        echo "  1. Sync Database (Clone A -> B)"
        echo "  2. SQL Playground (Run SQL/File)"
        echo "  0. Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1)
                local src=$(prompt "Source DB Name")
                local dst=$(prompt "Target DB Name")
                sync_database "$src" "$dst"
                pause
                ;;
            2) sql_playground; ;;
            0) return ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    sync_menu
fi
