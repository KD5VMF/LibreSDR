# Safety Warning

This package writes raw data directly to the SDR internal QSPI flash.

Only use it when:

- The SDR is a LibreSDR / Pluto+ style SDR.
- The SDR can still boot from SD card.
- `cat /proc/mtd` exactly matches the expected four-partition layout.
- You understand that all four QSPI partitions will be overwritten.

Do not use this on a stock ADALM-Pluto or any different SDR.

The checked restore script backs up the current QSPI before writing. Keep that backup if the board contains anything you may want later.
