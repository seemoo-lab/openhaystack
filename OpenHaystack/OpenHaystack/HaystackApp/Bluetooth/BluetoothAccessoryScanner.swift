//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import CoreBluetooth
import Foundation

protocol BluetoothAccessoryDelegate {
    func received(_ advertisement: Advertisement)
}

public class BluetoothAccessoryScanner: NSObject, CBCentralManagerDelegate {

    var scanner: CBCentralManager!
    var delegate: BluetoothAccessoryDelegate?

    override init() {
        super.init()
        scanner = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        startScanning(central)
    }

    private func startScanning(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return
        }
        let scanOptions = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ]
        scanner.scanForPeripherals(withServices: nil, options: scanOptions)
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let adv = Advertisement(fromAdvertisementData: advertisementData) else {
            return
        }
        self.delegate?.received(adv)
    }
}
