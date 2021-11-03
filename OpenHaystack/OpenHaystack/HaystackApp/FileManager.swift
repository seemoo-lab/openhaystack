//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//
import Foundation

extension FileManager {

    /// Copy a folder recursively.
    ///
    /// - Parameters:
    ///   - from: Folder source
    ///   - to: Folder destination
    /// - Throws: An error if copying or acessing files fails
    func copyFolder(from: URL, to: URL) throws {
        // Create the folder
        try? FileManager.default.createDirectory(at: to, withIntermediateDirectories: false, attributes: nil)

        let files = try FileManager.default.contentsOfDirectory(atPath: from.path)
        for file in files {
            // Check if file is a folder
            var isDir: ObjCBool = .init(booleanLiteral: false)
            let fileURL = from.appendingPathComponent(file)
            FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir)

            if isDir.boolValue == true {
                try self.copyFolder(from: fileURL, to: to.appendingPathComponent(file))
            } else {
                do {
                    // Copy file
                    try self.createFile(atPath: to.appendingPathComponent(file).path, contents: Data(contentsOf: fileURL), attributes: nil)
                } catch {
                    if fileURL.lastPathComponent != "CodeResources" {
                        throw error
                    }
                }
            }
        }
    }
}
