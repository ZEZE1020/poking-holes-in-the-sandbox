#!/usr/bin/env bash
set -Eeuo pipefail

if [ "$#" -gt 0 ]; then
  printf '%s\n' "$1"
  exit 0
fi

ip="$(curl --fail --silent --show-error --location --max-time 10 https://api.ipify.org)"

if ! printf '%s\n' "$ip" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'; then
  echo "Could not determine a valid public IPv4 address: $ip" >&2
  exit 1
fi

printf '%s/32\n' "$ip"
