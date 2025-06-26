#!/bin/bash

cd /usr/lib/zabbix/externalscripts/ || exit 1

if [[ "$1" != "ssl_check.json" ]]; then
  echo "Error: Only 'ssl_check.json' is allowed as a parameter."
  exit 1
fi

cat "$1"
