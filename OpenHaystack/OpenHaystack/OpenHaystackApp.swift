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
    @Environment(\.accessoryController) var accessoryController: AccessoryController
    @Environment(\.findMyController) var findMyController: FindMyController

    init() {}

    var body: some Scene {
        WindowGroup {
            OpenHaystackMainView()
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
            return AccessoryControllerPreview(accessories: PreviewData.accessories)
        } else {
            return AccessoryController()
        }
    }()
}

extension EnvironmentValues {
    var findMyController: FindMyController {
        get {self[FindMyControllerEnvironmentKey]}
    }
    
    var accessoryController: AccessoryController {
        get{self[AccessoryControllerEnvironmentKey]}
        set{self[AccessoryControllerEnvironmentKey] = newValue}
    }
}
