//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import OSLog
import SwiftUI

struct AccessoryListEntry: View {
    var accessory: Accessory
    @Binding var accessoryIcon: String
    @Binding var accessoryColor: Color
    @Binding var accessoryName: String
    @Binding var alertType: OpenHaystackMainView.AlertType?
    var delete: (Accessory) -> Void
    var deployAccessoryToMicrobit: (Accessory) -> Void
    var zoomOn: (Accessory) -> Void
    let formatter = DateFormatter()

    @State var editingName: Bool = false

    func timestampView() -> some View {
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return Group {
            if let timestamp = accessory.locationTimestamp {
                Text(formatter.string(from: timestamp))
            } else {
                Text("No location found")
            }
        }
        .font(.footnote)
    }

    var body: some View {

        HStack {
            IconSelectionView(selectedImageName: $accessoryIcon, selectedColor: $accessoryColor)

            VStack(alignment: .leading) {
                if self.editingName {
                    TextField("Enter accessory name", text: $accessoryName, onCommit: { self.editingName = false })
                        .font(.headline)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(accessory.name)
                        .font(.headline)
                }
                self.timestampView()
            }

            Spacer()
            if !accessory.isDeployed {
                Button(
                    action: { self.deployAccessoryToMicrobit(accessory) },
                    label: { Text("Deploy") }
                )
            }
            Circle()
                .fill(accessory.isNearby ? Color.green : accessory.isActive ? Color.orange : Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
        .contextMenu {
            Button("Delete", action: { self.delete(accessory) })
            Divider()
            Button("Rename", action: { self.editingName = true })
            Divider()
            Button("Copy advertisment key (Base64)", action: { self.copyPublicKey(of: accessory) })
            Button("Copy key ID (Base64)", action: { self.copyPublicKeyHash(of: accessory) })
            Divider()
            Button("Mark as \(accessory.isDeployed ? "deployable" : "deployed")", action: { accessory.isDeployed.toggle() })
        }
    }

    func copyPublicKey(of accessory: Accessory) {
        do {
            let publicKey = try accessory.getAdvertisementKey()
            let pasteboard = NSPasteboard.general
            pasteboard.prepareForNewContents(with: .currentHostOnly)
            pasteboard.setString(publicKey.base64EncodedString(), forType: .string)
        } catch {
            os_log("Failed extracing public key %@", String(describing: error))
            assert(false)
        }
    }

    func copyPublicKeyHash(of accessory: Accessory) {
        do {
            let keyID = try accessory.getKeyId()
            let pasteboard = NSPasteboard.general
            pasteboard.prepareForNewContents(with: .currentHostOnly)
            pasteboard.setString(keyID, forType: .string)
        } catch {
            os_log("Failed extracing public key %@", String(describing: error))
            assert(false)
        }
    }

    struct AccessoryListEntry_Previews: PreviewProvider {
        @StateObject static var accessory = PreviewData.accessories.first!
        @State static var alertType: OpenHaystackMainView.AlertType?

        static var previews: some View {
            Group {
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
                    delete: { _ in () },
                    deployAccessoryToMicrobit: { _ in () },
                    zoomOn: { _ in () })
            }
            .frame(width: 300)
        }
    }
}
