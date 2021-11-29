//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

struct NRFController {

    static var nrfFirmwareDirectory: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("NRF")
    }

    /// Runs the script to flash the firmware onto an nRF Device.
    static func flashToNRF(accessory: Accessory, updateInterval: Int, completion: @escaping (ClosureResult) -> Void) throws {
        // Copy firmware to a temporary directory
        let temp = NSTemporaryDirectory() + "OpenHaystack"
        let urlTemp = URL(fileURLWithPath: temp)
        try? FileManager.default.removeItem(at: urlTemp)

        try? FileManager.default.createDirectory(atPath: temp, withIntermediateDirectories: false, attributes: nil)

        guard let nrfDirectory = nrfFirmwareDirectory else { return }

        try FileManager.default.copyFolder(from: nrfDirectory, to: urlTemp)
        let urlScript = urlTemp.appendingPathComponent("flash_nrf.sh")
        try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: 0o755], ofItemAtPath: urlScript.path)
        try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: 0o755], ofItemAtPath: urlTemp.appendingPathComponent("flash_nrf.py").path)

        // Get public key, newest relevant symmetric key and updateInterval for flashing
        let masterBeaconPublicKey = try accessory.getUncompressedPublicKey()
        let masterBeaconSymmetricKey = accessory.getNewestSymmetricKey()
        let arguments = [masterBeaconPublicKey.base64EncodedString(), masterBeaconSymmetricKey.base64EncodedString(), String(updateInterval)]

        // Create file for logging and get file handle
        let loggingFileUrl = urlTemp.appendingPathComponent("nrf_installer.log")
        try "".write(to: loggingFileUrl, atomically: true, encoding: .utf8)
        let loggingFileHandle = FileHandle.init(forWritingAtPath: loggingFileUrl.path)!

        // Run script
        let task = try NSUserUnixTask(url: urlScript)
        task.standardOutput = loggingFileHandle
        task.standardError = loggingFileHandle
        task.execute(withArguments: arguments) { e in
            DispatchQueue.main.async {
                if let error = e {
                    completion(.failure(loggingFileUrl, error))
                } else {
                    completion(.success(loggingFileUrl))
                }
            }
        }

        try loggingFileHandle.close()
    }
}

enum ClosureResult {
    case success(URL)
    case failure(URL, Error)
}

enum NRFFirmwareFlashError: Error {
    /// Missing files for flashing
    case notFound
    /// Flashing / writing failed
    case flashFailed
}
