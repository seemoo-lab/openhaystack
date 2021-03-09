//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import AppKit
import Foundation
import OSLog

let mailBundleName = "OpenHaystackMail"

/// Manages plugin installation.
struct MailPluginManager {

    let pluginsFolderURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mail/Bundles")

    let pluginURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mail/Bundles").appendingPathComponent(mailBundleName + ".mailbundle")

    var isMailPluginInstalled: Bool {
        return FileManager.default.fileExists(atPath: pluginURL.path)
    }

    /// Shows a NSSavePanel to install the mail plugin at the required place.
    func askForPermission() -> Bool {

        let panel = NSSavePanel()
        panel.title = "Install Mail Plugin"
        panel.prompt = "Install"
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.message = "OpenHaystack has no right to access the directory to install the plug-in automatically. By clicking install you grant the persmission."

        if FileManager.default.fileExists(atPath: self.pluginsFolderURL.path) {
            panel.directoryURL = self.pluginsFolderURL
            panel.nameFieldLabel = "OpenHaystackMail Plugin"
            panel.nameFieldStringValue = mailBundleName + ".mailbundle"
        } else {
            panel.directoryURL = self.pluginsFolderURL.deletingLastPathComponent()
            panel.nameFieldLabel = "OpenHaystackMail Plugin"
            panel.nameFieldStringValue = "Bundles"
        }

        panel.center()

        let result = panel.runModal()

        return result == .OK && (panel.nameFieldStringValue == "Bundles" || panel.nameFieldStringValue == mailBundleName + ".mailbundle")
    }

    /// Install the mail plug-in to the correct location
    /// - Throws: An error if copying the fails fail. Due to permission or other errors
    func installMailPlugin() throws {
        guard self.askForPermission() else {
            throw PluginError.permissionNotGranted
        }

        let localPluginURL = Bundle.main.url(forResource: mailBundleName, withExtension: "mailbundle")!

        do {
            try FileManager.default.createDirectory(at: pluginsFolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error.localizedDescription)
        }
        try FileManager.default.copyFolder(from: localPluginURL, to: pluginURL)

        self.openAppleMail()
    }

    fileprivate func openAppleMail() {
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Mail.app"), configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)

    }

    func uninstallMailPlugin() throws {
        try FileManager.default.removeItem(at: pluginURL)
    }

    /// Copy plugin to downloads folder.
    ///
    /// - Throws: An error if the copy fails, because of missing permissions
    func pluginDownload() throws {
        guard let localPluginURL = Bundle.main.url(forResource: mailBundleName, withExtension: "mailbundle"),
            let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        else {
            throw PluginError.downloadFailed
        }

        let downloadsPluginURL = downloadsFolder.appendingPathComponent(mailBundleName + ".mailbundle")

        try FileManager.default.copyFolder(from: localPluginURL, to: downloadsPluginURL)
    }

}

enum PluginError: Error {
    case installationFailed
    case downloadFailed
    case permissionNotGranted
}
