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
        self.findPort()
    }

    static var installScripPath: URL? {
        Bundle.main.url(forResource: "ESP32", withExtension: nil)?.appendingPathComponent("flash_esp32.sh")
    }

    /// Tries to find the port / path at which the ESP32 module is attached
    static func findPort() -> URL? {
        return nil
    }

    /// Runs the script to flash the firmware on an ESP32
    static func flashToESP32(accessory: Accessory, completion: @escaping (Result<Void, Error>) -> Void) throws {
        guard let scriptPath = self.installScripPath,
              let port = portURL
        else {throw FirmwareFlashError.notFound}
        let key = accessory.privateKey.base64EncodedString()
        let arguments = ["-p \(port.path)", key]

        let task = try NSUserUnixTask(url: scriptPath)
        task.execute(withArguments: arguments) { e in
            DispatchQueue.main.async {
                if let error = e {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
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
