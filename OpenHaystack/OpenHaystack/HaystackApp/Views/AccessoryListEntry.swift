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

    var body: some View {
        VStack {
            HStack {
                Button(
                    action: {
                        self.zoomOn(self.accessory)
                    },
                    label: {
                        HStack {
                            Text(accessory.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                )
                .buttonStyle(PlainButtonStyle())

                HStack(alignment: .center) {

                    Button(
                        action: { self.zoomOn(self.accessory) },
                        label: {
                            Circle()
                                .strokeBorder(accessory.color, lineWidth: 2.0)
                                .background(
                                    ZStack {
                                        Circle().fill(Color("PinColor"))
                                        Image(systemName: accessory.icon)
                                            .padding(3)
                                    }
                                )

                                .frame(width: 30, height: 30)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())

                    Button(
                        action: {
                            self.deployAccessoryToMicrobit(accessory)
                        },
                        label: {
                            Text("Deploy")
                        })

                }
                .padding(.trailing)
            }

            Divider()
        }
        .contentShape(Rectangle())
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

// struct AccessoryListEntry_Previews: PreviewProvider {
//    static var previews: some View {
//        AccessoryListEntry()
//    }
// }
