#!/bin/bash
#================================================
# Panda Script v2.0 - Auto Update Checker
# Checks for updates and auto-installs if configured
# Website: https://panda-script.com
#================================================

PANDA_DIR="${PANDA_DIR:-/opt/panda}"
source "$PANDA_DIR/core/init.sh" 2>/dev/null

VERSION_URL="https://api.github.com/repos/acmavirus/panda-script/releases/latest"
UPDATE_LOG="$PANDA_LOG_DIR/auto_update.log"

log_update() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$UPDATE_LOG"
}

get_current_version() {
    grep "^version" "$PANDA_CONF" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "0.0.0"
}

get_latest_version() {
    curl -s --connect-timeout 10 "$VERSION_URL" 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v'
}

version_gt() {
    # Returns 0 if $1 > $2
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
}

check_for_updates() {
    local current=$(get_current_version)
    local latest=$(get_latest_version)
    
    if [[ -z "$latest" ]]; then
        log_update "Failed to check for updates (network error)"
        return 1
    fi
    
    if version_gt "$latest" "$current"; then
        log_update "New version available: $latest (current: $current)"
        echo "$latest"
        return 0
    else
        log_update "Already on latest version: $current"
        return 1
    fi
}

perform_auto_update() {
    local latest_version="$1"
    
    log_update "Starting auto-update to version $latest_version"
    
    # Send notification before update
    source "$PANDA_DIR/monitoring/alerts/alert_manager.sh" 2>/dev/null
    send_alert "system" "info" "Auto-updating Panda Script to version $latest_version"
    
    # Run update script
    if bash "$PANDA_DIR/../update"; then
        log_update "Auto-update completed successfully"
        
        send_alert "system" "info" "Panda Script updated to version $latest_version successfully"
        return 0
    else
        log_update "Auto-update failed"
        send_alert "system" "warning" "Panda Script auto-update failed"
        return 1
    fi
}

run_auto_update_check() {
    local auto_update_enabled=$(get_config general auto_update_enabled "false")
    
    if [[ "$auto_update_enabled" != "true" ]]; then
        log_update "Auto-update is disabled"
        return 0
    fi
    
    log_update "Checking for updates..."
    
    local latest=$(check_for_updates)
    
    if [[ -n "$latest" ]]; then
        local auto_install=$(get_config general auto_update_install "false")
        
        if [[ "$auto_install" == "true" ]]; then
            perform_auto_update "$latest"
        else
            # Just notify, don't install
            source "$PANDA_DIR/monitoring/alerts/alert_manager.sh" 2>/dev/null
            send_alert "system" "info" "Panda Script update available: $latest. Run 'panda' > Update to install."
        fi
    fi
}

# Setup cron job for auto-updates
setup_auto_update_cron() {
    local schedule="${1:-0 3 * * *}"  # Default: 3 AM daily
    
    # Remove existing panda auto-update cron
    crontab -l 2>/dev/null | grep -v "panda-auto-update" | crontab -
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$schedule $PANDA_DIR/core/auto_update.sh # panda-auto-update") | crontab -
    
    log_update "Auto-update cron job configured: $schedule"
    echo "Auto-update scheduled: $schedule"
}

remove_auto_update_cron() {
    crontab -l 2>/dev/null | grep -v "panda-auto-update" | crontab -
    log_update "Auto-update cron job removed"
    echo "Auto-update cron job removed"
}

show_auto_update_status() {
    echo "Auto Update Configuration:"
    echo ""
    
    local enabled=$(get_config general auto_update_enabled "false")
    local auto_install=$(get_config general auto_update_install "false")
    
    print_line "Auto-check enabled" "$enabled"
    print_line "Auto-install enabled" "$auto_install"
    print_line "Current version" "$(get_current_version)"
    
    echo ""
    echo "Cron Schedule:"
    crontab -l 2>/dev/null | grep "panda-auto-update" || echo "  Not scheduled"
    
    echo ""
    echo "Recent Update Checks:"
    tail -5 "$UPDATE_LOG" 2>/dev/null || echo "  No logs yet"
}

enable_auto_update() {
    local install_mode="${1:-notify}"  # notify or install
    
    # Update config
    if grep -q "^auto_update_enabled" "$PANDA_CONF"; then
        sed -i "s/^auto_update_enabled.*/auto_update_enabled = true/" "$PANDA_CONF"
    else
        echo "auto_update_enabled = true" >> "$PANDA_CONF"
    fi
    
    if [[ "$install_mode" == "install" ]]; then
        if grep -q "^auto_update_install" "$PANDA_CONF"; then
            sed -i "s/^auto_update_install.*/auto_update_install = true/" "$PANDA_CONF"
        else
            echo "auto_update_install = true" >> "$PANDA_CONF"
        fi
        echo "Auto-update enabled: Will automatically install new versions"
    else
        if grep -q "^auto_update_install" "$PANDA_CONF"; then
            sed -i "s/^auto_update_install.*/auto_update_install = false/" "$PANDA_CONF"
        else
            echo "auto_update_install = false" >> "$PANDA_CONF"
        fi
        echo "Auto-update enabled: Will notify only (no auto-install)"
    fi
    
    # Setup cron
    setup_auto_update_cron
}

disable_auto_update() {
    if grep -q "^auto_update_enabled" "$PANDA_CONF"; then
        sed -i "s/^auto_update_enabled.*/auto_update_enabled = false/" "$PANDA_CONF"
    fi
    
    remove_auto_update_cron
    echo "Auto-update disabled"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        --enable)
            enable_auto_update "${2:-notify}"
            ;;
        --enable-install)
            enable_auto_update "install"
            ;;
        --disable)
            disable_auto_update
            ;;
        --status)
            show_auto_update_status
            ;;
        --check)
            check_for_updates
            ;;
        *)
            run_auto_update_check
            ;;
    esac
fi
