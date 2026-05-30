#!/bin/sh
set -eu

# LibreSDR / Pluto+ QSPI full restore helper
# Restores the four QSPI partitions from mtdblock0..mtdblock3 in this folder.
# This checked version verifies the board layout, image sizes, backs up current QSPI,
# writes all four partitions, and compares the written flash against the source images.

cd "$(dirname "$0")"

EXPECTED_MTD0=1048576
EXPECTED_MTD1=131072
EXPECTED_MTD2=917504
EXPECTED_MTD3=31457280
EXPECTED_ERASE=00010000

info() { echo "$@"; }
fail() { echo "ERROR: $@"; exit 1; }

check_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

check_size() {
    file="$1"
    want="$2"
    [ -f "$file" ] || fail "Missing file: $file"
    got=$(wc -c < "$file")
    info "$file size: $got bytes, expected: $want bytes"
    [ "$got" = "$want" ] || fail "Size mismatch for $file"
}

require_mtd_line() {
    name="$1"
    sizehex="$2"
    line=$(grep '"'$name'"' /proc/mtd || true)
    [ -n "$line" ] || fail "/proc/mtd does not contain partition named $name"
    echo "$line" | grep -q "$sizehex $EXPECTED_ERASE" || fail "$name does not have expected size/erase layout. Line: $line"
}

backup_one() {
    dev="$1"
    out="$2"
    info "Backing up $dev -> $out"
    cat "$dev" > "$out"
}

write_one() {
    image="$1"
    target="$2"
    info
    info "Writing $image -> $target"
    dd if="$image" of="$target" bs=64K conv=fsync
    sync
    info "Verifying $image against $target"
    cmp "$image" "$target"
}

info "===== LibreSDR / Pluto+ QSPI full restore ====="
info "This overwrites all four internal QSPI partitions:"
info "  /dev/mtdblock0  qspi-fsbl-uboot"
info "  /dev/mtdblock1  qspi-uboot-env"
info "  /dev/mtdblock2  qspi-nvmfs"
info "  /dev/mtdblock3  qspi-linux"
info
info "Use this only on LibreSDR/Pluto+ style hardware with the exact /proc/mtd layout below."
info

check_cmd cat
check_cmd dd
check_cmd cmp
check_cmd grep
check_cmd wc
check_cmd mkdir
check_cmd sync

[ -e /dev/mtdblock0 ] || fail "/dev/mtdblock0 not found"
[ -e /dev/mtdblock1 ] || fail "/dev/mtdblock1 not found"
[ -e /dev/mtdblock2 ] || fail "/dev/mtdblock2 not found"
[ -e /dev/mtdblock3 ] || fail "/dev/mtdblock3 not found"
[ -e /dev/mtd0 ] || fail "/dev/mtd0 not found"
[ -e /dev/mtd1 ] || fail "/dev/mtd1 not found"
[ -e /dev/mtd2 ] || fail "/dev/mtd2 not found"
[ -e /dev/mtd3 ] || fail "/dev/mtd3 not found"

info "===== Current /proc/mtd ====="
cat /proc/mtd || true
info

require_mtd_line qspi-fsbl-uboot 00100000
require_mtd_line qspi-uboot-env 00020000
require_mtd_line qspi-nvmfs 000e0000
require_mtd_line qspi-linux 01e00000

info "QSPI partition layout matches this recovery package."
info

check_size mtdblock0 "$EXPECTED_MTD0"
check_size mtdblock1 "$EXPECTED_MTD1"
check_size mtdblock2 "$EXPECTED_MTD2"
check_size mtdblock3 "$EXPECTED_MTD3"

if command -v sha256sum >/dev/null 2>&1; then
    info
    info "===== Recovery image SHA256 checksums ====="
    sha256sum mtdblock0 mtdblock1 mtdblock2 mtdblock3
fi

info
info "WARNING: This will BACK UP the current QSPI, then OVERWRITE QSPI."
info "Do not continue if you are not booted from SD card or serial recovery."
printf "Type YES and press Enter to continue: "
read answer
[ "$answer" = "YES" ] || fail "User did not type YES. Nothing was written."

stamp=$(date +%Y%m%d_%H%M%S 2>/dev/null || echo unknown_time)
backup_dir="../qspi_backup_before_restore_$stamp"
mkdir -p "$backup_dir"

info
info "===== Backing up current QSPI to $backup_dir ====="
backup_one /dev/mtd0 "$backup_dir/current_mtd0_qspi-fsbl-uboot.bin"
backup_one /dev/mtd1 "$backup_dir/current_mtd1_qspi-uboot-env.bin"
backup_one /dev/mtd2 "$backup_dir/current_mtd2_qspi-nvmfs.bin"
backup_one /dev/mtd3 "$backup_dir/current_mtd3_qspi-linux.bin"
sync

if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$backup_dir"/*.bin > "$backup_dir/SHA256SUMS.txt"
    cat "$backup_dir/SHA256SUMS.txt"
fi

info
info "===== Writing recovery images ====="
write_one mtdblock0 /dev/mtdblock0
write_one mtdblock1 /dev/mtdblock1
write_one mtdblock2 /dev/mtdblock2
write_one mtdblock3 /dev/mtdblock3

info
info "===== Header check ====="
if command -v hexdump >/dev/null 2>&1; then
    echo "--- /dev/mtd0 ---"; hexdump -C /dev/mtd0 | head -4 || true
    echo "--- /dev/mtd1 ---"; hexdump -C /dev/mtd1 | head -4 || true
    echo "--- /dev/mtd2 ---"; hexdump -C /dev/mtd2 | head -4 || true
    echo "--- /dev/mtd3 ---"; hexdump -C /dev/mtd3 | head -4 || true
fi

info
info "SUCCESS: QSPI recovery images were written and verified."
info
info "Next commands:"
info "  sync"
info "  poweroff"
info
info "Then remove the SD card and power the LibreSDR back on."
info "Expected boot banner: Welcome to Pluto / v0.33-dirty."
