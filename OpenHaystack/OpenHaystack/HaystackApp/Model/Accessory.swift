//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import CoreLocation
import CryptoKit
import Foundation
import Security
import SwiftUI

class Accessory: ObservableObject, Codable, Identifiable, Equatable {
    let name: String
    let id: Int
    let privateKey: Data
    let color: Color
    let icon: String

    @Published var lastLocation: CLLocation?
    @Published var locationTimestamp: Date?

    init(name: String, color: Color = Color.white, iconName: String = "briefcase.fill") throws {
        self.name = name
        guard let key = BoringSSL.generateNewPrivateKey() else {
            throw KeyError.keyGenerationFailed
        }
        self.id = key.hashValue
        self.privateKey = key
        self.color = color
        self.icon = iconName
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.id = try container.decode(Int.self, forKey: .id)
        self.privateKey = try container.decode(Data.self, forKey: .privateKey)
        self.icon = (try? container.decode(String.self, forKey: .icon)) ?? "briefcase.fill"

        if var colorComponents = try? container.decode([CGFloat].self, forKey: .colorComponents),
            let spaceName = try? container.decode(String.self, forKey: .colorSpaceName),
            let cgColor = CGColor(colorSpace: CGColorSpace(name: spaceName as CFString)!, components: &colorComponents) {
            self.color = Color(cgColor)
        } else {
            self.color = Color.white
        }

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.privateKey, forKey: .privateKey)
        try container.encode(self.icon, forKey: .icon)

        if let colorComponents = self.color.cgColor?.components,
            let colorSpace = self.color.cgColor?.colorSpace?.name {
            try container.encode(colorComponents, forKey: .colorComponents)
            try container.encode(colorSpace as String, forKey: .colorSpaceName)
        }

    }

    /// The public key in the format used for Offline finding. It is 28 bytes long and can be transferred to a microbit
    func getActualPublicKey() throws -> Data {
        guard let publicKey = BoringSSL.derivePublicKey(fromPrivateKey: self.privateKey) else {
            throw KeyError.keyDerivationFailed
        }
        return publicKey
    }

    func getAdvertisementKey() throws -> Data {
        guard var publicKey = BoringSSL.derivePublicKey(fromPrivateKey: self.privateKey) else {
            throw KeyError.keyDerivationFailed
        }
        // Drop the first byte to just have the 28 bytes version
        publicKey = publicKey.dropFirst()
        assert(publicKey.count == 28)
        guard publicKey.count == 28 else { throw KeyError.keyDerivationFailed }

        return publicKey
    }

    /// Offline finding uses an id for each key to identify a device / location report.
    /// The key is a SHA256 hash of the public key bytes formatted as Base64
    /// - Throws: An error if the key derivation or hashing fails
    /// - Returns: A base64 id of the current key
    func getKeyId() throws -> String {
        try self.hashedPublicKey().base64EncodedString()
    }

    private func hashedPublicKey() throws -> Data {
        let publicKey = try self.getAdvertisementKey()
        var sha = SHA256()
        sha.update(data: publicKey)
        let digest = sha.finalize()

        return Data(digest)
    }

    func toFindMyDevice() throws -> FindMyDevice {

        let findMyKey = FindMyKey(
            advertisedKey: try self.getAdvertisementKey(),
            hashedKey: try self.hashedPublicKey(),
            privateKey: self.privateKey,
            startTime: nil,
            duration: nil,
            pu: nil,
            yCoordinate: nil,
            fullKey: nil)

        return FindMyDevice(
            deviceId: String(self.id),
            keys: [findMyKey],
            catalinaBigSurKeyFiles: nil,
            reports: nil,
            decryptedReports: nil)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case id
        case privateKey
        case colorComponents
        case colorSpaceName
        case icon
    }

    static func == (lhs: Accessory, rhs: Accessory) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.privateKey == rhs.privateKey && lhs.icon == rhs.icon
    }
}

enum KeyError: Error {
    case keyGenerationFailed
    case keyDerivationFailed
}
