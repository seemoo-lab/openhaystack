//
//  AccessoryMapView.swift
//  OpenHaystack
//
//  Created by Alex - SEEMOO on 02.03.21.
//  Copyright © 2021 SEEMOO - TU Darmstadt. All rights reserved.
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
