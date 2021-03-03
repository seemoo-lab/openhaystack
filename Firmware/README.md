# OpenHaystack Firmware for nRF51822

This project contains a PoC firmware for Nordic nRF51822 chips such as used by the [BBC micro:bit](https://microbit.org).
After flashing our firmware, the device sends out Bluetooth Low Energy advertisements such that it can be found by [Apple's Find My network](https://developer.apple.com/find-my/).

## Disclaimer

Note that the firmware is just a proof-of-concept and currently only implements advertising a single static key. This means that **devices running this firmware are trackable** by other devices in proximity.

## Requirements

You need to [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) to build the firmware.
On macOS, you can install it via [Homebrew](https://brew.sh):

```bash
brew install --cask gcc-arm-embedded
```

## Build

You need to specify a public key in the firmware image. You can either directly do so in the [source](offline-finding/main.c) (`public_key`) or patch the string `OFFLINEFINDINGPUBLICKEYHERE!` in the final firmware image.

To build the firmware, it should suffice to run:

```bash
make
```

from the main directory, which also takes care of downloading all dependencies. The deploy-ready image is then available at `offline-finding/build/offline-finding.bin`.

## Deploy

To deploy the image on a connected nRF device, you can run:

```bash
make install DEPLOY_PATH=/Volumes/MICROBIT
```

*We tested this procedure with the BBC micro:bit V1 only, but other nRF51822-based devices should work as well.*

## Author

- **Milan Stute** ([@schmittner](https://github.com/schmittner), [email](mailto:mstute@seemoo.tu-darmstadt.de), [web](https://seemoo.de/mstute))

## License

This firmware is licensed under the [**MIT License**](LICENSE).
