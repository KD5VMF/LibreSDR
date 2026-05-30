# LibreSDR / Pluto+ QSPI Recovery Package v0.33

This repository restores a LibreSDR / Pluto+ style SDR back to **internal QSPI boot** using a known-working `v0.33-dirty` QSPI image set.

It is intended for the situation where the SDR still boots from an SD card, but no longer boots from internal QSPI after a bad firmware flash, wrong PlutoSDR firmware, or failed update attempt.

After recovery, the expected internal boot banner is similar to:

```text
Welcome to Pluto
v0.33-dirty
```

That banner is normal for this recovery image. The purpose of this package is to recover a working internal QSPI boot path first. Upgrade only after you have backed up the working QSPI image.

## What this package contains

```text
boot_file/
  BOOT.BIN
  image.ub

burn_flash/
  autoconfig.sh                  Checked full-QSPI restore script
  autoconfig_original_minimal.sh Original 4-line dd script, kept for reference
  mtdblock0                      qspi-fsbl-uboot image, 1 MiB
  mtdblock1                      qspi-uboot-env image, 128 KiB
  mtdblock2                      qspi-nvmfs image, 896 KiB
  mtdblock3                      qspi-linux image, 30 MiB

docs/
  RECOVERY_WALKTHROUGH.md
  TROUBLESHOOTING.md

ASK_CHATGPT_FOR_HELP.txt
CHECKSUMS_SHA256.txt
LICENSE_NOTICE.md
README.md
RELEASE_NOTES.md
SAFETY_WARNING.md
VERIFY_PACKAGE.sh
boot+qspi.txt
```

## Hardware this is for

Use this only when the SDR shows this exact QSPI partition layout:

```text
dev:    size   erasesize  name
mtd0: 00100000 00010000 "qspi-fsbl-uboot"
mtd1: 00020000 00010000 "qspi-uboot-env"
mtd2: 000e0000 00010000 "qspi-nvmfs"
mtd3: 01e00000 00010000 "qspi-linux"
```

Do **not** use this on a stock ADALM-Pluto, a different SDR, or any board with a different `/proc/mtd` layout.

## Important safety warning

This restore overwrites all four internal QSPI partitions:

```text
/dev/mtdblock0  bootloader
/dev/mtdblock1  U-Boot environment
/dev/mtdblock2  nonvolatile/config filesystem
/dev/mtdblock3  Linux/FPGA firmware image
```

The checked `burn_flash/autoconfig.sh` script verifies the board layout and image sizes, backs up your current QSPI to the SD card, writes the four images, then compares the written flash against the source images.

## Quick recovery steps

### 1. Prepare the SD card

If you already have an SD card that boots the SDR, keep using that card and copy the entire `burn_flash` folder to the root of the SD card.

If you need a recovery SD card from this package, format a small SD card as FAT32 and copy the contents of `boot_file/` to the root of the SD card. Then also copy the entire `burn_flash` folder to the root of the SD card.

The SD card should contain at least:

```text
BOOT.BIN
image.ub
burn_flash/autoconfig.sh
burn_flash/mtdblock0
burn_flash/mtdblock1
burn_flash/mtdblock2
burn_flash/mtdblock3
```

### 2. Boot from SD and log in

Use the serial console, commonly 115200 baud.

Common credentials are:

```text
login: root
password: analog
```

### 3. Confirm the board layout

At the root shell, run:

```sh
cat /proc/mtd
```

Confirm it matches the four-partition layout shown above.

### 4. Mount the SD card

Try:

```sh
mkdir -p /mnt/sd
mount /dev/mmcblk0p1 /mnt/sd
```

### 5. Run the checked restore script

```sh
cd /mnt/sd/burn_flash
chmod +x autoconfig.sh
./autoconfig.sh
```

When prompted, type:

```text
YES
```

The script will create a backup folder next to `burn_flash`, then write and verify all four QSPI images.

### 6. Shut down and test internal QSPI boot

Only after the script prints `SUCCESS`, run:

```sh
sync
poweroff
```

Remove the SD card, then power the SDR back on.

Expected result:

```text
Welcome to Pluto
v0.33-dirty
```

## After recovery: make a working backup

Once QSPI boot works again, make a backup before attempting any update.

From another Linux machine:

```bash
mkdir -p ~/libresdr_qspi_backup_working_v033
cd ~/libresdr_qspi_backup_working_v033
ssh root@192.168.1.10 'cat /proc/mtd; uname -a; cat /proc/cmdline' | tee device_info.txt
ssh root@192.168.1.10 'cat /dev/mtd0' > mtd0_qspi-fsbl-uboot_WORKING_v033.bin
ssh root@192.168.1.10 'cat /dev/mtd1' > mtd1_qspi-uboot-env_WORKING_v033.bin
ssh root@192.168.1.10 'cat /dev/mtd2' > mtd2_qspi-nvmfs_WORKING_v033.bin
ssh root@192.168.1.10 'cat /dev/mtd3' > mtd3_qspi-linux_WORKING_v033.bin
sha256sum *.bin | tee SHA256SUMS.txt
```

Do not flash stock Analog Devices PlutoSDR firmware unless you are certain it is compatible with your LibreSDR/Pluto+ hardware. A wrong firmware can break internal boot again.

## Using ChatGPT to help

Open `ASK_CHATGPT_FOR_HELP.txt`, copy the prompt, and paste it into ChatGPT along with your terminal output. ChatGPT can help verify `/proc/mtd`, file sizes, mount points, and restore output before you commit to writing QSPI.
