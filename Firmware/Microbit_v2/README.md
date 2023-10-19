# OpenHaystack Firmware for nRF52833

This project contains a PoC firmware for Nordic nRF52833 chips such as used by the [BBC micro:bit](https://microbit.org).
After flashing our firmware, the device sends out Bluetooth Low Energy advertisements such that it can be found by [Apple's Find My network](https://developer.apple.com/find-my/).

This firmware builds partially on top of the [microbit-v2-samples](https://github.com/lancaster-university/microbit-v2-samples).

## Disclaimer

Note that the firmware is just a proof-of-concept and currently only implements advertising a single static key. This means that **devices running this firmware are trackable** by other devices in proximity.

## Requirements

This PoC supports builds using docker. You need a working [docker setup](https://docs.docker.com/engine/install/) or [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) to build the firmware on your own.

On macOS, you can install the toolchain via [Homebrew](https://brew.sh):

```bash
brew install --cask gcc-arm-embedded
```

With docker, you can build the microbit-tools image via:

```bash
docker build -t microbit-tools .
```

## Build

You need to specify a public key in the firmware image. You can either directly do so in the [source](offline-finding/main.c) (`public_key`) or patch the string `OFFLINEFINDINGPUBLICKEYHERE!` in the final firmware image.

To build the firmware, it should suffice to run:

```bash
docker run -v $(pwd):/app --rm microbit-tools
```

from the main directory, which also takes care of downloading all dependencies. The deploy-ready image is then available at `./MICROBIT.hex`.

## Deploy

To deploy the image on a connected nRF device, you can run:

```bash
cp MICROBIT.hex /Volumes/MICROBIT/
```

*We tested this procedure with the BBC micro:bit V2 only, but other nRF52833-based devices should work as well.*

## Author
- This firmware: **Sam Aleksov** ([@samaleksov](https://github.com/samaleksov), [email](mailto:samuelalexdev@gmail.com), [web](https://refractionx.com))

- **Milan Stute** ([@schmittner](https://github.com/schmittner), [email](mailto:mstute@seemoo.tu-darmstadt.de), [web](https://seemoo.de/mstute))

## License

This firmware is licensed under the [**MIT License**](LICENSE).
