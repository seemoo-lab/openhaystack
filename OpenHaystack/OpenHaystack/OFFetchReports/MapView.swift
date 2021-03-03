//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import SwiftUI
import Cocoa
import MapKit

struct MapView_ViewControllerRepresentable: NSViewControllerRepresentable {
    var findMyController: FindMyController?

    func makeNSViewController(context: Context) -> MapViewController {
        return MapViewController(nibName: NSNib.Name("MapViewController"), bundle: nil)
    }

    func updateNSViewController(_ nsViewController: MapViewController, context: Context) {
        if let controller = self.findMyController {
            nsViewController.addLocationsReports(from: controller.devices)
        }
    }

}

struct MapView: View {
    @Environment(\.findMyController) var findMyController

    var body: some View {
        MapView_ViewControllerRepresentable(findMyController: self.findMyController)
    }
}
