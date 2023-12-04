#!/usr/bin/env python3

import base64
import subprocess
import time
import struct
import argparse
import sys

class dongle:
    def __init__(self, key, interval_ms=2000, broadcast_name = "", hci="hci0", wait=1):
        self.key = key
        self.interval_ms = interval_ms
        self.broadcast_name = broadcast_name
        self.hci = hci
        self.wait = wait


    @staticmethod
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

    @staticmethod
    def bytes_to_strarray(bytes_, with_prefix=False):
        if with_prefix:
            return [hex(b) for b in bytes_]
        else:
            return [format(b, "x") for b in bytes_]


    def run_hci_cmd(self, cmd):
        cmd_ = ["hcitool", "-i", self.hci, "cmd"]
        cmd_ += cmd
        print(cmd_)
        subprocess.run(cmd_)
        if self.wait > 0:
            time.sleep(self.wait)


    def set_hci_device_name(self):
        cmd_ = ["hciconfig", self.hci, "name", self.broadcast_name]
        print(cmd_)
        subprocess.run(cmd_)

        if self.wait > 0:
            time.sleep(self.wait)
    
    def get_device_address(self) -> list:
        import re
        re_exp = "([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2})"
        cmd_ = ["hciconfig", self.hci]
        result = subprocess.run(cmd_,capture_output=True)
        result = re.search(re_exp, result.stdout.decode("utf-8")).group(0)
        result = result.split(":")
        result.reverse()
        for x in result:
            result[result.index(x)] = hex(int(x,16))
        return result
        
    def start_advertising(self):
        key = self.key
        addr = bytearray(key[:6])
        addr[0] |= 0b11000000

        adv = self.advertisement_template()
        adv[7:29] = key[6:28]
        adv[29] = key[0] >> 6

        print(f"key     ({len(key):2}) {key.hex()}")
        print(f"address ({len(addr):2}) {addr.hex()}")
        print(f"payload ({len(adv):2}) {adv.hex()}")

        # Set BLE address
        target_address = self.bytes_to_strarray(addr, with_prefix=True)[::-1]
        self.run_hci_cmd(["0x3f", "0x001"] + target_address)
        subprocess.run(["hciconfig", self.hci, "reset"])

        time.sleep(1)
        
        device_address = self.get_device_address()
        print ("target_address:", target_address)
        print ("device address:", device_address)
        if self.get_device_address() != target_address:
            print ("\n\nError: Failed to set device address. \nThis device might not support on modification of mac address. ")
            print("Your message might not be delivered.\n\n")
        else :
            print ("Success: Device address set")

        if self.broadcast_name != "":
            self.set_hci_device_name()
            subprocess.run(["hciconfig", self.hci, "reset"])
            print ("New Device Name:", self.broadcast_name)
            time.sleep(1)

        
        # Set BLE advertisement payload
        self.run_hci_cmd(["0x08", "0x0008"] + [format(len(adv), "x")] + self.bytes_to_strarray(adv))

        # Set BLE advertising mode
        interval_enc = struct.pack("<h", self.interval_ms)
        hci_set_adv_params = ["0x08", "0x0006"]
        # 7.8.5 LE Set Advertising Parameters Command
        # Command Parameters:
        # 0-1: Advertising_Interval_Min,
        # 2-3: Advertising_Interval_Max,
        # 4: Advertising_Type,
        # 5: Own_Address_Type,
        # 6: Direct_Address_Type,
        # 7-12: Direct_Address,
        # 13: Advertising_Channel_Map,
        # 14: Advertising_Filter_Policy
        hci_set_adv_params += self.bytes_to_strarray(interval_enc) # min interval, 2 Bytes
        hci_set_adv_params += self.bytes_to_strarray(interval_enc) # max interval, 2 Bytes
        hci_set_adv_params += ["00", "00", "00", "00", "00", "00", "00", "00", "00"]
        hci_set_adv_params += ["07", "00"] 
        self.run_hci_cmd(hci_set_adv_params)

        # Start BLE advertising
        # 7.8.9 LE Set Advertising Enable Command
        # Command Parameters:
        # 0: Advertising_Enable,
        # 1: Filter_Duplicates
        self.run_hci_cmd(["0x08", "0x000a"] + ["01"])
    
if __name__ == "__main__":
    import os,sys

    # Check Root 
    if not os.geteuid() == 0:
        sys.exit('Script must be run as root')

    parser = argparse.ArgumentParser()
    parser.add_argument("--key", "-k", help="Public key, also known as Advertisement key (base64)", default = "", type=str)
    parser.add_argument("--interval", "-i", help="Advertisement interval (ms) Default is 200", default=200, choices=range(20,1000*30+1), metavar="[20-30000]", type=int)
    parser.add_argument("--hci", "-d", help="HCI device. Default is hci0", default="hci0", type=str)
    parser.add_argument("--name", "-n", help="HCI device broadcast name. Default is unchanged.", default="", type=str)

    args = parser.parse_args()
    
    if len(sys.argv) == 1 or args.key == "":
        print (parser.print_help())
    else:
        key = base64.b64decode(args.key.encode())
        dongle(key, hci=args.hci, broadcast_name=args.name, interval_ms = args.interval).start_advertising()

