//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2024 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2024 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SwiftUI

struct OpenHaystackSettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("useMailPlugin") private var useMailPlugin = false
    @AppStorage("searchPartyToken") private var searchPartyToken = ""

    var body: some View {
        Form {
            Toggle("Use Apple Mail Plugin (only works on macOS 13 and lower)", isOn: $useMailPlugin)
            TextField("Search Party Token", text: $searchPartyToken)
        }
        .padding(20)
        .frame(width: 600, height: 200)
    }
}
