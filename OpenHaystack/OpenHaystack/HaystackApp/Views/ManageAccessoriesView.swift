//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI
import os

struct ManageAccessoriesView: View {

    @EnvironmentObject var accessoryController: AccessoryController
    var accessories: [Accessory] {
        return self.accessoryController.accessories
    }

    // MARK: Bindings from main View
    @Binding var alertType: OpenHaystackMainView.AlertType?
    @Binding var focusedAccessory: Accessory?
    @Binding var accessoryToDeploy: Accessory?
    @Binding var showESP32DeploySheet: Bool
    @State var sheetShown: SheetType?

    @State var showMailPopup = false

    var body: some View {
        VStack {
            Text("Your accessories")
                .font(.title2)
                .padding(.top)

            if self.accessories.isEmpty {
                Spacer()
                Text("No accessories have been added yet. Go ahead and add one via the '+' icon.")
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                self.accessoryList
            }
        }
        .toolbar(content: {
            self.toolbarView
        })
        .sheet(item: self.$sheetShown) { sheetType in
            switch sheetType {
            case .esp32Install:
                ESP32InstallSheet(accessory: self.$accessoryToDeploy, alertType: self.$alertType)
            case .deployFirmware:
                self.selectTargetView
            }
        }
    }

    /// Accessory List view.
    var accessoryList: some View {
        List(self.accessories, id: \.self, selection: $focusedAccessory) { accessory in
            AccessoryListEntry(
                accessory: accessory,
                accessoryIcon: Binding(
                    get: { accessory.icon },
                    set: { accessory.icon = $0 }
                ),
                accessoryColor: Binding(
                    get: { accessory.color },
                    set: { accessory.color = $0 }
                ),
                accessoryName: Binding(
                    get: { accessory.name },
                    set: { accessory.name = $0 }
                ),
                alertType: self.$alertType,
                delete: self.delete(accessory:),
                deployAccessoryToMicrobit: self.deploy(accessory:),
                zoomOn: { self.focusedAccessory = $0 })
        }
        .listStyle(SidebarListStyle())

    }

    /// All toolbar buttons shown.
    var toolbarView: some View {
        Group {
            Spacer()

            Button(
                action: self.importAccessories,
                label: {
                    Label("Import accessories", systemImage: "square.and.arrow.down")
                }
            )
            .help("Import accessories from a file")

            Button(
                action: self.exportAccessories,
                label: {
                    Label("Export accessories", systemImage: "square.and.arrow.up")
                }
            )
            .help("Export all accessories to a file")

            Button(action: self.addAccessory) {
                Label("Add accessory", systemImage: "plus")
            }
            .help("Add a new accessory")
        }
    }

    var selectTargetView: some View {
        VStack {
            Text("Select target")
                .font(.title)
            Text("Please select to which device you want to deply")
                .padding(.bottom, 4)

            VStack {
                Button(
                    "Micro:bit",
                    action: {
                        self.sheetShown = nil
                        if let accessory = self.accessoryToDeploy {
                            self.deployAccessoryToMicrobit(accessory: accessory)
                        }
                    }
                )
                .buttonStyle(LargeButtonStyle())

                Button(
                    "Export Microbit firmware",
                    action: {
                        self.sheetShown = nil
                        if let accessory = self.accessoryToDeploy {
                            self.exportMicrobitFirmware(for: accessory)
                        }
                    }
                )
                .buttonStyle(LargeButtonStyle())

                Button(
                    "ESP32",
                    action: {
                        self.sheetShown = .esp32Install
                    }
                )
                .buttonStyle(LargeButtonStyle())

                Button(
                    "Cancel",
                    action: {
                        self.sheetShown = nil
                    }
                )
                .buttonStyle(LargeButtonStyle(destructive: true))
            }

        }
        .padding()
    }

    /// Delete an accessory from the list of accessories.
    func delete(accessory: Accessory) {
        do {
            try self.accessoryController.delete(accessory: accessory)
        } catch {
            self.alertType = .deletionFailed
        }
    }

    func deploy(accessory: Accessory) {
        self.accessoryToDeploy = accessory
        self.sheetShown = .deployFirmware
    }

    /// Add an accessory with the provided details.
    func addAccessory() {
        do {
            _ = try self.accessoryController.addAccessory()
        } catch {
            self.alertType = .keyError
        }
    }

    func exportAccessories() {
        do {
            _ = try self.accessoryController.export(accessories: self.accessories)
        } catch {
            self.alertType = .exportFailed
        }
    }

    func importAccessories() {
        do {
            try self.accessoryController.importAccessories()
        } catch {
            if let importError = error as? AccessoryController.ImportError,
                importError == .cancelled
            {
                //User cancelled the import. No error
                return
            }

            self.alertType = .importFailed
        }
    }

    /// Deploy the public key of the accessory to a BBC microbit.
    func deployAccessoryToMicrobit(accessory: Accessory) {
        do {
            try MicrobitController.deploy(accessory: accessory)
        } catch {
            os_log("Error occurred %@", String(describing: error))
            self.alertType = .deployFailed
            return
        }

        self.alertType = .deployedSuccessfully
        accessory.isDeployed = true
        self.accessoryToDeploy = nil
    }

    func exportMicrobitFirmware(for accessory: Accessory) {
        do {
            let firmware = try MicrobitController.patchFirmware(for: accessory)

            let savePanel = NSSavePanel()
            savePanel.allowedFileTypes = ["bin"]
            savePanel.canCreateDirectories = true
            savePanel.directoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            savePanel.message = "Export the micro:bit firmware"
            savePanel.nameFieldLabel = "Firmware name"
            savePanel.nameFieldStringValue = "openhaystack_firmware.bin"
            savePanel.prompt = "Export"
            savePanel.title = "Export firmware"

            let result = savePanel.runModal()

            if result == .OK,
                let url = savePanel.url
            {
                // Store the accessory file
                try firmware.write(to: url)
            }

        } catch {
            os_log("Error occurred %@", String(describing: error))
            self.alertType = .exportFailed
            return
        }
    }

    enum SheetType: Int, Identifiable {
        var id: Int {
            return self.rawValue
        }
        case esp32Install
        case deployFirmware
    }
}

struct ManageAccessoriesView_Previews: PreviewProvider {

    @State static var accessories = PreviewData.accessories
    @State static var alertType: OpenHaystackMainView.AlertType?
    @State static var focussed: Accessory?
    @State static var deploy: Accessory?
    @State static var showESPSheet: Bool = true

    static var previews: some View {
        ManageAccessoriesView(alertType: self.$alertType, focusedAccessory: self.$focussed, accessoryToDeploy: self.$deploy, showESP32DeploySheet: self.$showESPSheet)
    }
}
