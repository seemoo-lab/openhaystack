//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import Foundation
import SwiftUI

// swiftlint:disable force_try
struct PreviewData {
    static let accessories: [Accessory] = {
        return accessoryList()
    }()

    static func accessoryList() -> [Accessory] {

        let latitude: Double = 52.5219814
        let longitude: Double = 13.413306

        let backpack = try! Accessory(name: "Backpack", color: Color.green, iconName: "briefcase.fill")
        backpack.lastLocation = CLLocation(latitude: latitude + (Double(arc4random() % 1000))/100000, longitude: longitude + (Double(arc4random() % 1000))/100000)

        let bag = try! Accessory(name: "Bag", color: Color.blue, iconName: "latch.2.case.fill")
        bag.lastLocation = CLLocation(latitude: latitude + (Double(arc4random() % 1000))/100000, longitude: longitude + (Double(arc4random() % 1000))/100000)

        let car = try! Accessory(name: "Car", color: Color.red, iconName: "car.fill")
        car.lastLocation = CLLocation(latitude: latitude + (Double(arc4random() % 1000))/100000, longitude: longitude + (Double(arc4random() % 1000))/100000)

        let keys = try! Accessory(name: "Keys", color: Color.orange, iconName: "key.fill")
        keys.lastLocation = CLLocation(latitude: latitude + (Double(arc4random() % 1000))/100000, longitude: longitude + (Double(arc4random() % 1000))/100000)

        let items = try! Accessory(name: "Items", color: Color.gray, iconName: "mappin")
        items.lastLocation = CLLocation(latitude: latitude + (Double(arc4random() % 1000))/100000, longitude: longitude + (Double(arc4random() % 1000))/100000)

        return [backpack, bag, car, keys, items]
    }
}
