//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

class AccessoryNearbyMonitor: BluetoothAccessoryDelegate {

    var accessoryController: AccessoryController
    var scanner: BluetoothAccessoryScanner

    init(accessoryController: AccessoryController) {
        self.accessoryController = accessoryController
        self.scanner = BluetoothAccessoryScanner()
        self.initScanner()
    }

    func initScanner() {
        self.scanner.delegate = self
    }

    func received(_ advertisement: Advertisement) {
        guard let accessory = getAccessoryForAdvertisement(advertisement) else {
            return
        }
        if !accessory.isNearby {
            // Only set on state change
            accessory.isNearby = true
        }
    }

    func getAccessoryForAdvertisement(_ advertisement: Advertisement) -> Accessory? {
        let accessory =
            try? self.accessoryController.accessories.first {
                let accessoryPublicKey = try $0.getAdvertisementKey().advanced(by: 6)
                return accessoryPublicKey == advertisement.publicKeyPayload
            } ?? nil
        return accessory
    }
}
