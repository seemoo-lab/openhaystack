# OpenHaystack Firmware for ESP32

This project contains a PoC firmware for Espressif ESP32 chips (like ESP32-WROOM or ESP32-WROVER, but _not_ ESP32-S2).
After flashing our firmware, the device sends out Bluetooth Low Energy advertisements such that it can be found by [Apple's Find My network](https://developer.apple.com/find-my/).

## Disclaimer

Note that the firmware is just a proof-of-concept and currently only implements advertising a single static key. This means that **devices running this firmware are trackable** by other devices in proximity.

## Requirements

To change and rebuild the firmware, you need Espressif's IoT Development Framework (ESP-IDF).
Installation instructions for the latest version of the ESP-IDF can be found in [its documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/).
The firmware is tested on version 4.2.

For deploying the firmware, you need Python 3 on your path, either as `python3` (preferred) or as `python`, and the `venv` module needs to be available.

## Build

With the ESP-IDF on your `$PATH`, you can use `idf.py` to build the application from within this directory:

```bash
idf.py build
```

This will create the following files:

- `build/bootloader/bootloader.bin` -- The second stage bootloader
- `build/partition_table/partition-table.bin` -- The partition table
- `build/openhaystack.bin` -- The application itself

These files are required for the next step: Deploy the firmware.

## Deploy the Firmware

Use the `flash_esp32.sh` script to deploy the firmware and a public key to an ESP32 device connected to your local machine:

```bash
./flash_esp32.sh -p /dev/yourSerialPort "public-key-in-base64"
```

> **Note:** You might need to reset your device after running the script before it starts sending advertisements.

For more options, see `./flash-esp32.h --help`.
