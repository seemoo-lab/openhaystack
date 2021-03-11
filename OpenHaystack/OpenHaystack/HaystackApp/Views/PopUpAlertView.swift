//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI

struct PopUpAlertView: View {

    let alertType: PopUpAlertType

    var body: some View {
        VStack {
            switch self.alertType {
            case .noReportsFound:
                VStack {
                    Text("No reports found")
                        .font(.title2)

                    Text("Your accessory might have not been found yet or it is not powered. Make sure it has enough power to be found by nearby iPhones")
                        .font(.caption)
                }.padding()
            }

        }
        .background(
            RoundedRectangle(cornerRadius: 7.5)
                .fill(Color.gray))
    }
}

struct PopUpAlertView_Previews: PreviewProvider {
    static var previews: some View {
        PopUpAlertView(alertType: .noReportsFound)
    }
}

enum PopUpAlertType: Int, Identifiable {
    var id: Int {
        return self.rawValue
    }

    case noReportsFound
}
