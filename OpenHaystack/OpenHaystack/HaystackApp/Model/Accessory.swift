//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import CoreLocation
import CryptoKit
import Foundation
import Security
import SwiftUI

class Accessory: ObservableObject, Codable, Identifiable, Equatable, Hashable {

    static let icons = [
        "creditcard.fill", "briefcase.fill", "case.fill", "latch.2.case.fill",
        "key.fill", "mappin", "globe", "crown.fill",
        "gift.fill", "car.fill", "bicycle", "figure.walk",
        "heart.fill", "hare.fill", "tortoise.fill", "eye.fill",
    ]
    static func randomIcon() -> String {
        return icons.randomElement() ?? ""
    }
    static func randomColor() -> Color {
        return Color(hue: Double.random(in: 0..<1), saturation: 0.75, brightness: 1)
    }

    @Published var name: String
    let id: Int
    let privateKey: Data
    @Published var locations: [FindMyLocationReport]?
    @Published var color: Color
    @Published var icon: String
    @Published var lastLocation: CLLocation?
    @Published var locationTimestamp: Date?
    @Published var isDeployed: Bool {
        didSet(wasDeployed) {
            // Reset active status if deployed
            if !wasDeployed && isDeployed {
                self.isActive = false
            }
        }
    }
    /// Whether the accessory is correctly advertising.
    @Published var isActive: Bool = false
    /// Whether this accessory is currently nearby.
    @Published var isNearby: Bool = false {
        didSet {
            if isNearby {
                self.isActive = true
            }
        }
    }
    var lastAdvertisement: Date?

    init(name: String = "New accessory", color: Color = randomColor(), iconName: String = randomIcon()) throws {
        self.name = name
        guard let key = BoringSSL.generateNewPrivateKey() else {
            throw KeyError.keyGenerationFailed
        }
        self.id = key.hashValue
        self.privateKey = key
        self.color = color
        self.icon = iconName
        self.isDeployed = false
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.id = try container.decode(Int.self, forKey: .id)
        self.privateKey = try container.decode(Data.self, forKey: .privateKey)
        self.icon = (try? container.decode(String.self, forKey: .icon)) ?? ""
        self.isDeployed = (try? container.decode(Bool.self, forKey: .isDeployed)) ?? false
        self.isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? false

        if var colorComponents = try? container.decode([CGFloat].self, forKey: .colorComponents),
            let spaceName = try? container.decode(String.self, forKey: .colorSpaceName),
            let cgColor = CGColor(colorSpace: CGColorSpace(name: spaceName as CFString)!, components: &colorComponents)
        {
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
        try container.encode(self.isDeployed, forKey: .isDeployed)
        try container.encode(self.isActive, forKey: .isActive)

        if let colorComponents = self.color.cgColor?.components,
            let colorSpace = self.color.cgColor?.colorSpace?.name
        {
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
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
        case isDeployed
        case isActive
    }

    static func == (lhs: Accessory, rhs: Accessory) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.privateKey == rhs.privateKey && lhs.icon == rhs.icon && lhs.isDeployed == rhs.isDeployed
    }
}

enum KeyError: Error {
    case keyGenerationFailed
    case keyDerivationFailed
}
