//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import CryptoKit
import Foundation

/// Decode key files found in newer macOS versions.
class FindMyKeyDecoder {
    /// Key files can be in different format.
    ///
    /// The old <= 10.15.3 have been using normal plists. Newer once use a binary format which needs different parsing.
    enum KeyFileFormat {
        /// Catalina > 10.15.4 key file format | Big Sur 11.0 Beta 1 uses a similar key file format that can be parsed identically.
        /// macOS 10.15.7 uses a new key file format that has not been reversed yet.
        /// (The key files are protected by sandboxing and only usable from a SIP disabled)
        case catalina_10_15_4
    }

    var fileFormat: KeyFileFormat?

    func parse(keyFile: Data) throws -> [FindMyKey] {
        // Detect the format at first
        if fileFormat == nil {
            try self.checkFormat(for: keyFile)
        }
        guard let format = self.fileFormat else {
            throw ParsingError.unsupportedFormat
        }

        switch format {
        case .catalina_10_15_4:
            let keys = try self.parseBinaryKeyFiles(from: keyFile)
            return keys
        }
    }

    func checkFormat(for keyFile: Data) throws {
        // Key files need to start with KEY = 0x4B 45 59
        let magicBytes = keyFile.subdata(in: 0..<3)
        guard magicBytes == Data([0x4b, 0x45, 0x59]) else {
            throw ParsingError.wrongMagicBytes
        }

        // Detect zeros
        let potentialZeros = keyFile[15..<31]
        guard potentialZeros == Data(repeating: 0x00, count: 16) else {
            throw ParsingError.wrongFormat
        }
        // Should be big sur
        self.fileFormat = .catalina_10_15_4
    }

    fileprivate func parseBinaryKeyFiles(from keyFile: Data) throws -> [FindMyKey] {
        var keys = [FindMyKey]()
        // First key starts at 32
        var i = 32

        while i + 117 < keyFile.count {
            // We could not identify what those keys were
            _ = keyFile.subdata(in: i..<i + 32)
            i += 32
            if keyFile[i] == 0x00 {
                // Public key only.
                // No need to parse it. Just skip to the next key
                i += 86
                continue
            }

            guard keyFile[i] == 0x01 else {
                throw ParsingError.wrongFormat
            }
            // Step over 0x01
            i += 1
            // Read the key (starting with 0x04)
            let fullKey = keyFile.subdata(in: i..<i + 85)
            i += 85
            // Create the sub keys. No actual need, but we do that to put them into a similar format as used before 10.15.4
            let advertisedKey = fullKey.subdata(in: 1..<29)
            let yCoordinate = fullKey.subdata(in: 29..<57)

            var shaDigest = SHA256()
            shaDigest.update(data: advertisedKey)
            let hashedKey = Data(shaDigest.finalize())

            let fmKey = FindMyKey(
                advertisedKey: advertisedKey,
                hashedKey: hashedKey,
                privateKey: fullKey,
                startTime: nil,
                duration: nil,
                pu: nil,
                yCoordinate: yCoordinate,
                fullKey: fullKey)

            keys.append(fmKey)
        }

        return keys
    }

    enum ParsingError: Error {
        case wrongMagicBytes
        case wrongFormat
        case unsupportedFormat
    }
}
