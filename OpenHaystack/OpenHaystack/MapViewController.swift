//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Cocoa
import MapKit

final class MapViewController: NSViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var pinsShown = false
    var focusedAccessory: Accessory?
    /// Some view updates need to be delayed to mitigate ui glitches
    var delayedWorkItem: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.mapView.register(AccessoryAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Accessory")
        self.mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: "AccessoryHistory")
    }

    func addLastLocations(from accessories: [Accessory]) {
        // Add pins
        self.mapView.removeAnnotations(self.mapView.annotations)
        for accessory in accessories {
            guard accessory.lastLocation != nil else { continue }
            let annotation = AccessoryAnnotation(accessory: accessory)
            self.mapView.addAnnotation(annotation)
        }
    }

    func zoomInOnSelection() {
        if focusedAccessory == nil {
            zoomInOnAll()
        } else {
            // Show focused accessory
            let focusedAnnotation: MKAnnotation? = self.mapView.annotations.first(where: { annotation in
                let accessoryAnnotation = annotation as! AccessoryAnnotation
                return accessoryAnnotation.accessory == self.focusedAccessory
            })
            if let annotation = focusedAnnotation {
                zoomInOn(annotations: [annotation])
            }
        }
    }

    func zoomInOnAll() {
        zoomInOn(annotations: self.mapView.annotations)
    }

    func zoomInOn(annotations: [MKAnnotation]) {
        DispatchQueue.main.async {
            self.mapView.showAnnotations(annotations, animated: true)
        }
    }

    func changeMapType(_ mapType: MKMapType) {
        self.mapView.mapType = mapType
    }

    func addAllLocations(from accessory: Accessory, past: TimeInterval) {
        //We delay the updates here to make sure that we do not get any race conditions with SwiftUI and our map update cycle that could end up showing the wrong data
        self.delayedWorkItem?.cancel()
        
        let workItem = DispatchWorkItem {
            let now = Date()
            let pastLocations = accessory.locations?.filter { location in
                guard let timestamp = location.timestamp else {
                    return false
                }
                return timestamp + past >= now
            }

            self.mapView.removeAnnotations(self.mapView.annotations)
            for location in pastLocations ?? [] {
                let coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                let annotation = AccessoryHistoryAnnotation(coordinate: coordinate)
                self.mapView.addAnnotation(annotation)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        self.delayedWorkItem = workItem
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case is AccessoryAnnotation:
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Accessory", for: annotation)
            annotationView.annotation = annotation
            return annotationView
        case is AccessoryHistoryAnnotation:
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AccessoryHistory", for: annotation)
            annotationView.annotation = annotation
            return annotationView
        default:
            return nil
        }
    }

}
