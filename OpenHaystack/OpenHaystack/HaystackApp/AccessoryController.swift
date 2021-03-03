//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import Foundation

class AccessoryController: ObservableObject {
    static let shared = AccessoryController()

    @Published var accessories: [Accessory]

    init() {
        self.accessories = KeychainController.loadAccessoriesFromKeychain()
    }

    init(accessories: [Accessory]) {
        self.accessories = accessories
    }

    func save() throws {
        try KeychainController.storeInKeychain(accessories: self.accessories)
    }

    func load() {
        self.accessories = KeychainController.loadAccessoriesFromKeychain()
    }

    func updateWithDecryptedReports(devices: [FindMyDevice]) {
        // Assign last locations
        for device in FindMyController.shared.devices {
            if let idx = self.accessories.firstIndex(where: {$0.id == Int(device.deviceId)}) {
                self.objectWillChange.send()
                let accessory = self.accessories[idx]

                let report = device.decryptedReports?
                    .sorted(by: {$0.timestamp ?? Date.distantPast > $1.timestamp  ?? Date.distantPast })
                    .first

                accessory.lastLocation = report?.location
                accessory.locationTimestamp = report?.timestamp

                self.accessories[idx] = accessory
            }
        }
    }
}
