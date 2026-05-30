# Release Notes

## v0.33 QSPI Recovery Package

Purpose: restore LibreSDR / Pluto+ internal QSPI boot after a failed or wrong firmware flash.

Expected recovered boot banner:

```text
Welcome to Pluto
v0.33-dirty
```

Package highlights:

- Includes full raw QSPI image set: `mtdblock0` through `mtdblock3`.
- Includes optional SD boot files in `boot_file/`.
- Replaces the original bare `dd` restore script with a checked `autoconfig.sh`.
- Keeps the original minimal restore script as `autoconfig_original_minimal.sh` for audit/reference.
- Adds checksums, walkthrough, troubleshooting notes, and ChatGPT assistance prompt.

Known limitation:

- This restores an older/different `v0.33-dirty` firmware image. Its purpose is recovery first, not latest firmware.
