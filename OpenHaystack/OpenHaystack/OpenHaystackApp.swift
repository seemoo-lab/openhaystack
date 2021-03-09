//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import SwiftUI

@main
struct OpenHaystackApp: App {

    var body: some Scene {
        WindowGroup {
            if ProcessInfo().arguments.contains("-preview") {
                OpenHaystackMainView(accessoryController: AccessoryController(accessories: PreviewData.accessories))
            } else {
                OpenHaystackMainView()
            }
        }
        .commands {
            SidebarCommands()
        }
    }

}
