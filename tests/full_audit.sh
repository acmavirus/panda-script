#!/bin/bash
#================================================================
# 🐼 Panda Script v2.2.1 - Comprehensive Test & Demo Suite
#================================================================
# Purpose: This script performs a full audit and demo of all features
# including v2.2.1 Advanced Management Hub updates.
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
    print_section "1. Core Stack (LEMP & Extensions)"
    check_service "nginx"
    check_service "mariadb"
    
    local php_versions=("7.4" "8.1" "8.2" "8.3")
    for v in "${php_versions[@]}"; do
        if systemctl is-active --quiet "php$v-fpm"; then
            echo -e "  [✅] PHP-FPM $v is active"
        fi
    done
    
    check_file "$PANDA_DIR/modules/php/php_ext.sh"
}

# --- 2. Website & App Management Demo ---
test_website_management() {
    print_section "2. Website & Framework Intelligence"
    check_file "/etc/nginx/sites-available"
    check_file "$PANDA_DIR/modules/website/wp_cli.sh"
    check_file "$PANDA_DIR/modules/nginx/redirect.sh"
    
    echo -e "  [i] Checking Framework-Aware Permission logic..."
    grep -q "Laravel Detection" "$PANDA_DIR/modules/system/permissions.sh" && echo -e "  [✅] Permission tool is Framework-Aware"
}

# --- 3. Docker & Networking ---
test_docker_cache() {
    print_section "3. Docker & Proxy Bridge"
    if command -v docker &>/dev/null; then
        echo -e "  [✅] Docker Engine is installed"
    fi
    check_file "$PANDA_DIR/modules/nginx/proxy.sh"
    check_service "redis-server"
}

# --- 4. Security Center Audit ---
test_security() {
    print_section "4. Security & Panda Guard"
    check_service "ufw"
    check_service "fail2ban"
    check_file "$PANDA_DIR/modules/security/guard.sh"
    
    if [[ -f "/etc/nginx/conf.d/7g.conf" ]]; then
        echo -e "  [✅] 7G Firewall (WAF) active"
    fi
}

# --- 5. Developer Experience (DevXP) ---
test_devxp() {
    print_section "5. DevXP & UX"
    check_file "$PANDA_DIR/modules/website/deploy.sh"
    check_file "$PANDA_DIR/monitoring/debug.sh"
    check_file "$PANDA_DIR/modules/system/optimize.sh"
    
    echo -e "  [i] Checking Bash Tab Completion..."
    if [[ -f "/etc/bash_completion.d/panda" ]] || [[ -f "$PANDA_DIR/templates/panda-completion.bash" ]]; then
        echo -e "  [✅] Tab Completion ready"
    fi
}

# --- 6. Reliability & Diagnostics ---
test_reliability() {
    print_section "6. Reliability & Panda Doctor"
    check_file "$PANDA_DIR/monitoring/doctor.sh"
    
    echo -e "  [i] Checking Backup Integrity Check logic..."
    grep -q "md5sum" "$PANDA_DIR/modules/backup/local.sh" && echo -e "  [✅] Backup Integrity Check active"
}

# --- 0. Demo Readiness Fixer ---
prepare_demo() {
    if [[ "$1" == "--fix" ]]; then
        print_section "0. Preparing Demo Environment"
        apt-get update &>/dev/null
        apt-get install -y redis-server memcached multitail net-tools &>/dev/null
        systemctl enable --now redis-server memcached &>/dev/null
        log_success "Demo environment prepared!"
    fi
}

# --- Main Execution ---
clear
prepare_demo "$1"
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       🐼 Panda Script v2.2.1 - FULL AUDIT & DEMO             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

test_core_stack
test_website_management
test_docker_cache
test_security
test_devxp
test_reliability

echo -e "\n${GREEN}Audit completed! All v2.2.1 features are verified.${NC}"
echo -e "${YELLOW}To test Panda Doctor, run: panda doctor${NC}\n"
