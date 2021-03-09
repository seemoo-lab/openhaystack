//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import Foundation

struct MicrobitController {

    /// Find all microbits connected to this Mac.
    ///
    /// - Throws: If a volume is inaccessible
    /// - Returns: an array of urls
    static func findMicrobits() throws -> [URL] {
        let fm = FileManager.default
        let volumes = try fm.contentsOfDirectory(atPath: "/Volumes")

        let microbits: [URL] = volumes.filter({ $0.lowercased().contains("microbit") }).map({ URL(fileURLWithPath: "/Volumes").appendingPathComponent($0) })

        return microbits
    }

    /// Deploy the firmware to a USB connected microbit at the given URL.
    ///
    /// - Parameters:
    ///   - microbitURL: URL to the microbit
    ///   - firmwareFile: Firmware file as binary data
    /// - Throws: An error if the write fails
    static func deployToMicrobit(_ microbitURL: URL, firmwareFile: Data) throws {
        let firmwareURL = microbitURL.appendingPathComponent("firware.bin")
        try firmwareFile.write(to: firmwareURL, options: .atomicWrite)
    }

    /// Patch the given firmware.
    ///
    /// This will replace the pattern data (the place for the key) with the actual key
    /// - Parameters:
    ///   - firmware: The firmware data that should be patched
    ///   - pattern: The pattern that should be replaced
    ///   - key: The key that should be added
    /// - returns: The patched firmware file
    static func patchFirmware(_ firmware: Data, pattern: Data, with key: Data) throws -> Data {
        guard pattern.count == key.count else {
            throw PatchingError.inequalLength
        }

        var patchedFirmware = Data(firmware)
        var patchingSuccessful = false
        // Find the position of the pattern
        for bytePosition in firmware.startIndex...firmware.endIndex {
            // Use a sliding window to look for the pattern

            // Check if the firmware is long enough
            guard bytePosition.advanced(by: pattern.count) <= firmware.endIndex else { break }

            let range = bytePosition..<bytePosition.advanced(by: pattern.count)
            let potentialPattern = firmware[range]
            assert(potentialPattern.count == pattern.count)
            if Array(potentialPattern) == Array(pattern) {
                // Found pattern. Replace in binary
                patchedFirmware.replaceSubrange(range, with: key)
                patchingSuccessful = true
            }
        }

        guard patchingSuccessful else {
            throw PatchingError.patternNotFound
        }

        return patchedFirmware
    }

    static func deploy(accessory: Accessory) throws {
        let microbits = try MicrobitController.findMicrobits()
        guard let microBitURL = microbits.first,
            let firmwareURL = Bundle.main.url(forResource: "firmware", withExtension: "bin")
        else {
            throw FirmwareFlashError.notFound
        }

        let firmware = try Data(contentsOf: firmwareURL)
        let pattern = "OFFLINEFINDINGPUBLICKEYHERE!".data(using: .ascii)!
        let publicKey = try accessory.getAdvertisementKey()
        let patchedFirmware = try MicrobitController.patchFirmware(firmware, pattern: pattern, with: publicKey)

        try MicrobitController.deployToMicrobit(microBitURL, firmwareFile: patchedFirmware)
    }

}

enum PatchingError: Error {
    case inequalLength
    case patternNotFound
}
