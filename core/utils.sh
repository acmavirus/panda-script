#!/bin/bash
#================================================
# Panda Script v2.0 - Helper Utilities
# Website: https://panda-script.com
#================================================

generate_password() {
    local length="${1:-16}"
    tr -dc 'A-Za-z0-9!@#$%' < /dev/urandom | head -c "$length"
}

generate_random_string() {
    local length="${1:-12}"
    tr -dc 'a-z0-9' < /dev/urandom | head -c "$length"
}

backup_file() {
    local file="$1"
    [[ -f "$file" ]] && cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
}

file_contains() {
    local file="$1"
    local pattern="$2"
    grep -q "$pattern" "$file" 2>/dev/null
}

add_line_if_not_exists() {
    local file="$1"
    local line="$2"
    grep -qF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

remove_line() {
    local file="$1"
    local pattern="$2"
    sed -i "/$pattern/d" "$file" 2>/dev/null
}

get_ram_mb() {
    free -m | awk '/^Mem:/{print $2}'
}

get_ram_used_percent() {
    free | awk '/^Mem:/{printf "%.0f", $3/$2*100}'
}

get_cpu_cores() {
    nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo
}

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
}

get_disk_usage() {
    df -h / | awk 'NR==2{print $5}' | tr -d '%'
}

get_load_average() {
    cat /proc/loadavg | awk '{print $1, $2, $3}'
}

get_uptime_seconds() {
    cat /proc/uptime | awk '{print int($1)}'
}

get_uptime_human() {
    uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}'
}

get_hostname() {
    hostname
}

get_timezone() {
    timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}' || cat /etc/timezone 2>/dev/null
}

db_query() {
    local query="$1"
    sqlite3 "${PANDA_DB_FILE:-/opt/panda/data/db/panda.db}" "$query"
}

db_insert() {
    local table="$1"
    shift
    local query="INSERT INTO $table VALUES ($@)"
    sqlite3 "${PANDA_DB_FILE}" "$query"
}

is_valid_email() {
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

sanitize_string() {
    echo "$1" | tr -cd '[:alnum:]._-'
}

json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | jq -r ".$key" 2>/dev/null
}

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

to_uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}
