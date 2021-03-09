//
//  ESP32InstallSheet.swift
//  OpenHaystack
//
//  Created by Alex - SEEMOO on 09.03.21.
//  Copyright © 2021 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import OSLog

struct ESP32InstallSheet: View {
    @Binding var accessory: Accessory?
    @Binding var alertType: OpenHaystackMainView.AlertType?
    @State var detectedPorts: [URL] = []

    @State var isFlashing = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            self.portSelectionView
                .padding()
                .overlay(self.loadingOverlay)
                .frame(minWidth: 640, minHeight: 480, alignment: .center)
        }
        .onAppear {
            self.detectedPorts = ESP32Controller.findPort()
        }
    }

    var portSelectionView: some View {
        VStack {
            Text("Flash your ESP32")
                .font(.title2)

            Text("Select the serial port that belongs to your ESP32 module")
                .foregroundColor(.gray)

            self.portList

            Spacer()

            HStack {
                Spacer()

                Button("Reload ports", action: {
                    self.detectedPorts = ESP32Controller.findPort()
                })

                Button("Cancel", action: {
                    self.presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }

    var portList: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(0..<self.detectedPorts.count, id: \.self) { portIdx in
                    Button(action: {
                        if let accessory = self.accessory {
                            // Flash selected module
                            self.deployAccessoryToESP32(accessory: accessory, to: self.detectedPorts[portIdx])
                        }
                    }, label: {
                        HStack {
                            Text(self.detectedPorts[portIdx].path)
                                .padding(4)
                            Spacer()
                        }
                        .contentShape(Rectangle())

                    })
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    var loadingOverlay: some View {
        ZStack {
            if isFlashing {
                Rectangle()
                    .fill(Color.gray)
                    .opacity(0.5)

                VStack {
                    ActivityIndicator(size: .large)
                    Text("This can take up to 3min")
                }

            }
        }
    }

    func deployAccessoryToESP32(accessory: Accessory, to port: URL) {
        do {
            self.isFlashing = true
            try ESP32Controller.flashToESP32(accessory: accessory, port: port, completion: { result in
                presentationMode.wrappedValue.dismiss()

                self.isFlashing = false
                switch result {
                case .success(_):
                    self.alertType = .deployedSuccessfully
                case .failure(let error):
                    os_log(.error, "Flashing to ESP32 failed %@", String(describing: error))
                    self.presentationMode.wrappedValue.dismiss()
                    self.alertType = .deployFailed
                }
            })
        } catch {
            os_log(.error, "Execution of script failed %@", String(describing: error))
            self.presentationMode.wrappedValue.dismiss()
            self.alertType = .deployFailed
            self.isFlashing = false

        }

        self.accessory = nil
    }
}

struct ESP32InstallSheet_Previews: PreviewProvider {
    @State static var acc: Accessory? = try! Accessory(name: "Sample")

    @State static var alert: OpenHaystackMainView.AlertType?

    static var previews: some View {
        ESP32InstallSheet(accessory: $acc, alertType: $alert)
    }
}
