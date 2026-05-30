#!/bin/sh
set -eu

echo "===== Verify LibreSDR QSPI Recovery Package ====="

check_size() {
    file="$1"
    want="$2"
    [ -f "$file" ] || { echo "ERROR: missing $file"; exit 1; }
    got=$(wc -c < "$file")
    echo "$file size: $got bytes, expected: $want bytes"
    [ "$got" = "$want" ] || { echo "ERROR: size mismatch for $file"; exit 1; }
}

check_size burn_flash/mtdblock0 1048576
check_size burn_flash/mtdblock1 131072
check_size burn_flash/mtdblock2 917504
check_size burn_flash/mtdblock3 31457280

if command -v sha256sum >/dev/null 2>&1 && [ -f CHECKSUMS_SHA256.txt ]; then
    echo
    echo "Checking SHA256 sums..."
    sha256sum -c CHECKSUMS_SHA256.txt
fi

echo

echo "Package verification complete."
