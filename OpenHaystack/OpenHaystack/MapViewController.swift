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

    func addLocationsReports(from devices: [FindMyDevice]) {
        if !self.mapView.annotations.isEmpty {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }

        // Zoom to first location
        if let location = devices.first?.decryptedReports?.first {
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
            let region = MKCoordinateRegion(center: coordinate, span: span)

            self.mapView.setRegion(region, animated: true)
        }

        // Add pins
        for device in devices {

            guard let reports = device.decryptedReports else { continue }
            for report in reports {
                let pin = MKPointAnnotation()
                pin.title = device.deviceId
                pin.coordinate = CLLocationCoordinate2D(latitude: report.latitude, longitude: report.longitude)
                self.mapView.addAnnotation(pin)
            }
        }

    }

    func zoom(on accessory: Accessory?) {
        self.focusedAccessory = accessory
        guard let location = accessory?.lastLocation else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        DispatchQueue.main.async {
            self.mapView.setRegion(region, animated: true)
        }
    }

    func addLastLocations(from accessories: [Accessory]) {
        if !self.mapView.annotations.isEmpty {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }

        // Zoom to first location
        if focusedAccessory == nil, let location = accessories.first(where: { $0.lastLocation != nil })?.lastLocation {
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            DispatchQueue.main.async {
                self.mapView.setRegion(region, animated: true)
            }
        }

        // Add pins
        for accessory in accessories {
            guard accessory.lastLocation != nil else { continue }

            let annotation = AccessoryAnnotation(accessory: accessory)
            self.mapView.addAnnotation(annotation)

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
