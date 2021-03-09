//
//  ESP32Controller.swift
//  OpenHaystack
//
//  Created by Alex - SEEMOO on 09.03.21.
//  Copyright © 2021 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation

struct ESP32Controller {
    static var portURL: URL? {
        self.findPort().first
    }

    static var espFirmwareDirectory: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("ESP32")
    }

    /// Tries to find the port / path at which the ESP32 module is attached
    static func findPort() -> [URL] {
        // List all ports
        let ports = try? FileManager.default.contentsOfDirectory(atPath: "/dev").filter({$0.contains("cu.usb")})

        let portURLs = ports?.map({URL(fileURLWithPath: "/dev/\($0)")})

        return portURLs ?? []
    }

    /// Runs the script to flash the firmware on an ESP32
    static func flashToESP32(accessory: Accessory, completion: @escaping (Result<Void, Error>) -> Void) throws {

        // Copy firmware to a temporary directory
        let temp = NSTemporaryDirectory() + "OpenHaystack"
        let urlTemp = URL(fileURLWithPath: temp)
        try? FileManager.default.removeItem(at: urlTemp)

        try? FileManager.default.createDirectory(atPath: temp, withIntermediateDirectories: false, attributes: nil)

        guard let espDirectory = espFirmwareDirectory else {return}

        try FileManager.default.copyFolder(from: espDirectory, to: urlTemp)
        let scriptPath = urlTemp.appendingPathComponent("flash_esp32.sh")

        guard let port = portURL
            else {throw FirmwareFlashError.notFound}

        let key = accessory.privateKey.base64EncodedString()
        let arguments = ["-p", "\(port.path)", key]

        let task = try NSUserUnixTask(url: scriptPath)
        task.execute(withArguments: arguments) { e in
            DispatchQueue.main.async {
                if let error = e {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }

                // Delete the temporary folder
                try? FileManager.default.removeItem(at: urlTemp)
            }
        }

    }
}

enum FirmwareFlashError: Error {
    /// Missing files for flashing
    case notFound
    /// Flashing / writing failed 
    case flashFailed
}
