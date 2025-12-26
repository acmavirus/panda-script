#!/bin/bash
#================================================
# Panda Script v2.0 - Swap Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

manage_swap() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ 🛠️  Swap File Manager                                   ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check current swap
    echo "Current Swap Status:"
    swapon --show
    free -h | grep "Swap"
    echo ""
    
    echo "  1. Create/Expand Swap File"
    echo "  2. Disable and Delete Swap File"
    echo "  0. Back"
    echo ""
    read -p "Enter choice: " choice
    
    case $choice in
        1) create_swap ;;
        2) delete_swap ;;
        0) return ;;
        *) manage_swap ;;
    esac
}

create_swap() {
    echo ""
    read -p "Enter swap size in MB (e.g., 1024, 2048, 4096): " swap_size
    
    if [[ ! "$swap_size" =~ ^[0-9]+$ ]]; then
        log_error "Invalid size!"
        pause
        return
    fi
    
    local swap_path="/panda.swap"
    
    log_info "Creating swap file of ${swap_size}MB at $swap_path..."
    
    # Disable existing panda swap if any
    if [[ -f "$swap_path" ]]; then
        swapoff "$swap_path" 2>/dev/null
        rm -f "$swap_path"
    fi
    
    fallocate -l ${swap_size}M "$swap_path" || dd if=/dev/zero of="$swap_path" bs=1M count="$swap_size"
    chmod 600 "$swap_path"
    mkswap "$swap_path"
    swapon "$swap_path"
    
    # Add to fstab if not exists
    if ! grep -q "$swap_path" /etc/fstab; then
        echo "$swap_path none swap sw 0 0" >> /etc/fstab
    fi
    
    log_success "Swap file created and enabled!"
    pause
}

delete_swap() {
    local swap_path="/panda.swap"
    
    if [[ ! -f "$swap_path" ]]; then
        log_warning "No Panda swap file found at $swap_path"
        pause
        return
    fi
    
    if confirm "Are you sure you want to delete the swap file at $swap_path?"; then
        swapoff "$swap_path"
        rm -f "$swap_path"
        sed -i "\|$swap_path|d" /etc/fstab
        log_success "Swap file deleted."
    fi
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    manage_swap
fi
