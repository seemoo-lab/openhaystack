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

    func updateIntervalView() -> some View {
        let intervalFormatter = DateComponentsFormatter()
        intervalFormatter.unitsStyle = .abbreviated

        return Group {
            Text("Key derivation interval: \(intervalFormatter.string(from: accessory.updateInterval)!)")
        }.font(.footnote)
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
                if accessory.usesDerivation {
                    self.updateIntervalView()
                }
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
        .listRowBackground(Color.clear)
        .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
        .contextMenu {
            Button("Delete", action: { self.delete(accessory) })
            Button("Rename", action: { self.editingName = true })
            Menu("Key derivation options") {
                Button("Toggle key derivation", action: { accessory.usesDerivation = !accessory.usesDerivation })
                Button("Reset derivation state", action: { accessory.resetDerivationState() })
            }
            Divider()
            Button("Copy key ID (Base64)", action: { self.copyPublicKeyHash(of: accessory) })
            Menu("Copy advertisement key") {
                Button("Base64", action: { self.copyAdvertisementKeyB64(of: accessory) })
                Button("Byte array", action: { self.copyAdvertisementKey(escapedString: false) })
                Button("Escaped string", action: { self.copyAdvertisementKey(escapedString: true) })
            }
            Menu("Copy symmetric and uncompressed public key") {
                Button("Base64", action: { self.copySymmetricAndPublicKeyBase64(of: accessory) })
                Button("Escaped string", action: { self.copySymmetricAndPublicKey(of: accessory) })
            }
            Divider()
            Button("Mark as \(accessory.isDeployed ? "deployable" : "deployed")", action: { accessory.isDeployed.toggle() })

            Group {
                Button("Copy private Key B64", action: { copyPrivateKey(accessory: accessory) })

                Button("Export Locations", action: { exportLocations(accessory: accessory) })
            }

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

    func copyAdvertisementKeyB64(of accessory: Accessory) {
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

    func copyAdvertisementKey(escapedString: Bool) {
        do {
            let publicKey = try self.accessory.getAdvertisementKey()
            let keyByteArray = [UInt8](publicKey)

            if escapedString {
                let string = keyByteArray.map { "\\x\(String($0, radix: 16))" }.joined()
                let pasteboard = NSPasteboard.general
                pasteboard.prepareForNewContents(with: .currentHostOnly)
                pasteboard.setString(string, forType: .string)
            } else {
                let string = keyByteArray.map { "0x\(String($0, radix: 16))" }.joined(separator: ", ")
                let pasteboard = NSPasteboard.general
                pasteboard.prepareForNewContents(with: .currentHostOnly)
                pasteboard.setString(string, forType: .string)
            }
        } catch {
            os_log("Failed extracing public key %@", String(describing: error))
            assert(false)
        }
    }

    func copySymmetricAndPublicKey(of accessory: Accessory) {
        do {
            let symmetricKey = accessory.symmetricKey
            let publicKey = try accessory.getUncompressedPublicKey()
            let publicKeyString = [UInt8](publicKey).map { "\\x\(String($0, radix: 16))" }.joined()
            let symmetricKeyString = [UInt8](symmetricKey).map { "\\x\(String($0, radix: 16))" }.joined()

            let pasteboard = NSPasteboard.general
            pasteboard.prepareForNewContents(with: .currentHostOnly)
            pasteboard.setString("Symmetric key: \(symmetricKeyString)\n Uncompressed public key: \(publicKeyString) ", forType: .string)
        } catch {
            os_log("Failed extracing public key %@", String(describing: error))
            assert(false)
        }
    }

    func copySymmetricAndPublicKeyBase64(of accessory: Accessory) {
        do {
            let symmetricKey = accessory.symmetricKey
            let publicKey = try accessory.getUncompressedPublicKey()

            let pasteboard = NSPasteboard.general
            pasteboard.prepareForNewContents(with: .currentHostOnly)
            pasteboard.setString("Symmetric key: \(symmetricKey.base64EncodedString())\n Uncompressed public key: \(publicKey.base64EncodedString()) ", forType: .string)
        } catch {
            os_log("Failed extracing public key %@", String(describing: error))
            assert(false)
        }
    }

    func copyPrivateKey(accessory: Accessory) {
        let privateKey = accessory.privateKey
        let keyB64 = privateKey.base64EncodedString()

        let pasteboard = NSPasteboard.general
        pasteboard.prepareForNewContents(with: .currentHostOnly)
        pasteboard.setString(keyB64, forType: .string)
    }

    func exportLocations(accessory: Accessory) {
        guard let locations = accessory.locations,
            let locationData = try? JSONEncoder().encode(locations)
        else {
            return
        }

        let savePanel = SavePanel.shared
        savePanel.saveFile(file: locationData, fileExtension: "json")
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
