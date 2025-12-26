#!/bin/bash
#================================================
# Panda Script v2.0 - OS Detection
# OS detection & validation
# Website: https://panda-script.com
#================================================

#------------------------------------------------
# Detect OS
#------------------------------------------------
detect_os() {
    # Source os-release file
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        export OS_ID="$ID"
        export OS_VERSION="$VERSION_ID"
        export OS_VERSION_CODENAME="${VERSION_CODENAME:-}"
        export OS_NAME="$NAME"
        export OS_PRETTY_NAME="$PRETTY_NAME"
        export OS_ID_LIKE="${ID_LIKE:-$ID}"
    else
        log_error "Cannot detect OS. /etc/os-release not found."
        return 1
    fi
    
    # Determine OS family
    case "$OS_ID" in
        ubuntu|debian|linuxmint|pop)
            export OS_FAMILY="debian"
            ;;
        rhel|centos|rocky|almalinux|fedora|ol)
            export OS_FAMILY="rhel"
            ;;
        *)
            # Check ID_LIKE
            if [[ "$OS_ID_LIKE" =~ debian|ubuntu ]]; then
                export OS_FAMILY="debian"
            elif [[ "$OS_ID_LIKE" =~ rhel|centos|fedora ]]; then
                export OS_FAMILY="rhel"
            else
                export OS_FAMILY="unknown"
            fi
            ;;
    esac
    
    # Detect architecture
    export OS_ARCH=$(uname -m)
    case "$OS_ARCH" in
        x86_64|amd64)
            export OS_ARCH="x86_64"
            export OS_ARCH_ALT="amd64"
            ;;
        aarch64|arm64)
            export OS_ARCH="aarch64"
            export OS_ARCH_ALT="arm64"
            ;;
        *)
            export OS_ARCH_ALT="$OS_ARCH"
            ;;
    esac
    
    # Detect kernel version
    export KERNEL_VERSION=$(uname -r)
    
    return 0
}

#------------------------------------------------
# Check Supported OS
#------------------------------------------------
check_supported_os() {
    detect_os
    
    local supported=false
    
    case "$OS_ID" in
        ubuntu)
            if [[ "$OS_VERSION" =~ ^(20\.04|22\.04|24\.04)$ ]]; then
                supported=true
            fi
            ;;
        debian)
            if [[ "$OS_VERSION" =~ ^(10|11|12)$ ]]; then
                supported=true
            fi
            ;;
        rocky|almalinux)
            if [[ "$OS_VERSION" =~ ^(8|9|10) ]]; then
                supported=true
            fi
            ;;
        centos)
            if [[ "$OS_VERSION" =~ ^(7|8|9) ]]; then
                supported=true
            fi
            ;;
        *)
            supported=false
            ;;
    esac
    
    if [[ "$supported" != "true" ]]; then
        log_error "Unsupported OS: $OS_PRETTY_NAME"
        log_info "Supported operating systems:"
        echo "  - Ubuntu 20.04, 22.04, 24.04"
        echo "  - Debian 10, 11, 12"
        echo "  - Rocky Linux 8, 9, 10"
        echo "  - AlmaLinux 8, 9, 10"
        echo "  - CentOS 7, 8, 9"
        return 1
    fi
    
    log_success "Detected supported OS: $OS_PRETTY_NAME"
    return 0
}

#------------------------------------------------
# Get OS Info
#------------------------------------------------
get_os_info() {
    detect_os
    
    echo "OS ID: $OS_ID"
    echo "OS Version: $OS_VERSION"
    echo "OS Name: $OS_NAME"
    echo "OS Family: $OS_FAMILY"
    echo "Architecture: $OS_ARCH"
    echo "Kernel: $KERNEL_VERSION"
}

#------------------------------------------------
# Check if Debian-based
#------------------------------------------------
is_debian() {
    [[ "${OS_FAMILY:-}" == "debian" ]]
}

#------------------------------------------------
# Check if RHEL-based
#------------------------------------------------
is_rhel() {
    [[ "${OS_FAMILY:-}" == "rhel" ]]
}

#------------------------------------------------
# Check if Ubuntu
#------------------------------------------------
is_ubuntu() {
    [[ "${OS_ID:-}" == "ubuntu" ]]
}

#------------------------------------------------
# Get Major Version
#------------------------------------------------
get_os_major_version() {
    echo "${OS_VERSION%%.*}"
}

#------------------------------------------------
# Check Virtualization
#------------------------------------------------
detect_virtualization() {
    local virt=""
    
    if [[ -f /sys/hypervisor/type ]]; then
        virt=$(cat /sys/hypervisor/type)
    elif command -v systemd-detect-virt &>/dev/null; then
        virt=$(systemd-detect-virt 2>/dev/null || echo "none")
    elif command -v virt-what &>/dev/null; then
        virt=$(virt-what 2>/dev/null | head -1)
    fi
    
    echo "${virt:-physical}"
}

#------------------------------------------------
# Check Cloud Provider
#------------------------------------------------
detect_cloud_provider() {
    local provider="unknown"
    
    # Check for AWS
    if curl -s --connect-timeout 1 http://169.254.169.254/latest/meta-data/ &>/dev/null; then
        provider="aws"
    # Check for GCP
    elif curl -s --connect-timeout 1 -H "Metadata-Flavor: Google" http://169.254.169.254/ &>/dev/null; then
        provider="gcp"
    # Check for Azure
    elif curl -s --connect-timeout 1 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" &>/dev/null; then
        provider="azure"
    # Check for DigitalOcean
    elif curl -s --connect-timeout 1 http://169.254.169.254/metadata/v1/ &>/dev/null; then
        provider="digitalocean"
    # Check for Vultr
    elif curl -s --connect-timeout 1 http://169.254.169.254/v1.json &>/dev/null; then
        provider="vultr"
    # Check for Linode
    elif [[ -f /etc/linode/lish_authorized_users ]]; then
        provider="linode"
    fi
    
    echo "$provider"
}

#------------------------------------------------
# Get CPU Info
#------------------------------------------------
get_cpu_info() {
    local cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
    local model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    
    echo "Cores: $cores"
    echo "Model: ${model:-Unknown}"
}

#------------------------------------------------
# Get Memory Info
#------------------------------------------------
get_memory_info() {
    local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mb=$((total_kb / 1024))
    local total_gb=$(echo "scale=1; $total_mb / 1024" | bc)
    
    echo "Total RAM: ${total_gb}GB (${total_mb}MB)"
}

#------------------------------------------------
# Auto-detect at load
#------------------------------------------------
detect_os
