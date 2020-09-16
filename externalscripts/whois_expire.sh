#!/bin/bash

# Check to ensure argument has been passed.
if [ $# -ne 1 ]; then
        echo "usage: $0 domain_name"
        exit 1
fi

# Check to ensure whois is functional.
if ! type -tP whois &> /dev/null
then
        echo "Please install whois."
        exit 2
fi

domain=$1

# Check whois for the domain, filter out expire date, then awk filters the last field of the first line
if expiration_string=$(whois "$domain" 2>&1 | grep -Ei 'Expiration|Expires on|Expiry date|paid-till' | awk 'NR==1{print $NF}'); then
        expiration_epoch=$(date --date="$expiration_string" '+%s')
        rightnow_epoch=$(date '+%s')

        # Bash does lookups on arithmetic variables; no $ required.
        echo "$(( (expiration_epoch - rightnow_epoch) / 86400 ))"
else
        echo "ERROR executing whois for the $domain domain - $expiration_string"
        exit 3
fi
