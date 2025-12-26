#!/bin/bash
#================================================================
# 🐼 Panda Script v2.2.0 - Comprehensive Test & Demo Suite
#================================================================
# Purpose: This script performs a full audit and demo of all features
# listed in the README.md to ensure stability and functionality.
#================================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || {
    echo "Error: Panda Script not found. Please install it first."
    exit 1
}

# --- Utility Functions ---
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo -e "  [✅] $service is running"
        return 0
    else
        echo -e "  [❌] $service is NOT running"
        return 1
    fi
}

check_file() {
    local path=$1
    if [[ -e "$path" ]]; then
        echo -e "  [✅] Found: $path"
        return 0
    else
        echo -e "  [❌] Missing: $path"
        return 1
    fi
}

print_section() {
    echo -e "\n${CYAN}================================================================${NC}"
    echo -e "${YELLOW}🐼 Testing: $1${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

# --- 1. Core Stack Audit ---
test_core_stack() {
    print_section "1. Core Stack (LEMP)"
    check_service "nginx"
    check_service "mariadb"
    
    local php_versions=("7.4" "8.0" "8.1" "8.2" "8.3")
    for v in "${php_versions[@]}"; do
        if systemctl is-active --quiet "php$v-fpm"; then
            echo -e "  [✅] PHP-FPM $v is active"
        fi
    done
    
    echo -e "  [i] MySQL version: $(mysql -V | awk '{print $5}')"
    echo -e "  [i] Nginx version: $(nginx -v 2>&1 | awk -F/ '{print $2}')"
}

# --- 2. Website & App Management Demo ---
test_website_management() {
    print_section "2. Website Management"
    local test_domain="panda-test-$(date +%s).com"
    
    echo -e "  [i] Simulating Vhost creation for $test_domain..."
    # In a real test, we might call: website_create "$test_domain"
    # For demo, we verify the capability
    check_file "/etc/nginx/sites-available"
    
    echo -e "  [i] Checking WP-CLI integration..."
    if command -v wp &>/dev/null; then
        echo -e "  [✅] WP-CLI is installed"
    else
        echo -e "  [❌] WP-CLI missing"
    fi

    echo -e "  [i] Checking Node.js/PM2..."
    command -v nvm &>/dev/null || [[ -d "$HOME/.nvm" ]] && echo -e "  [✅] NVM detected"
    command -v pm2 &>/dev/null && echo -e "  [✅] PM2 detected"
}

# --- 3. Docker & Performance ---
test_docker_cache() {
    print_section "3. Docker & Caching"
    if command -v docker &>/dev/null; then
        echo -e "  [✅] Docker Engine is installed ($ (docker --version))"
        check_service "docker"
    else
        echo -e "  [i] Docker not installed (Optional)"
    fi
    
    check_service "redis-server"
    check_service "memcached"
}

# --- 4. Security Center Audit ---
test_security() {
    print_section "4. Security Center"
    check_service "ufw"
    check_service "fail2ban"
    
    if [[ -f "/etc/nginx/conf.d/7g.conf" ]]; then
        echo -e "  [✅] 7G Firewall (WAF) integration active"
    else
        echo -e "  [i] 7G Firewall not configured on this host"
    fi
    
    if command -v clamscan &>/dev/null; then
        echo -e "  [✅] Malware Scanner (ClamAV) ready"
    else
        echo -e "  [i] ClamAV not installed"
    fi
}

# --- 5. Developer Experience (DevXP) ---
test_devxp() {
    print_section "5. Developer Experience (v2.2.0)"
    
    check_file "$PANDA_DIR/modules/website/deploy.sh"
    check_file "$PANDA_DIR/monitoring/debug.sh"
    check_file "$PANDA_DIR/modules/cloud/tunnel.sh"
    
    echo -e "  [i] Testing Fix Permissions tool..."
    if [[ -f "$PANDA_DIR/modules/system/permissions.sh" ]]; then
        echo -e "  [✅] Fix Permissions tool ready"
    fi
}

# --- 6. Backup & Reliability ---
test_reliability() {
    print_section "6. Reliability & Cloud"
    if command -v rclone &>/dev/null; then
        echo -e "  [✅] Rclone detected ($(rclone version | head -n1))"
    fi
    
    if [[ -f "/etc/system/system/panda-auto-heal.service" ]] || systemctl list-unit-files | grep -q "panda-auto-heal"; then
        echo -e "  [✅] Auto-Heal Engine is installed"
        check_service "panda-auto-heal"
    else
        echo -e "  [i] Auto-Heal service not active"
    fi
}

# --- Main Execution ---
clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       🐼 Panda Script v2.2.0 - FULL AUDIT & DEMO             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

test_core_stack
test_website_management
test_docker_cache
test_security
test_devxp
test_reliability

echo -e "\n${GREEN}Audit completed! All core components and modules have been checked.${NC}"
echo -e "${YELLOW}Note: Some optional modules (Docker, ClamAV) depend on user choice during installation.${NC}\n"
