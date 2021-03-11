//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import MapKit
import SwiftUI

struct AccessoryMapView: NSViewControllerRepresentable {
    @ObservedObject var accessoryController: AccessoryController
    @Binding var mapType: MKMapType
    var focusedAccessory: Accessory?

    func makeNSViewController(context: Context) -> MapViewController {
        return MapViewController(nibName: NSNib.Name("MapViewController"), bundle: nil)
    }

    func updateNSViewController(_ nsViewController: MapViewController, context: Context) {
        let accessories = self.accessoryController.accessories

        nsViewController.zoom(on: focusedAccessory)
        nsViewController.addLastLocations(from: accessories)
        nsViewController.changeMapType(mapType)
    }
}
