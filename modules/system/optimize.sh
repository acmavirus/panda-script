#!/bin/bash
#================================================
# Panda Script v2.2 - Media Optimizer
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_tools() {
    log_info "Ensuring optimization tools are installed..."
    apt-get update &>/dev/null
    apt-get install -y jpegoptim optipng webp &>/dev/null
    log_success "Optimization tools ready."
}

optimize_images() {
    local target_dir="$1"
    [[ -z "$target_dir" ]] && { log_error "Target directory required."; return 1; }
    [[ ! -d "$target_dir" ]] && { log_error "Directory $target_dir not found."; return 1; }

    log_info "Optimizing JPEG/PNG in $target_dir..."
    
    # JPEG
    find "$target_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -exec jpegoptim --strip-all --all-progressive -m85 {} \;
    
    # PNG
    find "$target_dir" -type f -iname "*.png" -exec optipng -o2 -strip all {} \;
    
    log_success "Image optimization completed."
}

convert_to_webp() {
    local target_dir="$1"
    [[ -z "$target_dir" ]] && { log_error "Target directory required."; return 1; }
    
    log_info "Converting images to WebP in $target_dir..."
    
    find "$target_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read img; do
        if [[ ! -f "${img}.webp" ]]; then
            cwebp -q 75 "$img" -o "${img}.webp" &>/dev/null
        fi
    done
    
    log_success "WebP conversion completed."
}

optimization_menu() {
    local domain=$(prompt "Enter domain to optimize")
    local site_root="/var/www/$domain"
    
    [[ ! -d "$site_root" ]] && { log_error "Domain not found."; pause; return; }
    
    while true; do
        clear
        print_header "🖼️ Media Optimization: $domain"
        echo "  1. Lossless Compression (JPEG/PNG)"
        echo "  2. Convert to WebP"
        echo "  3. Full Optimization (Compress + WebP)"
        echo "  0. Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) install_tools; optimize_images "$site_root"; pause ;;
            2) install_tools; convert_to_webp "$site_root"; pause ;;
            3) 
                install_tools
                optimize_images "$site_root"
                convert_to_webp "$site_root"
                pause
                ;;
            0) return ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    optimization_menu
fi
