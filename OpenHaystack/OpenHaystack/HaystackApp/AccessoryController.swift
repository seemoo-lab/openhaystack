//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Combine
import Foundation
import OSLog
import SwiftUI

class AccessoryController: ObservableObject {
    @Published var accessories: [Accessory]
    var selfObserver: AnyCancellable?
    var listElementsObserver = [AnyCancellable]()
    let findMyController: FindMyController

    weak var savePanel: NSSavePanel?

    init(accessories: [Accessory], findMyController: FindMyController) {
        self.accessories = accessories
        self.findMyController = findMyController
        initAccessoryObserver()
        initObserver()
    }

    convenience init() {
        self.init(accessories: KeychainController.loadAccessoriesFromKeychain(), findMyController: FindMyController())
    }

    func initAccessoryObserver() {
        self.selfObserver = self.objectWillChange.sink { [weak self] _ in
            // objectWillChange is called before the values are actually changed,
            // so we dispatch the call to save()
            DispatchQueue.main.async { [weak self] in
                self?.initObserver()
                try? self?.save()
            }
        }
    }

    func initObserver() {
        self.listElementsObserver.forEach({
            $0.cancel()
        })
        self.accessories.forEach({
            let c = $0.objectWillChange.sink(receiveValue: { [weak self] in self?.objectWillChange.send() })
            // Important: You have to keep the returned value allocated,
            // otherwise the sink subscription gets cancelled
            self.listElementsObserver.append(c)
        })
    }

    func save() throws {
        try KeychainController.storeInKeychain(accessories: self.accessories)
    }

    func updateWithDecryptedReports(devices: [FindMyDevice]) {
        // Assign last locations
        for device in devices {
            if let idx = self.accessories.firstIndex(where: { $0.id == Int(device.deviceId) }) {
                self.objectWillChange.send()
                let accessory = self.accessories[idx]

                let report = device.decryptedReports?
                    .sorted(by: { $0.timestamp ?? Date.distantPast > $1.timestamp ?? Date.distantPast })
                    .first

                accessory.lastLocation = report?.location
                accessory.locationTimestamp = report?.timestamp
                accessory.locations = device.decryptedReports
            }
        }
    }

    func delete(accessory: Accessory) throws {
        var accessories = self.accessories
        guard let idx = accessories.firstIndex(of: accessory) else { return }

        accessories.remove(at: idx)

        withAnimation {
            self.accessories = accessories
        }
    }

    func addAccessory() throws -> Accessory {
        let accessory = try Accessory()
        withAnimation {
            self.accessories.append(accessory)
        }
        return accessory
    }

    /// Export the accessories property list so it can be imported at another location.
    func export(accessories: [Accessory]) throws -> URL {

        let savePanel = NSSavePanel()
        //        savePanel.allowedFileTypes = ["plist", "json"]
        if #available(macOS 12.0, *) {
            savePanel.allowedContentTypes = [.propertyList]
        } else {
            savePanel.allowedFileTypes = ["plist"]
        }

        savePanel.canCreateDirectories = true
        savePanel.directoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        savePanel.message = "This export contains all private keys! Keep the file save to protect your location data"
        savePanel.nameFieldLabel = "Filename"
        savePanel.nameFieldStringValue = "openhaystack_accessories"
        savePanel.prompt = "Export"
        savePanel.title = "Export accessories & keys"
        savePanel.isExtensionHidden = false

        let accessoryView = NSView()
        let popUpButton = NSPopUpButton(title: "File type", target: self, action: #selector(exportFileTypeChanged(button:)))
        popUpButton.addItems(withTitles: ["Property List", "JSON"])
        popUpButton.selectItem(at: 0)
        popUpButton.stringValue = "File type"
        popUpButton.translatesAutoresizingMaskIntoConstraints = false
        accessoryView.addSubview(popUpButton)

        let popUpButtonLabel = NSTextField(labelWithString: "File type")
        popUpButtonLabel.translatesAutoresizingMaskIntoConstraints = false
        accessoryView.addSubview(popUpButtonLabel)
        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        //        popUpButtonLabel.leadingAnchor.constraint(greaterThanOrEqualTo: accessoryView.leadingAnchor, constant: 20.0).isActive = true
        popUpButtonLabel.trailingAnchor.constraint(equalTo: popUpButton.leadingAnchor, constant: -8.0).isActive = true
        popUpButtonLabel.trailingAnchor.constraint(lessThanOrEqualTo: accessoryView.centerXAnchor, constant: 0).isActive = true
        popUpButtonLabel.centerYAnchor.constraint(equalTo: popUpButton.centerYAnchor, constant: 0).isActive = true
        //        popUpButton.trailingAnchor.constraint(lessThanOrEqualTo: accessoryView.trailingAnchor, constant: -20.0).isActive = true
        popUpButton.leadingAnchor.constraint(lessThanOrEqualTo: accessoryView.centerXAnchor, constant: 0).isActive = true
        popUpButton.topAnchor.constraint(equalTo: accessoryView.topAnchor, constant: 8.0).isActive = true
        popUpButton.bottomAnchor.constraint(equalTo: accessoryView.bottomAnchor, constant: -8.0).isActive = true
        popUpButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 20.0).isActive = true
        popUpButton.widthAnchor.constraint(lessThanOrEqualToConstant: 200.0).isActive = true

