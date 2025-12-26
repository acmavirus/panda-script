#!/bin/bash
#================================================
# Panda Script v2.0 - Junk Cleaner
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

clean_junk() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ 🧹 Junk File Cleaner                                   ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "Targeting:"
    echo "  - Nginx logs (*.log.1, *.gz)"
    echo "  - System logs (/var/log/*.log.*)"
    echo "  - Apt cache (archives)"
    echo "  - Temporary files (/tmp/*)"
    echo ""
    
    if ! confirm "Proceed with cleaning?"; then
        return
    fi
    
    log_info "Cleaning Nginx logs..."
    find /var/log/nginx -type f \( -name "*.log.1" -o -name "*.gz" \) -delete
    
    log_info "Cleaning system logs..."
    find /var/log -type f \( -name "*.log.*" -o -name "*.gz" \) -delete
    
    log_info "Cleaning apt cache..."
    apt-get clean
    
    log_info "Cleaning temporary files..."
    find /tmp -type f -atime +1 -delete 2>/dev/null
    
    log_success "System cleanup completed!"
    echo ""
    df -h /
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    clean_junk
fi
