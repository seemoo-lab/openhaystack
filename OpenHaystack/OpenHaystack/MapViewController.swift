//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import Cocoa
import MapKit

final class MapViewController: NSViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var pinsShown = false
    var focusedAccessory: Accessory?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.mapView.register(AccessoryAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Accessory")
    }

    func zoom(on accessory: Accessory?) {
        self.focusedAccessory = accessory
        self.zoomInOnSelection()
    }

    func addLastLocations(from accessories: [Accessory]) {
        // Add pins
        self.mapView.removeAnnotations(self.mapView.annotations)
        for accessory in accessories {
            guard accessory.lastLocation != nil else { continue }
            let annotation = AccessoryAnnotation(accessory: accessory)
            self.mapView.addAnnotation(annotation)
        }
        self.zoomInOnSelection()
    }

    func zoomInOnSelection() {
        var annotations = [MKAnnotation]()

        if focusedAccessory == nil {
            // Show all locations
            annotations = self.mapView.annotations
        } else {
            // Show focused accessory
            let focusedAnnotation: MKAnnotation? = self.mapView.annotations.first(where: { annotation in
                let accessoryAnnotation = annotation as! AccessoryAnnotation
                return accessoryAnnotation.accessory == self.focusedAccessory
            })
            if let annotation = focusedAnnotation {
                annotations = [annotation]
            }
        }
        DispatchQueue.main.async {
            self.mapView.showAnnotations(annotations, animated: true)
        }
    }

    func changeMapType(_ mapType: MKMapType) {
        self.mapView.mapType = mapType
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case is AccessoryAnnotation:
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Accessory", for: annotation)
            annotationView.annotation = annotation
            return annotationView
        default:
            return nil
        }
    }

}
