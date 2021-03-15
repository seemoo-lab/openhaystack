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

struct Advertisement {

    let publicKeyPayload: Data

    init?(fromAdvertisementData: [String: Any]) {
        guard let manufacturerData = fromAdvertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return nil
        }
        self.init(fromManufacturerData: manufacturerData)
    }

    init?(fromManufacturerData: Data) {
        guard let publicKey = Advertisement.extractPublicKeyFromPayload(fromManufacturerData) else {
            return nil
        }
        self.publicKeyPayload = publicKey
    }

    static let publicKeyPayloadLength = 22

    static func extractPublicKeyFromPayload(_ payload: Data) -> Data? {
        guard payload.count == 29 else {
            return nil
        }
        // Apple company ID
        guard payload.subdata(in: 0..<2) == Data([0x4c, 0x00]) else {
            return nil
        }
        // Offline finding sub type
        guard payload.subdata(in: 2..<3) == Data([0x12]) else {
            return nil
        }
        // Offline finding sub type length
        guard payload.subdata(in: 3..<4) == Data([0x19]) else {
            return nil
        }
        let publicKey = payload.subdata(in: 5..<5 + publicKeyPayloadLength)
        guard publicKey.count == publicKeyPayloadLength else {
            return nil
        }
        return publicKey
    }
}
