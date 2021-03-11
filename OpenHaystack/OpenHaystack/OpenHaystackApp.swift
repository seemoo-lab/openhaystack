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
    @StateObject var findMyController: FindMyController

    init() {
        var accessoryController: AccessoryController
        if ProcessInfo().arguments.contains("-preview") {
            accessoryController = AccessoryControllerPreview(accessories: PreviewData.accessories)
        } else {
            accessoryController = AccessoryController()
        }
        self._accessoryController = StateObject(wrappedValue: accessoryController)
        self._findMyController = StateObject(wrappedValue: FindMyController(accessories: accessoryController))
    }

    var body: some Scene {
        WindowGroup {
            OpenHaystackMainView()
                .environmentObject(accessoryController)
                .environmentObject(findMyController)
        }
        .commands {
            SidebarCommands()
        }
    }

}
