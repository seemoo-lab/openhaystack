//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import OSLog
import SwiftUI

struct AccessoryListEntry: View {
    var accessory: Accessory
    @Binding var alertType: OpenHaystackMainView.AlertType?
    var delete: (Accessory) -> Void
    var deployAccessoryToMicrobit: (Accessory) -> Void
    var zoomOn: (Accessory) -> Void
    let formatter = DateFormatter()

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
            Circle()
                .strokeBorder(accessory.color, lineWidth: 2.0)
                .background(
                    ZStack {
                        Circle().fill(Color("PinColor"))
                        Image(systemName: accessory.icon)
                            .padding(3)
                    }
                )
                .frame(width: 40, height: 40)

            Button(
                action: {
                    self.zoomOn(self.accessory)
                },
                label: {
                    VStack(alignment: .leading) {
                        Text(accessory.name)
                            .font(.headline)
                        self.timestampView()

                    }
                    .contentShape(Rectangle())
                }
            )
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(
                action: {
                    self.deployAccessoryToMicrobit(accessory)
                },
                label: {
                    Text("Deploy")
                }
            )
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
        .contextMenu {
            Button("Delete", action: { self.delete(accessory) })
            Divider()
            Button("Copy advertisment key (Base64)", action: { self.copyPublicKey(of: accessory) })
            Button("Copy key id (Base64)", action: { self.copyPublicKeyHash(of: accessory) })
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
}
