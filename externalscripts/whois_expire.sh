#!/bin/bash

# --- Prerequisite Check ---
check_dependencies() {
    local missing=0
    for cmd in curl jq date grep awk timeout whois; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: '$cmd' is not installed or not found in PATH." >&2
            missing=1
        fi
    done
    if [ "$missing" -ne 0 ]; then
        echo "Please install the missing commands and try again." >&2
        exit 1
    fi
}

check_dependencies

# Configuration
WHOIS_TIMEOUT=3  # seconds
RDAP_TIMEOUT=2   # seconds

# Hardcoded RDAP servers for instant lookups
declare -A RDAP_SERVERS=(
    ["dev"]="https://pubapi.registry.google/rdap/domain/"
    ["app"]="https://pubapi.registry.google/rdap/domain/"
    ["page"]="https://pubapi.registry.google/rdap/domain/"
    ["com"]="https://rdap.verisign.com/com/v1/domain/"
    ["net"]="https://rdap.verisign.com/net/v1/domain/"
    ["org"]="https://rdap.publicinterestregistry.org/v1/domain/"
)

# Error handling
handle_error() {
    local err_msg="ERROR: $1"
    echo "$err_msg" >&2
    logger -t domain_check "$err_msg" 2>/dev/null
    exit 1
}

# Sanitize and validate domain input
if [ $# -ne 1 ]; then
    handle_error "Usage: $0 domain_name"
fi

domain=$(echo "$1" | awk '!/[^a-zA-Z0-9.-]/ {print tolower($0)}')
[ -z "$domain" ] && handle_error "Invalid domain format"
tld=${domain##*.}

# Try to get RDAP server dynamically if not in hardcoded list
get_rdap_server() {
    local tld=$1
    local url="https://data.iana.org/rdap/dns.json"
    local server=$(curl -s --max-time "$RDAP_TIMEOUT" "$url" 2>/dev/null | \
                   jq -r ".services[] | select(.[0][] | contains(\"${tld}\")) | .[1][0]" 2>/dev/null | head -1)
    if [ -n "$server" ]; then
        echo "${server}domain/"
    fi
}

# Fast RDAP lookup
get_rdap_expiration() {
    local tld=$1
    local domain=$2
    local url="${RDAP_SERVERS[$tld]}${domain}"
    [ -z "$url" ] && return 1
    local response=$(curl -s --max-time "$RDAP_TIMEOUT" -H "Accept: application/rdap+json" "$url" 2>/dev/null)
    local expiration=$(echo "$response" | jq -r '.events[]? | select(.eventAction=="expiration") | .eventDate' 2>/dev/null)
    [ -n "$expiration" ] && date -d "$expiration" "+%Y-%m-%d" 2>/dev/null
}

# WHOIS lookup
get_whois_expiration() {
    local domain=$1
    local output=$(timeout "$WHOIS_TIMEOUT" whois "$domain" 2>&1)
    local exp_date=$(echo "$output" | grep -oE 'Expir.*date:[[:space:]]*[0-9-]+|paid-till:[[:space:]]*[0-9-]+' | \
                 head -n1 | awk '{print $NF}' | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    [ -n "$exp_date" ] && echo "$exp_date"
}

# Normalize date (for robustness)
normalize_date() {
    date -d "$(echo "$1" | sed 's/[^0-9\-]//g')" "+%Y-%m-%d" 2>/dev/null
}

# Main execution flow
current_epoch=$(date +%s)
expiration_date=""

# 1. Try RDAP if server is known (hardcoded)
if [ -n "${RDAP_SERVERS[$tld]}" ]; then
    expiration_date=$(get_rdap_expiration "$tld" "$domain")
fi

# 2. If not, try to discover RDAP server dynamically
if [ -z "$expiration_date" ] && [ -z "${RDAP_SERVERS[$tld]}" ]; then
    dynamic_server=$(get_rdap_server "$tld")
    if [ -n "$dynamic_server" ]; then
        RDAP_SERVERS["$tld"]="$dynamic_server"
        expiration_date=$(get_rdap_expiration "$tld" "$domain")
    fi
fi

# 3. Fall back to WHOIS
if [ -z "$expiration_date" ]; then
    expiration_date=$(get_whois_expiration "$domain")
fi

# Normalize date (just in case)
expiration_date=$(normalize_date "$expiration_date")

if [ -z "$expiration_date" ]; then
    handle_error "Could not determine expiration date for $domain"
fi

# Calculate days until expiration
expiration_epoch=$(date -d "$expiration_date" +%s 2>/dev/null)
if [ -z "$expiration_epoch" ]; then
    handle_error "Invalid date format: $expiration_date"
fi

days=$(( (expiration_epoch - current_epoch) / 86400 ))

# Output result
echo "$days"