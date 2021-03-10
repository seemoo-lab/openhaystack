//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import Combine
import Foundation
import SwiftUI

class AccessoryController: ObservableObject {
    @Published var accessories: [Accessory]
    var selfObserver: AnyCancellable?
    var listElementsObserver = [AnyCancellable]()

    init(accessories: [Accessory]) {
        self.accessories = accessories
        initAccessoryObserver()
        initObserver()
    }

    convenience init() {
        self.init(accessories: KeychainController.loadAccessoriesFromKeychain())
    }

    func initAccessoryObserver() {
        self.selfObserver = self.objectWillChange.sink { _ in
            // objectWillChange is called before the values are actually changed,
            // so we dispatch the call to save()
            DispatchQueue.main.async {
                self.initObserver()
                try? self.save()
            }
        }
    }

    func initObserver() {
        self.listElementsObserver.forEach({
            $0.cancel()
        })
        self.accessories.forEach({
            let c = $0.objectWillChange.sink(receiveValue: { self.objectWillChange.send() })
            // Important: You have to keep the returned value allocated,
            // otherwise the sink subscription gets cancelled
            self.listElementsObserver.append(c)
        })
    }

    func save() throws {
        try KeychainController.storeInKeychain(accessories: self.accessories)
    }

    func updateWithDecryptedReports(devices: [FindMyDevice]) {
        // Assign last locations
        for device in devices {
            if let idx = self.accessories.firstIndex(where: { $0.id == Int(device.deviceId) }) {
                self.objectWillChange.send()
                let accessory = self.accessories[idx]

                let report = device.decryptedReports?
                    .sorted(by: { $0.timestamp ?? Date.distantPast > $1.timestamp ?? Date.distantPast })
                    .first

                accessory.lastLocation = report?.location
                accessory.locationTimestamp = report?.timestamp
            }
        }
    }

    func delete(accessory: Accessory) throws {
        var accessories = self.accessories
        guard let idx = accessories.firstIndex(of: accessory) else { return }

        accessories.remove(at: idx)

        withAnimation {
            self.accessories = accessories
        }
    }

    func addAccessory(with name: String, color: Color, icon: String) throws -> Accessory {
        let accessory = try Accessory(name: name, color: color, iconName: icon)
        withAnimation {
            self.accessories.append(accessory)
        }
        return accessory
    }
}

class AccessoryControllerPreview: AccessoryController {
    override func save() {
        // don't allow saving dummy data to keychain
    }
}
