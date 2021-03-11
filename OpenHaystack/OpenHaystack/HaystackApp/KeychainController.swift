//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import OSLog
import Security

struct KeychainController {

    static func loadAccessoriesFromKeychain(test: Bool = false) -> [Accessory] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrLabel: "FindMyAccessories",
            kSecAttrService: "SEEMOO-FINDMY",
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
        ]

        if test {
            query[kSecAttrService] = "SEEMOO-Test"
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
            let resultData = result as? Data
        else {
            return []
        }

        // Convert from PropertyList to an array of accessories
        do {
            let accessories = try PropertyListDecoder().decode([Accessory].self, from: resultData)
            return accessories
        } catch {
            os_log("Could not decode accessories %@", String(describing: error))
        }

        return []
    }

    static func storeInKeychain(accessories: [Accessory], test: Bool = false) throws {
        // Store or update
        var attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrLabel: "FindMyAccessories",
            kSecAttrService: "SEEMOO-FINDMY",
            kSecValueData: try PropertyListEncoder().encode(accessories),
        ]

        if test {
            attributes[kSecAttrService] = "SEEMOO-Test"
        }

        // Try to store the item
        let storeStatus = SecItemAdd(attributes as CFDictionary, nil)

        if storeStatus == errSecDuplicateItem {
            var query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrLabel: "FindMyAccessories",
                kSecAttrService: "SEEMOO-FINDMY",
            ]

            if test {
                query[kSecAttrService] = "SEEMOO-Test"
            }

            // Update the existing item
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.updatingItemFailed
            }
        }
    }
}

enum KeychainError: Error {
    case updatingItemFailed
}
