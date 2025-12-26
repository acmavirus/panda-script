#!/bin/bash
#================================================
# Panda Script v2.0 - Kernel Hardening
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

SYSCTL_CONF="/etc/sysctl.d/99-panda-security.conf"

harden_kernel() {
    log_info "Hardening kernel..."
    
    cat > "$SYSCTL_CONF" << 'EOF'
# Network Security
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# IPv6 Security
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0

# Memory Protection
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

# File System
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

    sysctl -p "$SYSCTL_CONF"
    log_success "Kernel hardened"
}

optimize_kernel_network() {
    log_info "Optimizing kernel network..."
    
    cat > /etc/sysctl.d/99-panda-network.conf << 'EOF'
# TCP Performance
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 262144

# Memory
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2

# File Descriptors
fs.file-max = 2097152
fs.nr_open = 2097152
EOF

    sysctl -p /etc/sysctl.d/99-panda-network.conf
    log_success "Network optimized"
}

get_kernel_status() {
    echo "Kernel Security Settings:"
    echo ""
    
    local settings=(
        "net.ipv4.tcp_syncookies"
        "net.ipv4.conf.all.rp_filter"
        "kernel.randomize_va_space"
    )
    
    for setting in "${settings[@]}"; do
        local value=$(sysctl -n "$setting" 2>/dev/null)
        print_line "$setting" "${value:-N/A}"
    done
}