        savePanel.accessoryView = accessoryView
        self.savePanel = savePanel

        let result = savePanel.runModal()

        if result == .OK,
            var url = savePanel.url
        {
            let selectedItemIndex = popUpButton.indexOfSelectedItem

            // Store the accessory file
            if selectedItemIndex == 0 {
                if url.pathExtension != "plist" {
                    url = url.appendingPathExtension("plist")
                }
                let propertyList = try PropertyListEncoder().encode(accessories)
                try propertyList.write(to: url)
            } else if selectedItemIndex == 1 {
                if url.pathExtension != "json" {
                    url = url.appendingPathExtension("json")
                }
                let jsonObject = try JSONEncoder().encode(accessories)
                try jsonObject.write(to: url)
            }

            return url
        }
        throw ImportError.cancelled
    }

    @objc func exportFileTypeChanged(button: NSPopUpButton) {
        if button.indexOfSelectedItem == 0 {
            if #available(macOS 12.0, *) {
                self.savePanel?.allowedContentTypes = [.propertyList]
            } else {
                self.savePanel?.allowedFileTypes = ["plist"]
            }
        } else {
            if #available(macOS 12.0, *) {
                self.savePanel?.allowedContentTypes = [.json]
            } else {
                self.savePanel?.allowedFileTypes = ["json"]
            }
        }
    }

    /// Let the user select a file to import the accessories exported by another OpenHaystack instance.
    func importAccessories() throws {
        let openPanel = NSOpenPanel()
        if #available(macOS 12.0, *) {
            openPanel.allowedContentTypes = [.json, .propertyList]
        } else {
            openPanel.allowedFileTypes = ["json", "plist"]
        }

        openPanel.canCreateDirectories = true
        openPanel.directoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        openPanel.message = "Import an accessories file that includes the private keys"
        openPanel.prompt = "Import"
        openPanel.title = "Import accessories & keys"

        let result = openPanel.runModal()
        if result == .OK,
            let url = openPanel.url
        {
            let accessoryData = try Data(contentsOf: url)
            var importedAccessories: [Accessory]
            if url.pathExtension == "plist" {
                importedAccessories = try PropertyListDecoder().decode([Accessory].self, from: accessoryData)
            } else {
                importedAccessories = try JSONDecoder().decode([Accessory].self, from: accessoryData)
            }

            var updatedAccessories = self.accessories
            // Filter out accessories with the same id (no duplicates)
            importedAccessories = importedAccessories.filter({ acc in !self.accessories.contains(where: { acc.id == $0.id }) })
            updatedAccessories.append(contentsOf: importedAccessories)
            updatedAccessories.sort(by: { $0.name < $1.name })

            self.accessories = updatedAccessories

            //Update reports automatically. Do not report errors from here
            self.downloadLocationReports { result in }
        }
    }

    enum ImportError: Error {
        case cancelled
    }

    //MARK: Location reports

    /// Download the location reports from.
    ///
    /// - Parameter completion: called when the reports have been succesfully downloaded or the request has failed
    func downloadLocationReports(completion: @escaping (Result<Void, OpenHaystackMainView.AlertType>) -> Void) {
        AnisetteDataManager.shared.requestAnisetteData { [weak self] result in
            guard let self = self else {
                completion(.failure(.noReportsFound))
                return
            }
            switch result {
            case .failure(_):
                completion(.failure(.activatePlugin))
            case .success(let accountData):

                guard let token = accountData.searchPartyToken,
                    token.isEmpty == false
                else {
                    completion(.failure(.searchPartyToken))
                    return
                }

                self.findMyController.fetchReports(for: self.accessories, with: token) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        os_log(.error, "Downloading reports failed %@", error.localizedDescription)
                        completion(.failure(.downloadingReportsFailed))
                    case .success(let devices):
                        let reports = devices.compactMap({ $0.reports }).flatMap({ $0 })
                        if reports.isEmpty {
                            completion(.failure(.noReportsFound))
                        } else {
                            self?.updateWithDecryptedReports(devices: devices)
                            completion(.success(()))
                        }
                    }
                }

            }
        }
    }

}

class AccessoryControllerPreview: AccessoryController {
    override func save() {
        // don't allow saving dummy data to keychain
    }
}
