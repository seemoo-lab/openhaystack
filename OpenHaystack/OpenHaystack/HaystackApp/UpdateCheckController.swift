//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import AppKit
import Foundation

/// Can  check if a new OpenHaystack version is needed and download it.
public struct UpdateCheckController {

    public static func checkForNewVersion() {
        // Load the GitHub Releases page
        let releasesURL = URL(string: "https://github.com/seemoo-lab/openhaystack/releases")!
        URLSession.shared.dataTask(with: releasesURL) { optionalData, response, error in
            guard let data = optionalData,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let htmlString = String(data: data, encoding: .utf8)
            else {
                return
            }

            guard let availableVersion = getVersion(from: htmlString) else {
                return
            }

            //Get installed version
            let version = Bundle.main.infoDictionary?["CFBundleVersionShortString"] as? String ?? "0"

            let comparisonResult = compareVersions(availableVersion: availableVersion, installedVersion: version)

            DispatchQueue.main.async {
                if comparisonResult == .older, askToDownloadUpdate() == .alertSecondButtonReturn {
                    //The currently installed version is older. Install an update
                    self.downloadUpdate(
                        version: availableVersion,
                        finished: { success in
                            if success {
                                let result = successDownloadAlert()
                                if result == .alertSecondButtonReturn {
                                    //Open the download folder
                                    let downloadURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
                                    NSWorkspace.shared.open(downloadURL)
                                }
                            } else {
                                if downloadFailedAlert() == .alertSecondButtonReturn {
                                    NSWorkspace.shared.open(URL(string: "https://github.com/seemoo-lab/openhaystack/releases")!)
                                }
                            }
                        })
                }
            }

        }.resume()
    }

    internal static func getVersion(from htmlString: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "Release (v[0-9]+(.[0-9]+)?(.[0-9]+)?)") else {
            return nil
        }

        let htmlNSString = htmlString as NSString

        let htmlRange = NSRange(location: 0, length: htmlNSString.length)

        if let checkResult = regex.firstMatch(in: htmlNSString as String, options: [], range: htmlRange),
            checkResult.numberOfRanges >= 2
        {

            //Get the latest release version range
            // A result should have multiple ranges for each capture group. 1 is the capture group for the version number
            let releaseVersionRange = checkResult.range(at: 1)
            let releaseVersion = htmlNSString.substring(with: releaseVersionRange)

            let releaseVersionNumber = releaseVersion.replacingOccurrences(of: "v", with: "")

            return releaseVersionNumber
        }

        return nil
    }

    /// Compares two version strings and returns if the installed version is older, newer or the same
    /// - Parameters:
    ///   - availableVersion: The latest available version
    ///   - installedVersion: The currently installed version
    /// - Returns: .older when a newer version is available. .newer when the installed version is newer .same, if both versions are equal
    internal static func compareVersions(availableVersion: String, installedVersion: String) -> VersionCompare {
        let availableVersionSplit = availableVersion.split(separator: ".")
        let installedVersionSplit = installedVersion.split(separator: ".")

        for (idx, availableVersionPart) in availableVersionSplit.enumerated() {

            if idx < installedVersionSplit.count {
                guard let avpi = Int(availableVersionPart),
                    let ivpi = Int(installedVersionSplit[idx])
                else { return .older }

                if avpi > ivpi {
                    return .older
                } else if ivpi > avpi {
                    return .newer
                }

            } else {
                //The installed version is x.x
                // The new version is x.x.y so it must be older
                return .older
            }
        }

        if installedVersionSplit.count > availableVersionSplit.count {
            //The installed version has a higher sub-version. So it must be newer
            return .newer
        }

        // All numbers were equal
        return .same
    }

    enum VersionCompare {
        case same, newer, older
    }

    static func downloadUpdate(version: String, finished: @escaping (Bool) -> Void) {

        //Download the current version into a file in Downloads
        let downloadURL = URL(string: "https://github.com/seemoo-lab/openhaystack/releases/download/v\(version)/OpenHaystack.zip")!

        let task = URLSession.shared.downloadTask(with: downloadURL) { optionalFileURL, response, error in

            guard let downloadLocation = optionalFileURL else {
                finished(false)
                return
            }

            //Move the file to the downloads folder
            let downloadURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            let openHaystackURL = downloadURL.appendingPathComponent("OpenHaystack.zip")
            do {
                let fm = FileManager.default
                if fm.fileExists(atPath: openHaystackURL.path) {
                    _ = try fm.replaceItemAt(openHaystackURL, withItemAt: downloadLocation)
                } else {
                    try fm.moveItem(at: downloadLocation, to: openHaystackURL)
                }

                DispatchQueue.main.async { finished(true) }
            } catch let error {
                print(error.localizedDescription)
                DispatchQueue.main.async { finished(false) }

            }
        }

        task.resume()
    }

    private static func askToDownloadUpdate() -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("New version available", comment: "Alert title")
        alert.informativeText = NSLocalizedString("A new version of OpenHaystack is available. Do you want to download it now?", comment: "Alert text")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Download")

        return alert.runModal()
    }

    private static func successDownloadAlert() -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Successfully downloaded update", comment: "Alert title")
        alert.informativeText = NSLocalizedString("The new version has been downloaded successfully and it was placed in your Downloads folder.", comment: "Alert text")
        alert.addButton(withTitle: "Okay")
        alert.addButton(withTitle: "Open folder")

        return alert.runModal()
    }

    private static func downloadFailedAlert() -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Download failed", comment: "Alert title")
        alert.informativeText = NSLocalizedString("To update to the newest version, please open the releases page on GitHub", comment: "Alert text")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Open")

        return alert.runModal()
    }

}

extension String {
    func substring(from range: NSRange) -> String {
        let substring = self[self.index(startIndex, offsetBy: range.lowerBound)..<self.index(startIndex, offsetBy: range.upperBound)]

        return String(substring)
    }
}
