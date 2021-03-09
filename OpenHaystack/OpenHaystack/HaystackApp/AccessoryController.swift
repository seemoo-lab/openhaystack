//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import Combine
import Foundation
import SwiftUI
import Combine

class AccessoryController: ObservableObject {
    static let shared = AccessoryController()

    @Published var accessories: [Accessory]
    var cancellables = [AnyCancellable]()
    var saveCancellable: AnyCancellable?

    var accessoryObserver: AnyCancellable?

    init() {
        self.accessories = KeychainController.loadAccessoriesFromKeychain()
        initObserver()
    }

    func initObserver() {
        self.accessories.forEach({
            let c = $0.objectWillChange.sink(receiveValue: { self.objectWillChange.send() })

            // Important: You have to keep the returned value allocated,
            // otherwise the sink subscription gets cancelled
            self.cancellables.append(c)
        })
        self.saveCancellable = self.$accessories.sink { _ in
            // FIXME: accessories actually don't change
            try? self.save()
        }
    }

    init(accessories: [Accessory]) {
        self.accessories = accessories
        initObserver()
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
        try self.save()
    }

    func addAccessory(with name: String, color: Color, icon: String) throws -> Accessory {
        let accessory = try Accessory(name: name, color: color, iconName: icon)

        let accessories = self.accessories + [accessory]

        withAnimation {
            self.accessories = accessories
        }

        try self.save()

        return accessory
    }
}
