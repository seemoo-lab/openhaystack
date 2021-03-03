//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import Foundation
import MapKit
import SwiftUI

class AccessoryAnnotationView: MKAnnotationView {

    var pinView: NSHostingView<AccessoryPinView>?

    var myAnnotation: MKAnnotation? {
        didSet {
            self.updateView()
        }
    }

    override var annotation: MKAnnotation? {
        get {
            self.myAnnotation
        }
        set(a) {
            self.myAnnotation = a
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        self.image = nil

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView() {
        guard let accessory = (self.annotation as? AccessoryAnnotation)?.accessory else {return}
        self.pinView?.removeFromSuperview()
        self.pinView = NSHostingView(rootView: AccessoryPinView(accessory: accessory))

        self.addSubview(pinView!)

        self.leftCalloutOffset = CGPoint(x: -13, y: -15)
        self.rightCalloutOffset = CGPoint(x: -13, y: -15)

        let calloutView = NSTextView()
        calloutView.string = accessory.name
        calloutView.frame = NSRect(x: 0, y: 0, width: 150, height: 30)

        if let date = accessory.locationTimestamp {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short

            let dateString = dateFormatter.string(from: date)

            calloutView.string = "\(accessory.name)\n\(dateString)"
            calloutView.frame = NSRect(x: 0, y: 0, width: 150, height: 40)
        }

        calloutView.sizeToFit()
        calloutView.backgroundColor = NSColor.clear
        self.detailCalloutAccessoryView = calloutView
        self.canShowCallout = true
    }

//    override func draw(_ dirtyRect: NSRect) {
//        guard let accessoryAnnotation = self.annotation as? AccessoryAnnotation else {
//            super.draw(dirtyRect)
//            return
//        }
//
//        let path = NSBezierPath(ovalIn: dirtyRect)
//        path.lineWidth = 2.0
//
//        guard let cgColor = accessoryAnnotation.accessory.color.cgColor,
//              let strokeColor = NSColor(cgColor: cgColor)?.withAlphaComponent(0.8) else {return}
//
//        NSColor(named: NSColor.Name("PinColor"))?.setFill()
//
//        path.fill()
//
//        strokeColor.setStroke()
//        path.stroke()
//
//        let accessory = accessoryAnnotation.accessory
//
//        guard let image = NSImage(systemSymbolName: accessory.icon, accessibilityDescription: accessory.name) else {return}
//
//        let ratio = image.size.width / image.size.height
//        let imageWidth: CGFloat = 20
//        let imageHeight = imageWidth / ratio
//        let imageRect = NSRect(
//            x: dirtyRect.width/2 - imageWidth/2,
//            y: dirtyRect.height/2 - imageHeight/2,
//            width: imageWidth, height: imageHeight)
//
//        image.draw(in: imageRect)
//    }

    struct AccessoryPinView: View {
        var accessory: Accessory

        var body: some View {
            Circle()
                .strokeBorder(accessory.color, lineWidth: 2.0)
                .background(
                    ZStack {
                        Circle().fill(Color("PinColor"))
                        Image(systemName: accessory.icon)
                            .padding(3)
                    }
                )
                .frame(width: 30, height: 30)
        }
    }

}

class AccessoryAnnotation: NSObject, MKAnnotation {
    let accessory: Accessory

    var coordinate: CLLocationCoordinate2D {
        return accessory.lastLocation!.coordinate
    }

    init(accessory: Accessory) {
        self.accessory = accessory
    }
}
