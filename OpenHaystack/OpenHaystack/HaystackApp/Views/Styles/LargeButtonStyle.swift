//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SwiftUI

struct LargeButtonStyle: ButtonStyle {

    var active: Bool = false
    var destructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if configuration.isPressed {
                RoundedRectangle(cornerRadius: 5.0)
                    .fill(Color.accentColor)
            } else {
                RoundedRectangle(cornerRadius: 5.0)
                    .fill(self.active ? Color.accentColor : self.destructive ? Color.red : Color("Button"))
            }

            configuration.label
                .font(Font.headline)
                .padding(6)
        }
    }
}
