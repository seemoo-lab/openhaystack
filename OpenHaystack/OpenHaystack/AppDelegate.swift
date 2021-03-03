//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    private var mainView: some View {
        #if ACCESSORY
        if ProcessInfo().arguments.contains("-preview") {
            return OpenHaystackMainView(accessoryController: AccessoryController(accessories: PreviewData.accessories))
        }
        return OpenHaystackMainView()
        #else
        return OFFetchReportsMainView()
        #endif
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)

        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: mainView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}
