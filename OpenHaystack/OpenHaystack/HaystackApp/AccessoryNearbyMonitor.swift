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

    var cleanup: Timer?

    init(accessoryController: AccessoryController) {
        self.accessoryController = accessoryController
        self.scanner = BluetoothAccessoryScanner()
        self.initScanner()
        self.initTimer()
    }

    func initScanner() {
        self.scanner.delegate = self
    }

    func initTimer() {
        self.cleanup = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.removeNearbyAccessories()
        }
    }

    func received(_ advertisement: Advertisement) {
        guard let accessory = getAccessoryForAdvertisement(advertisement) else {
            return
        }
        updateNearbyAccessory(accessory)
    }

    func updateNearbyAccessory(_ accessory: Accessory) {
        if !accessory.isNearby {
            // Only set on state change
            accessory.isNearby = true
        }
        accessory.lastAdvertisement = Date()
    }

    func removeNearbyAccessories(now: Date = Date(), timeout: TimeInterval = 10.0) {
        let nearbyAccessories = self.accessoryController.accessories.filter({ $0.isNearby })
        for accessory in nearbyAccessories {
            guard let lastAdvertisement = accessory.lastAdvertisement else {
                continue
            }
            if lastAdvertisement + timeout < now {
                accessory.isNearby = false
            }
        }
    }

    func getAccessoryForAdvertisement(_ advertisement: Advertisement) -> Accessory? {
        let accessory =
            self.accessoryController.accessories.first {
                isAdvertisement(advertisement, from: $0)
            } ?? nil
        return accessory
    }

    func isAdvertisement(_ advertisement: Advertisement, from: Accessory) -> Bool {
        do {
            let accessoryPublicKey = try from.getAdvertisementKey().advanced(by: 6)
            return accessoryPublicKey == advertisement.publicKeyPayload
        } catch {
            return false
        }
    }
}
