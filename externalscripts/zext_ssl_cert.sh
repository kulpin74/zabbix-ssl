#!/bin/bash
#------------------------------------------------------------
# zext_ssl_cert.sh
# Script checks for number of days until certificate expires,
# the issuing authority, or the SHA-256 fingerprint depending
# on the switch passed on the command line.
#
# Based on script from aperto.fr (http://aperto.fr/cms/en/blog/15-blog-en/15-ssl-certificate-expiration-monitoring-with-zabbix.html)
# with additions by racooper@tamu.edu and extended by nils@sxda.io for timeout & fingerprint support.
#------------------------------------------------------------

DEBUG=0
TIMEOUT=10  # Timeout in seconds for openssl connection

if [ "$DEBUG" -gt 0 ]; then
    exec 2>>/tmp/my.log
    set -x
fi

f=$1
host=$2
port=$3
sni=$4
proto=$5

if [ -z "$sni" ]; then
    servername=$host
else
    servername=$sni
fi

if [ -n "$proto" ]; then
    starttls="-starttls $proto"
fi

get_cert() {
    timeout "$TIMEOUT" openssl s_client -servername "$servername" -connect "$host:$port" -showcerts $starttls </dev/null 2>/dev/null |
    sed -n '/BEGIN CERTIFICATE/,/END CERT/p'
}

case $f in
-d)
    cert_data="$(get_cert)"
    end_date=$(echo "$cert_data" | openssl x509 -enddate -noout 2>/dev/null | sed -n 's/notAfter=//p' | sed 's/ GMT//g')

    if [ -n "$end_date" ]; then
        end_date_seconds=$(date '+%s' --date "$end_date")
        now_seconds=$(date '+%s')
        echo "($end_date_seconds - $now_seconds) / 86400" | bc
    fi
    ;;

-i)
    cert_data="$(get_cert)"
    issue_dn=$(echo "$cert_data" | openssl x509 -issuer -noout 2>/dev/null | sed -n 's/issuer=//p')

    if [ -n "$issue_dn" ]; then
        issuer=$(echo "$issue_dn" | sed -n 's/.*CN=*//p')
        echo "$issuer"
    fi
    ;;

-f)
    cert_data="$(get_cert)"
    fingerprint=$(echo "$cert_data" | openssl x509 -fingerprint -sha256 -noout 2>/dev/null | sed 's/^.*=//')

    if [ -n "$fingerprint" ]; then
        echo "$fingerprint"
    fi
    ;;

*)
    echo "usage: $0 [-i|-d|-f] hostname port sni [proto]"
    echo "    -i  Show Issuer"
    echo "    -d  Show valid days remaining"
    echo "    -f  Show SHA-256 fingerprint"
    ;;
esac

