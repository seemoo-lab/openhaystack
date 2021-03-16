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
    @Binding var focusedAccessory: Accessory?
    @Binding var showHistory: Bool
    @Binding var showPastHistory: TimeInterval
    var delayer = UpdateDelayer()

    func makeNSViewController(context: Context) -> MapViewController {
        return MapViewController(nibName: NSNib.Name("MapViewController"), bundle: nil)
    }

    func updateNSViewController(_ nsViewController: MapViewController, context: Context) {
        let accessories = self.accessoryController.accessories

        nsViewController.focusedAccessory = focusedAccessory
        if showHistory {
            delayer.delayUpdate {
                nsViewController.addAllLocations(from: focusedAccessory!, past: showPastHistory)
                nsViewController.zoomInOnAll()
            }
        } else {
            nsViewController.addLastLocations(from: accessories)
            nsViewController.zoomInOnSelection()
        }
        nsViewController.changeMapType(mapType)
    }
}

class UpdateDelayer {
    /// Some view updates need to be delayed to mitigate UI glitches.
    var delayedWorkItem: DispatchWorkItem?

    func delayUpdate(delay: Double = 0.3, closure: @escaping () -> Void) {
        self.delayedWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            closure()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        self.delayedWorkItem = workItem
    }
}
