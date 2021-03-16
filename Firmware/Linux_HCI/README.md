# OpenHaystack HCI Script for Linux

This script enables Linux devices to send out Bluetooth Low Energy advertisements such that they can be found by [Apple's Find My network](https://developer.apple.com/find-my/).

## Disclaimer

Note that the script is just a proof-of-concept and currently only implements advertising a single static key. This means that **devices running this script are trackable** by other devices in proximity.

## Requirements

The script requires a Linux machine with a Bluetooth Low Energy radio chip, a Python environment, and `hcitool` installed. We tested it on a Raspberry Pi running the official Raspberry Pi OS.

## Usage

Our Python script uses HCI calls to configure Bluetooth advertising. You can copy the required `ADVERTISMENT_KEY` from the app by right-clicking on your accessory and selecting _Copy advertisement key (Base64)_. Then run the script:

```bash
sudo python3 HCI.py --key <ADVERTISMENT_KEY>
```
