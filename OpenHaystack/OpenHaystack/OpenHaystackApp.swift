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

    init() {
        let accessoryController: AccessoryController
        if ProcessInfo().arguments.contains("-preview") {
            accessoryController = AccessoryControllerPreview(accessories: PreviewData.accessories, findMyController: FindMyController())
        } else {
            accessoryController = AccessoryController()
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

//MARK: Environment objects 
private struct FindMyControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue: FindMyController = FindMyController()
}

private struct AccessoryControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue: AccessoryController = {
        if ProcessInfo().arguments.contains("-preview") {
            return AccessoryControllerPreview(accessories: PreviewData.accessories, findMyController: FindMyController())
        } else {
            return AccessoryController()
        }
    }()
}
