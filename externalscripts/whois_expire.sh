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
CACHE_TTL=86400  # Cache validity in seconds (86400 = 1 day)
CACHE_FILE="/tmp/rdap_cache.$USER"
DOMAIN_CACHE="/tmp/domain_cache.$USER"

# Load caches if they exist
[ -f "$CACHE_FILE" ] && source "$CACHE_FILE"
[ -f "$DOMAIN_CACHE" ] && source "$DOMAIN_CACHE"

# Declare associative arrays for domain cache and cache timestamps
declare -A CACHE
declare -A CACHE_TIME

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

# Pre-cached RDAP servers for instant lookups
declare -A RDAP_SERVERS=(
    ["dev"]="https://pubapi.registry.google/rdap/domain/"
    ["app"]="https://pubapi.registry.google/rdap/domain/"
    ["page"]="https://pubapi.registry.google/rdap/domain/"
    ["com"]="https://rdap.verisign.com/com/v1/domain/"
    ["net"]="https://rdap.verisign.com/net/v1/domain/"
    ["org"]="https://rdap.publicinterestregistry.org/v1/domain/"
)

# Try to get RDAP server dynamically if not cached
get_rdap_server() {
    local tld=$1
    local url="https://data.iana.org/rdap/dns.json"
    local server=$(curl -s --max-time $RDAP_TIMEOUT "$url" 2>/dev/null | \
                   jq -r ".services[] | select(.[0][] | contains(\"${tld}\")) | .[1][0]" 2>/dev/null | head -1)
    if [ -n "$server" ]; then
        RDAP_SERVERS["$tld"]="${server}domain/"
        declare -p RDAP_SERVERS > "$CACHE_FILE"
    fi
    echo "$server"
}

# Fast RDAP lookup
get_rdap_expiration() {
    local tld=$1
    local domain=$2
    local url="${RDAP_SERVERS[$tld]}${domain}"
    [ -z "$url" ] && return 1
    local response=$(curl -s --max-time $RDAP_TIMEOUT -H "Accept: application/rdap+json" "$url" 2>/dev/null)
    local expiration=$(echo "$response" | jq -r '.events[]? | select(.eventAction=="expiration") | .eventDate' 2>/dev/null)
    [ -n "$expiration" ] && date -d "$expiration" "+%Y-%m-%d" 2>/dev/null
}

# WHOIS lookup
get_whois_expiration() {
    local domain=$1
    local output=$(timeout $WHOIS_TIMEOUT whois "$domain" 2>&1)
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

# Check domain cache first (with TTL validation)
if [ -n "${CACHE[$domain]}" ] && [ -n "${CACHE_TIME[$domain]}" ]; then
    cache_age=$((current_epoch - CACHE_TIME[$domain]))
    if [ "$cache_age" -lt "$CACHE_TTL" ]; then
        echo "$domain"
        echo "${CACHE[$domain]}"
        exit 0
    else
        # Cache expired, clean up old entries for this domain
        unset 'CACHE[$domain]'
        unset 'CACHE_TIME[$domain]'
    fi
fi

# Try RDAP if server is known
if [ -n "${RDAP_SERVERS[$tld]}" ]; then
    expiration_date=$(get_rdap_expiration "$tld" "$domain")
fi

# If not, try to discover RDAP server
if [ -z "$expiration_date" ] && [ -z "${RDAP_SERVERS[$tld]}" ]; then
    get_rdap_server "$tld" > /dev/null
    if [ -n "${RDAP_SERVERS[$tld]}" ]; then
        expiration_date=$(get_rdap_expiration "$tld" "$domain")
    fi
fi

# Fall back to WHOIS
if [ -z "$expiration_date" ]; then
    expiration_date=$(get_whois_expiration "$domain")
fi

# Try to normalize date (just in case)
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

# Update cache with both value and timestamp
CACHE["$domain"]=$days
CACHE_TIME["$domain"]=$current_epoch

# Save caches to disk
declare -p CACHE > "$DOMAIN_CACHE"
declare -p CACHE_TIME >> "$DOMAIN_CACHE"

echo "$days"