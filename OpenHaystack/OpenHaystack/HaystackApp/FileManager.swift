//
//  FileManager.swift
//  OpenHaystack
//
//  Created by Alex - SEEMOO on 09.03.21.
//  Copyright © 2021 SEEMOO - TU Darmstadt. All rights reserved.
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
                // Copy file
                try FileManager.default.copyItem(at: fileURL, to: to.appendingPathComponent(file))
            }
        }
    }
}
