//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SwiftUI

// swiftlint:disable force_try
struct PreviewData {
    static let accessories: [Accessory] = {
        return accessoryList()
    }()

    static let latitude: Double = 49.878046
    static let longitude: Double = 8.656993

    static func randomLocation() -> CLLocation {
        return CLLocation(
            latitude: latitude + Double.random(in: 0..<0.005) * (Bool.random() ? -1 : 1),
            longitude: longitude + Double.random(in: 0..<0.005) * (Bool.random() ? -1 : 1)
        )
    }

    static func randomTimestamp() -> Date {
        return Date.init().addingTimeInterval(TimeInterval(-Double.random(in: 0..<24 * 60 * 60)))
    }

    static func previewAccessory(name: String, color: Color, icon: String) -> Accessory {
        let accessory = try! Accessory(name: name, color: color, iconName: icon)
        accessory.lastLocation = randomLocation()
        accessory.locationTimestamp = randomTimestamp()
        accessory.isDeployed = true
        accessory.isActive = true
        accessory.isNearby = Bool.random()
        return accessory
    }

    static func accessoryList() -> [Accessory] {
        return [
            previewAccessory(name: "Backpack", color: Color.green, icon: "briefcase.fill"),
            previewAccessory(name: "Bag", color: Color.blue, icon: "latch.2.case.fill"),
            previewAccessory(name: "Car", color: Color.red, icon: "car.fill"),
            previewAccessory(name: "Keys", color: Color.orange, icon: "key.fill"),
            previewAccessory(name: "Items", color: Color.gray, icon: "mappin"),
        ]
    }
}
