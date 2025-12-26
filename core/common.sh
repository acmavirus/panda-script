#!/bin/bash
#================================================
# Panda Script v2.0 - Common Functions
# Colors, logging, prompts, UI functions
# Website: https://panda-script.com
#================================================

#------------------------------------------------
# Colors & Formatting
#------------------------------------------------
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export GRAY='\033[0;37m'
export NC='\033[0m'          # No Color
export BOLD='\033[1m'
export DIM='\033[2m'
export UNDERLINE='\033[4m'
export BLINK='\033[5m'
export REVERSE='\033[7m'

# Background colors
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'
export BG_BLUE='\033[44m'

#------------------------------------------------
# Logging Functions
#------------------------------------------------
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_to_file "INFO" "$1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_to_file "SUCCESS" "$1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_to_file "WARNING" "$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_to_file "ERROR" "$1"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${GRAY}[DEBUG]${NC} $1"
        log_to_file "DEBUG" "$1"
    fi
}

log_to_file() {
    local level="$1"
    local message="$2"
    local log_file="${PANDA_LOG_DIR:-/opt/panda/data/logs}/panda.log"
    
    if [[ -d "$(dirname "$log_file")" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$log_file"
    fi
}

#------------------------------------------------
# Print Functions
#------------------------------------------------
print_header() {
    local title="$1"
    local width="${2:-60}"
    
    echo ""
    echo -e "${CYAN}╔$(printf '═%.0s' $(seq 1 $((width-2))))╗${NC}"
    printf "${CYAN}║${NC} ${WHITE}%-$((width-4))s${NC} ${CYAN}║${NC}\n" "$title"
    echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $((width-2))))╝${NC}"
    echo ""
}

print_separator() {
    local width="${1:-60}"
    local char="${2:-─}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

print_line() {
    local label="$1"
    local value="$2"
    local width="${3:-50}"
    
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "$label" "$value"
}

print_status() {
    local label="$1"
    local status="$2"
    
    case "$status" in
        "running"|"active"|"ok"|"success")
            echo -e "  ${WHITE}$label${NC}: ${GREEN}● $status${NC}"
            ;;
        "stopped"|"inactive"|"failed"|"error")
            echo -e "  ${WHITE}$label${NC}: ${RED}● $status${NC}"
            ;;
        "warning"|"degraded")
            echo -e "  ${WHITE}$label${NC}: ${YELLOW}● $status${NC}"
            ;;
        *)
            echo -e "  ${WHITE}$label${NC}: ${GRAY}○ $status${NC}"
            ;;
    esac
}

#------------------------------------------------
# Progress Functions
#------------------------------------------------
show_spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    tput civis  # Hide cursor
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${BLUE}[${spin:$i:1}]${NC} $message"
        i=$(( (i + 1) % ${#spin} ))
        sleep 0.1
    done
    
    tput cnorm  # Show cursor
    echo -e "\r${GREEN}[✓]${NC} $message"
}

show_progress() {
    local current=$1
    local total=$2
    local width="${3:-30}"
    local message="${4:-}"
    
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%% %s" "$percent" "$message"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

#------------------------------------------------
# User Input Functions
#------------------------------------------------
prompt() {
    local message="$1"
    local default="$2"
    local result
    
    if [[ -n "$default" ]]; then
        read -p "$message [$default]: " result
        echo "${result:-$default}"
    else
        read -p "$message: " result
        echo "$result"
    fi
}

prompt_yn() {
    local message="$1"
    local default="${2:-y}"
    local result
    
    if [[ "$default" == "y" ]]; then
        read -p "$message [Y/n]: " result
        [[ ! "$result" =~ ^[Nn]$ ]]
    else
        read -p "$message [y/N]: " result
        [[ "$result" =~ ^[Yy]$ ]]
    fi
}

prompt_password() {
    local message="$1"
    local result
    
    read -s -p "$message: " result
    echo ""
    echo "$result"
}

prompt_select() {
    local message="$1"
    shift
    local options=("$@")
    local choice
    
    echo -e "${WHITE}$message${NC}"
    echo ""
    
    local i=1
    for option in "${options[@]}"; do
        echo "  $i) $option"
        ((i++))
    done
    
    echo ""
    read -p "Enter your choice [1]: " choice
    choice=${choice:-1}
    
    if [[ $choice -ge 1 && $choice -le ${#options[@]} ]]; then
        echo "${options[$((choice-1))]}"
    else
        echo ""
    fi
}

#------------------------------------------------
# Confirmation Functions
#------------------------------------------------
confirm() {
    local message="$1"
    local response
    
    echo -e "${YELLOW}⚠️  $message${NC}"
    read -p "Are you sure? [y/N]: " response
    
    [[ "$response" =~ ^[Yy]$ ]]
}

confirm_danger() {
    local message="$1"
    local confirm_text="$2"
    local response
    
    echo -e "${RED}🚨 DANGER: $message${NC}"
    echo -e "Type '${WHITE}$confirm_text${NC}' to confirm:"
    read -p "> " response
    
    [[ "$response" == "$confirm_text" ]]
}

#------------------------------------------------
# Table Functions
#------------------------------------------------
print_table_header() {
    local columns=("$@")
    local total_width=0
    
    # Calculate total width
    for col in "${columns[@]}"; do
        ((total_width += ${#col} + 3))
    done
    
    # Print separator
    printf "+"
    for col in "${columns[@]}"; do
        printf '%*s+' "$((${#col} + 2))" '' | tr ' ' '-'
    done
    echo ""
    
    # Print headers
    printf "|"
    for col in "${columns[@]}"; do
        printf " ${BOLD}%-${#col}s${NC} |" "$col"
    done
    echo ""
    
    # Print separator
    printf "+"
    for col in "${columns[@]}"; do
        printf '%*s+' "$((${#col} + 2))" '' | tr ' ' '-'
    done
    echo ""
}

#------------------------------------------------
# Wait & Countdown
#------------------------------------------------
wait_countdown() {
    local seconds=$1
    local message="${2:-Waiting...}"
    
    for ((i=seconds; i>0; i--)); do
        printf "\r$message $i seconds remaining...  "
        sleep 1
    done
    echo -e "\r$message Done!                        "
}

#------------------------------------------------
# Clear Screen & Pause
#------------------------------------------------
clear_screen() {
    clear
}

pause() {
    local message="${1:-Press any key to continue...}"
    read -n 1 -s -r -p "$message"
    echo ""
}

#------------------------------------------------
# Format Functions
#------------------------------------------------
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local i=0
    
    while (( bytes >= 1024 && i < 4 )); do
        bytes=$((bytes / 1024))
        ((i++))
    done
    
    echo "$bytes${units[$i]}"
}

format_seconds() {
    local seconds=$1
    local days=$((seconds / 86400))
    local hours=$(( (seconds % 86400) / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$((seconds % 60))
    
    if [[ $days -gt 0 ]]; then
        printf "%dd %dh %dm" $days $hours $minutes
    elif [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

format_date() {
    local timestamp="${1:-$(date +%s)}"
    date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null
}
