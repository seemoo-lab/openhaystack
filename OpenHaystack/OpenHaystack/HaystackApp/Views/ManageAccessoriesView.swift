//
//  ManageAccessoriesView.swift
//  OpenHaystack
//
//  Created by Alex - SEEMOO on 09.03.21.
//  Copyright © 2021 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI

struct ManageAccessoriesView: View {

    @ObservedObject var accessoryController = AccessoryController.shared
    var accessories: [Accessory] {
        return self.accessoryController.accessories
    }

    // MARK: Bindings from main View
    @Binding var alertType: OpenHaystackMainView.AlertType?
    @Binding var focusedAccessory: Accessory?
    @Binding var accessoryToDeploy: Accessory?
    @Binding var showESP32DeploySheet: Bool

    // MARK: View State
    @State var keyName: String = ""
    @State var accessoryColor: Color = Color.white
    @State var selectedIcon: String = "briefcase.fill"

    var body: some View {
        VStack {
            Text("Create a new tracking accessory")
                .font(.title2)
                .padding(.top)

            Text("A BBC Microbit can be used to track anything you care about. Connect it over USB, name the accessory (e.g. Backpack) generate the key and deploy it")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundColor(.gray)

            HStack {
                TextField("Name", text: self.$keyName)
                ColorPicker("", selection: self.$accessoryColor)
                    .frame(maxWidth: 50, maxHeight: 20)
                IconSelectionView(selectedImageName: self.$selectedIcon)
            }

            Button(
                action: self.addAccessory,
                label: {
                    Text("Generate key and deploy")
                }
            )
            .disabled(self.keyName.isEmpty)
            .padding(.bottom)

            Divider()

            Text("Your accessories")
                .font(.title2)
                .padding(.top)

            if self.accessories.isEmpty {
                Spacer()
                Text("No accessories have been added yet. Go ahead and add one above")
                    .multilineTextAlignment(.center)
            } else {
                self.accessoryList
            }

            Spacer()

        }
        .sheet(isPresented: self.$showESP32DeploySheet, content: {
            ESP32InstallSheet(accessory: self.$accessoryToDeploy, alertType: self.$alertType)
        })
    }

    /// Accessory List view.
    var accessoryList: some View {
        List(self.accessories) { accessory in
            AccessoryListEntry(
                accessory: accessory,
                alertType: self.$alertType,
                delete: self.delete(accessory:),
                deployAccessoryToMicrobit: self.deploy(accessory:),
                zoomOn: { self.focusedAccessory = $0 })
        }
        .background(Color.clear)
        .cornerRadius(15.0)
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
        self.alertType = .selectDepoyTarget
    }

    /// Add an accessory with the provided details.
    func addAccessory() {
        let keyName = self.keyName
        self.keyName = ""

        do {
            let accessory = try self.accessoryController.addAccessory(with: keyName, color: self.accessoryColor, icon: self.selectedIcon)
            self.deploy(accessory: accessory)

        } catch {
            self.alertType = .keyError
        }
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
