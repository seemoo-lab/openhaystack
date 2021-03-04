#!/usr/bin/env python3

import base64
import subprocess
import time
import struct
import argparse
import sys


def advertisement_template():
    adv = ""
    adv += "1e"  # length (30)
    adv += "ff"  # manufacturer specific data
    adv += "4c00"  # company ID (Apple)
    adv += "1219"  # offline finding type and length
    adv += "00"  # state
    for _ in range(22):  # key[6:28]
        adv += "00"
    adv += "00"  # first two bits of key[0]
    adv += "00"  # hint
    return bytearray.fromhex(adv)


def bytes_to_strarray(bytes_, with_prefix=False):
    if with_prefix:
        return [hex(b) for b in bytes_]
    else:
        return [format(b, "x") for b in bytes_]


def run_hci_cmd(cmd, hci="hci0", wait=1):
    cmd_ = ["hcitool", "-i", hci, "cmd"]
    cmd_ += cmd
    print(cmd_)
    subprocess.run(cmd_)
    if wait > 0:
        time.sleep(wait)


def start_advertising(key, interval_ms=2000):
    addr = bytearray(key[:6])
    addr[0] |= 0b11000000

    adv = advertisement_template()
    adv[7:29] = key[6:28]
    adv[29] = key[0] >> 6

    print(f"key     ({len(key):2}) {key.hex()}")
    print(f"address ({len(addr):2}) {addr.hex()}")
    print(f"payload ({len(adv):2}) {adv.hex()}")

    # Set BLE address
    run_hci_cmd(["0x3f", "0x001"] + bytes_to_strarray(addr, with_prefix=True)[::-1])
    subprocess.run(["systemctl", "restart", "bluetooth"])
    time.sleep(1)

    # Set BLE advertisement payload
    run_hci_cmd(["0x08", "0x0008"] + [format(len(adv), "x")] + bytes_to_strarray(adv))

    # Set BLE advertising mode
    interval_enc = struct.pack("<h", interval_ms)
    hci_set_adv_params = ["0x08", "0x0006"]
    hci_set_adv_params += bytes_to_strarray(interval_enc)
    hci_set_adv_params += bytes_to_strarray(interval_enc)
    hci_set_adv_params += ["03", "00", "00", "00", "00", "00", "00", "00", "00"]
    hci_set_adv_params += ["07", "00"]
    run_hci_cmd(hci_set_adv_params)

    # Start BLE advertising
    run_hci_cmd(["0x08", "0x000a"] + ["01"], wait=0)


def main(args):
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", "-k", help="Advertisement key (base64)")
    args = parser.parse_args(args)

    key = base64.b64decode(args.key.encode())
    start_advertising(key)


if __name__ == "__main__":
    main(sys.argv[1:])
