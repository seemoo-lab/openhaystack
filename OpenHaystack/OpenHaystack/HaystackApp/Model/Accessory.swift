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
    let symmetricKey: Data
    @Published var usesDerivation: Bool
    @Published var oldestRelevantSymmetricKey: Data
    @Published var lastDerivationTimestamp: Date
    @Published var updateInterval: TimeInterval
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
                self.usesDerivation = false
            } else if wasDeployed && !isDeployed {
                self.usesDerivation = false
                self.updateInterval = TimeInterval(60 * 60 * 24)
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
        let symKey = SymmetricKey(size: .bits256)
        self.symmetricKey = symKey.withUnsafeBytes {
            return Data(Array($0))
        }
        self.usesDerivation = false
        self.oldestRelevantSymmetricKey = self.symmetricKey
        self.lastDerivationTimestamp = Date()
        self.updateInterval = TimeInterval(60 * 60)
        self.color = color
        self.icon = iconName
        self.isDeployed = false
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.id = try container.decode(Int.self, forKey: .id)
        self.privateKey = try container.decode(Data.self, forKey: .privateKey)
        let symmetricKey = (try? container.decode(Data.self, forKey: .symmetricKey)) ?? SymmetricKey(size: .bits256).withUnsafeBytes { return Data($0) }
        self.symmetricKey = symmetricKey
        self.usesDerivation = (try? container.decode(Bool.self, forKey: .usesDerivation)) ?? false
        self.oldestRelevantSymmetricKey = (try? container.decode(Data.self, forKey: .oldestRelevantSymmetricKey)) ?? symmetricKey
        self.lastDerivationTimestamp = (try? container.decode(Date.self, forKey: .lastDerivationTimestamp)) ?? Date()
        self.updateInterval = (try? container.decode(TimeInterval.self, forKey: .updateInterval)) ?? TimeInterval(60 * 60 * 24)
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
        try container.encode(self.symmetricKey, forKey: .symmetricKey)
        try container.encode(self.usesDerivation, forKey: .usesDerivation)
        try container.encode(self.oldestRelevantSymmetricKey, forKey: .oldestRelevantSymmetricKey)
        try container.encode(self.lastDerivationTimestamp, forKey: .lastDerivationTimestamp)
        try container.encode(self.updateInterval, forKey: .updateInterval)
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

    /// Get Uncompressed public key
    /// This is needed for libraries such as mbedtls that do not support loading compressed points
    func getUncompressedPublicKey() throws -> Data {
        guard let publicKey = BoringSSL.deriveUncompressedPublicKey(fromPrivateKey: self.privateKey) else {
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

    func getNewestSymmetricKey() -> Data {
        var derivationTimestamp = self.lastDerivationTimestamp
        var symmetricKey = self.oldestRelevantSymmetricKey
        while derivationTimestamp < Date() {
            derivationTimestamp.addTimeInterval(self.updateInterval)
            symmetricKey = Accessory.kdf(inputData: self.symmetricKey, sharedInfo: "update".data(using: .ascii)!, bytesToReturn: 32)
        }
        return symmetricKey
    }

    func toFindMyDevice() throws -> FindMyDevice {

        var findMyKey = [FindMyKey]()

        /// Always append first FindMyKey to support devices without derivation
        findMyKey.append(
            FindMyKey(
                advertisedKey: try self.getAdvertisementKey(),
                hashedKey: try self.hashedPublicKey(),
                privateKey: self.privateKey,
                startTime: nil,
                duration: nil,
                pu: nil,
                yCoordinate: nil,
                fullKey: nil)
        )
        if self.usesDerivation {
            /// Derive FindMyKeys until we have symmetric key from one week before now
            while self.lastDerivationTimestamp < Date() - TimeInterval(7 * 24 * 60 * 60) {
                self.lastDerivationTimestamp.addTimeInterval(self.updateInterval)
                self.oldestRelevantSymmetricKey = Accessory.kdf(inputData: self.oldestRelevantSymmetricKey, sharedInfo: "update".data(using: .ascii)!, bytesToReturn: 32)
            }

            /// we need to generate Keys from seven days in the past until now and 10 extra keys in case of desynchronization
            let untilDate = Date() + TimeInterval(self.updateInterval * 11)
            var derivationTimestamp = self.lastDerivationTimestamp
            var derivedSymmetricKey = self.oldestRelevantSymmetricKey

            print("--- Derived keys for \(self.name) ---")
            print("Masterbacon symmetric key \(self.symmetricKey.hexEncodedString())")
            do {
                let uncompressedMasterBeaconKey = try self.getUncompressedPublicKey()
                print("Masterbeacon public key (uncompressed) \(uncompressedMasterBeaconKey.hexEncodedString())")
            } catch {
                print("Failed to get master beacon public key (only needed for printing)")
            }

            while derivationTimestamp < untilDate {
                /// Step 1: derive SKN_i
                derivedSymmetricKey = Accessory.kdf(inputData: derivedSymmetricKey, sharedInfo: "update".data(using: .ascii)!, bytesToReturn: 32)
                /// Step 2: derive u_i and v_i
                let derivedAntiTrackingKeys = Accessory.kdf(inputData: derivedSymmetricKey, sharedInfo: "diversify".data(using: .ascii)!, bytesToReturn: 72)
                /// Step 3 & 4: compute private and public key
                guard let derivedPrivateKey = BoringSSL.calculatePrivateKey(fromSharedData: derivedAntiTrackingKeys, masterBeaconPrivateKey: self.privateKey) else {
                    throw KeyError.keyDerivationFailed
                }
                guard let derivedPublicKey = BoringSSL.derivePublicKey(fromPrivateKey: derivedPrivateKey) else {
                    throw KeyError.keyDerivationFailed
                }

                /// Drop first byte to get advertisment key
                let derivedAdvertisementKey = derivedPublicKey.dropFirst()
                guard derivedAdvertisementKey.count == 28 else { throw KeyError.keyDerivationFailed }

                /// Get hash of advertisment key
                var sha = SHA256()
                sha.update(data: derivedAdvertisementKey)
                let derivedAdvertisementKeyHash = Data(sha.finalize())

                print("-> Derived keys for \(derivationTimestamp):")
                //print("Dervided anti tracking keys \(derivedAntiTrackingKeys.hexEncodedString())")
                //print("SymmetricKey \(derivedSymmetricKey.hexEncodedString())")
                print("Derived public key \(derivedPublicKey.hexEncodedString())")

                findMyKey.append(
                    FindMyKey(
                        advertisedKey: derivedAdvertisementKey,
                        hashedKey: derivedAdvertisementKeyHash,
                        privateKey: derivedPrivateKey,
                        startTime: nil,
                        duration: nil,
                        pu: nil,
                        yCoordinate: nil,
                        fullKey: nil)
                )

                /// Add time interval to derivation timestamp
                derivationTimestamp.addTimeInterval(self.updateInterval)
            }
        }

        return FindMyDevice(
            deviceId: String(self.id),
            keys: findMyKey,
            catalinaBigSurKeyFiles: nil,
            reports: nil,
            decryptedReports: nil)
    }

    static func kdf(inputData: Data, sharedInfo: Data, bytesToReturn: Int) -> Data {
        var derivedKey = Data()
        var counter: Int32 = 1

        /// derive from input and shared info until we have enough data
        while derivedKey.count < bytesToReturn {
            var shaDigest = SHA256()
            shaDigest.update(data: inputData)
            let counterData = Data(Data(bytes: &counter, count: MemoryLayout.size(ofValue: counter)).reversed())
            shaDigest.update(data: counterData)
            shaDigest.update(data: sharedInfo)
            derivedKey.append(Data(shaDigest.finalize()))
            counter += 1
        }

        /// drop bytes which are not needed and return
        derivedKey = derivedKey.dropLast(derivedKey.count - bytesToReturn)
        return derivedKey
    }

    func resetDerivationState() {
        /// reset keys and derivation time in case an accessory is reflashed with old keys
        self.oldestRelevantSymmetricKey = self.symmetricKey
        self.lastDerivationTimestamp = Date()
    }

    enum CodingKeys: String, CodingKey {
        case name
        case id
        case privateKey
        case usesDerivation
        case symmetricKey
        case oldestRelevantSymmetricKey
        case lastDerivationTimestamp
        case updateInterval
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
