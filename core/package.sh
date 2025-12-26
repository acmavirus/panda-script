#!/bin/bash
#================================================
# Panda Script v2.0 - Package Manager
# Package manager abstraction (apt/dnf/yum)
# Website: https://panda-script.com
#================================================

#------------------------------------------------
# Detect Package Manager
#------------------------------------------------
detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        export PKG_MANAGER="apt"
        export PKG_UPDATE="apt-get update -y"
        export PKG_UPGRADE="apt-get upgrade -y"
        export PKG_INSTALL="apt-get install -y"
        export PKG_REMOVE="apt-get remove -y"
        export PKG_PURGE="apt-get purge -y"
        export PKG_AUTOREMOVE="apt-get autoremove -y"
        export PKG_SEARCH="apt-cache search"
        export PKG_INFO="apt-cache show"
        export PKG_LIST="dpkg -l"
        export PKG_INSTALLED="dpkg -l | grep -q"
    elif command -v dnf &>/dev/null; then
        export PKG_MANAGER="dnf"
        export PKG_UPDATE="dnf makecache"
        export PKG_UPGRADE="dnf upgrade -y"
        export PKG_INSTALL="dnf install -y"
        export PKG_REMOVE="dnf remove -y"
        export PKG_PURGE="dnf remove -y"
        export PKG_AUTOREMOVE="dnf autoremove -y"
        export PKG_SEARCH="dnf search"
        export PKG_INFO="dnf info"
        export PKG_LIST="rpm -qa"
        export PKG_INSTALLED="rpm -q"
    elif command -v yum &>/dev/null; then
        export PKG_MANAGER="yum"
        export PKG_UPDATE="yum makecache"
        export PKG_UPGRADE="yum upgrade -y"
        export PKG_INSTALL="yum install -y"
        export PKG_REMOVE="yum remove -y"
        export PKG_PURGE="yum remove -y"
        export PKG_AUTOREMOVE="yum autoremove -y"
        export PKG_SEARCH="yum search"
        export PKG_INFO="yum info"
        export PKG_LIST="rpm -qa"
        export PKG_INSTALLED="rpm -q"
    else
        log_error "No supported package manager found"
        return 1
    fi
    
    return 0
}

#------------------------------------------------
# Update Package Cache
#------------------------------------------------
pkg_update() {
    log_info "Updating package cache..."
    $PKG_UPDATE &>/dev/null
    return $?
}

#------------------------------------------------
# Upgrade Packages
#------------------------------------------------
pkg_upgrade() {
    log_info "Upgrading packages..."
    $PKG_UPGRADE
    return $?
}

#------------------------------------------------
# Install Package(s)
#------------------------------------------------
pkg_install() {
    local packages="$@"
    
    if [[ -z "$packages" ]]; then
        log_error "No packages specified"
        return 1
    fi
    
    log_info "Installing: $packages"
    $PKG_INSTALL $packages
    return $?
}

#------------------------------------------------
# Install Package Silently
#------------------------------------------------
pkg_install_silent() {
    local packages="$@"
    
    if [[ -z "$packages" ]]; then
        return 1
    fi
    
    $PKG_INSTALL $packages &>/dev/null
    return $?
}

#------------------------------------------------
# Remove Package(s)
#------------------------------------------------
pkg_remove() {
    local packages="$@"
    
    if [[ -z "$packages" ]]; then
        log_error "No packages specified"
        return 1
    fi
    
    log_info "Removing: $packages"
    $PKG_REMOVE $packages
    return $?
}

#------------------------------------------------
# Purge Package(s)
#------------------------------------------------
pkg_purge() {
    local packages="$@"
    
    if [[ -z "$packages" ]]; then
        log_error "No packages specified"
        return 1
    fi
    
    log_info "Purging: $packages"
    $PKG_PURGE $packages
    return $?
}

#------------------------------------------------
# Auto Remove
#------------------------------------------------
pkg_autoremove() {
    log_info "Removing unused packages..."
    $PKG_AUTOREMOVE &>/dev/null
    return $?
}

#------------------------------------------------
# Check if Package Installed
#------------------------------------------------
pkg_installed() {
    local package="$1"
    
    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$package" &>/dev/null
            ;;
    esac
    
    return $?
}

#------------------------------------------------
# Search Package
#------------------------------------------------
pkg_search() {
    local query="$1"
    $PKG_SEARCH "$query"
}

#------------------------------------------------
# Get Package Info
#------------------------------------------------
pkg_info() {
    local package="$1"
    $PKG_INFO "$package"
}

#------------------------------------------------
# Get Package Version
#------------------------------------------------
pkg_version() {
    local package="$1"
    
    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$package" 2>/dev/null | awk '/^ii/{print $3}'
            ;;
        dnf|yum)
            rpm -q --queryformat '%{VERSION}-%{RELEASE}' "$package" 2>/dev/null
            ;;
    esac
}

#------------------------------------------------
# Install Multiple Dependencies
#------------------------------------------------
install_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! pkg_installed "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Installing missing dependencies: ${missing[*]}"
        pkg_install "${missing[@]}"
    else
        log_info "All dependencies already installed"
    fi
}

#------------------------------------------------
# Add Repository (Debian/Ubuntu)
#------------------------------------------------
apt_add_repo() {
    local repo="$1"
    local key_url="$2"
    local key_file="$3"
    
    if [[ "$PKG_MANAGER" != "apt" ]]; then
        log_error "apt_add_repo only works on Debian-based systems"
        return 1
    fi
    
    # Install prerequisites
    pkg_install_silent software-properties-common apt-transport-https ca-certificates gnupg
    
    # Add GPG key if provided
    if [[ -n "$key_url" && -n "$key_file" ]]; then
        curl -fsSL "$key_url" | gpg --dearmor -o "$key_file"
    fi
    
    # Add repository
    if [[ -n "$repo" ]]; then
        echo "$repo" > /etc/apt/sources.list.d/custom.list
        pkg_update
    fi
}

#------------------------------------------------
# Add Repository (RHEL)
#------------------------------------------------
dnf_add_repo() {
    local repo_url="$1"
    
    if [[ "$PKG_MANAGER" != "dnf" && "$PKG_MANAGER" != "yum" ]]; then
        log_error "dnf_add_repo only works on RHEL-based systems"
        return 1
    fi
    
    if [[ -n "$repo_url" ]]; then
        $PKG_INSTALL "$repo_url"
    fi
}

#------------------------------------------------
# Enable Repository (RHEL)
#------------------------------------------------
dnf_enable_repo() {
    local repo="$1"
    
    if command -v dnf &>/dev/null; then
        dnf config-manager --set-enabled "$repo" &>/dev/null
    fi
}

#------------------------------------------------
# Enable Module (RHEL)
#------------------------------------------------
dnf_enable_module() {
    local module="$1"
    local stream="$2"
    
    if command -v dnf &>/dev/null; then
        dnf module reset "$module" -y &>/dev/null
        dnf module enable "$module:$stream" -y &>/dev/null
    fi
}

#------------------------------------------------
# Clean Cache
#------------------------------------------------
pkg_clean() {
    log_info "Cleaning package cache..."
    
    case "$PKG_MANAGER" in
        apt)
            apt-get clean
            apt-get autoclean
            ;;
        dnf)
            dnf clean all
            ;;
        yum)
            yum clean all
            ;;
    esac
}

#------------------------------------------------
# Initialize
#------------------------------------------------
detect_pkg_manager
