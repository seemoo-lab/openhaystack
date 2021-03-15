//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI

@main
struct OpenHaystackApp: App {
    @StateObject var accessoryController: AccessoryController
    var accessoryNearbyMonitor: AccessoryNearbyMonitor?

    init() {
        let accessoryController: AccessoryController
        if ProcessInfo().arguments.contains("-preview") {
            accessoryController = AccessoryControllerPreview(accessories: PreviewData.accessories, findMyController: FindMyController())
            self.accessoryNearbyMonitor = nil
        } else {
            accessoryController = AccessoryController()
            self.accessoryNearbyMonitor = AccessoryNearbyMonitor(accessoryController: accessoryController)
        }
        self._accessoryController = StateObject(wrappedValue: accessoryController)
    }

    var body: some Scene {
        WindowGroup {
            OpenHaystackMainView()
                .environmentObject(self.accessoryController)
        }
        .commands {
            SidebarCommands()
        }
    }
}
