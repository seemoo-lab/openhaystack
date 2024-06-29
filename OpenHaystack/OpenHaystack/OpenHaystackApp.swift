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
    var frameWidth: CGFloat? = nil
    var frameHeight: CGFloat? = nil

    @State var checkedForUpdates = false

    init() {
        let accessoryController: AccessoryController
        if ProcessInfo().arguments.contains("-preview") {
            accessoryController = AccessoryControllerPreview(accessories: PreviewData.accessories, findMyController: FindMyController())
            self.accessoryNearbyMonitor = nil
            //            self.frameWidth = 1920
            //            self.frameHeight = 1080
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
                .frame(width: self.frameWidth, height: self.frameHeight)
                .onAppear {
                    self.checkForUpdates()
                }
        }
        .commands {
            SidebarCommands()
        }
        #if os(macOS)
        Settings {
            OpenHaystackSettingsView()
        }
        #endif
    }

    func checkForUpdates() {
        guard checkedForUpdates == false, ProcessInfo().arguments.contains("-stopUpdateCheck") == false else { return }
        UpdateCheckController.checkForNewVersion()
        checkedForUpdates = true
    }
}
