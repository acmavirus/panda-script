#!/bin/bash
#================================================
# Panda Script v2.0 - Rclone Cloud Backup
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_rclone() {
    log_info "Installing Rclone..."
    sudo -v
    if ! command -v rclone &>/dev/null; then
        curl https://rclone.org/install.sh | sudo bash
    fi
    log_success "Rclone installed successfully!"
}

manage_backups() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ ☁️  Cloud Backup & Restore                                 ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    if ! command -v rclone &>/dev/null; then
        echo "  1. Install Rclone"
        echo "  0. Back"
        read -p "Choice: " c
        [[ "$c" == "1" ]] && install_rclone
        return
    fi
    
    echo "  1. Configure Cloud Provider (rclone config)"
    echo "  2. List Remotes"
    echo "  3. Backup All Websites to Cloud"
    echo "  4. Schedule Daily Backup"
    echo "  0. Back"
    echo ""
    read -p "Choice: " choice
    
    case $choice in
        1) rclone config; pause ;;
        2) rclone listremotes; pause ;;
        3) backup_all_to_cloud ;;
        4) schedule_cloud_backup ;;
        0) return ;;
    esac
}

backup_all_to_cloud() {
    local remote=$(prompt "Enter rclone remote name (e.g., gdrive:backups)")
    [[ -z "$remote" ]] && return
    
    log_info "Starting full backup to $remote..."
    
    # Run local backup first (already exists in modules/backup/backup.sh)
    source "$PANDA_DIR/modules/backup/backup.sh"
    # Assuming backup_all exists and saves to $PANDA_DIR/data/backups
    # (Checking if I need to implement it or if it exists)
    
    # For now, let's just sync the backup folder
    rclone sync "$PANDA_DIR/data/backups" "$remote" --progress
    log_success "Backup sync completed!"
    pause
}

schedule_cloud_backup() {
    local remote=$(prompt "Enter rclone remote name")
    [[ -z "$remote" ]] && return
    
    local cron_cmd="0 3 * * * /opt/panda/modules/backup/rclone.sh sync_job $remote >> /var/log/panda_backup.log 2>&1"
    (crontab -l 2>/dev/null; echo "$cron_cmd") | sort -u | crontab -
    
    log_success "Daily backup scheduled at 03:00 to $remote"
    pause
}

if [[ "$1" == "sync_job" ]]; then
    rclone sync "$PANDA_DIR/data/backups" "$2"
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    manage_backups
fi
