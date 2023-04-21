//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import OSLog
import SwiftUI

struct NRFInstallSheet: View {
    @Binding var accessory: Accessory?
    @Binding var alertType: OpenHaystackMainView.AlertType?
    @Binding var scriptOutput: String?
    @State var isFlashing = false

    @ObservedObject var days = NumbersOnly()
    @ObservedObject var hours = NumbersOnly()
    @ObservedObject var minutes = NumbersOnly()

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            self.flashView
                .padding()
                .overlay(self.loadingOverlay)
                .frame(minWidth: 640, minHeight: 480, alignment: .center)
        }
        .onAppear {
        }
    }

    var flashView: some View {
        VStack {
            Text("Flash your NRF Device")
                .font(.title2)

            Text("Fill out options for flashing firmware")
                .foregroundColor(.gray)

            Divider()

            Text(
                "The new NRF firmware uses rotating keys. This means that the device changes its public key after a specific number of days. This disallows ad networks to track your device over several days when you are moving around the city. Shorter update cycles then days are not supported"
            )
            self.timePicker

            Text("One day is a reasonable amount of time")
                .font(.footnote)
                .foregroundColor(.secondary)

            Spacer()

            HStack {
                Spacer()

                Button(
                    "Deploy",
                    action: {
                        if let accessory = self.accessory {
                            var daysInt = Int(days.value) ?? 1
                            if daysInt < 1 {
                                daysInt = 1
                            }
                            let hoursInt = 0
                            let minutesInt = 0

                            let updateInterval = daysInt * 24 * 60 + hoursInt * 60 + minutesInt
                            //warn user if no update interval was given
                            if updateInterval > 0 {
                                deployAccessoryToNRFDevice(accessory: accessory, updateInterval: updateInterval)
                            } else {

                            }
                        }
                    })

                Button(
                    "Cancel",
                    action: {
                        self.presentationMode.wrappedValue.dismiss()
                    })
            }

            HStack {
                Spacer()
                Text("Flashing from M1 Macs might fail due to missing ARM support by NRF")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    var timePicker: some View {
        Group {
            HStack {
                TextField("", text: $days.value).textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Day(s)")
            }
        }.padding()
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

    func deployAccessoryToNRFDevice(accessory: Accessory, updateInterval: Int) {
        do {
            self.isFlashing = true

            try NRFController.flashToNRF(
                accessory: accessory,
                updateInterval: updateInterval,
                completion: { result in
                    presentationMode.wrappedValue.dismiss()

                    self.isFlashing = false
                    switch result {
                    case .success(_):
                        self.alertType = .deployedSuccessfully
                        accessory.isDeployed = true
                        accessory.usesDerivation = true
                        accessory.updateInterval = TimeInterval(updateInterval * 60)
                    case .failure(let loggingFileUrl, let error):
                        os_log(.error, "Flashing to NRF device failed %@", String(describing: error))
                        self.presentationMode.wrappedValue.dismiss()
                        self.alertType = .nrfDeployFailed
                        do {
                            self.scriptOutput = try String(contentsOf: loggingFileUrl, encoding: .ascii)
                        } catch {
                            self.scriptOutput = "Error while trying to read log file."
                        }
                    }
                })
        } catch {
            os_log(.error, "Preparation or execution of script failed %@", String(describing: error))
            self.presentationMode.wrappedValue.dismiss()
            self.alertType = .deployFailed
            self.isFlashing = false
        }

        self.accessory = nil
    }
}

struct NRFInstallSheet_Previews: PreviewProvider {
    @State static var acc: Accessory? = try! Accessory(name: "Sample")

    @State static var alert: OpenHaystackMainView.AlertType?
    @State static var scriptOutput: String?

    static var previews: some View {
        NRFInstallSheet(accessory: $acc, alertType: $alert, scriptOutput: $scriptOutput)
    }
}

class NumbersOnly: ObservableObject {
    @Published var value = "1" {
        didSet {
            let filtered = value.filter { $0.isNumber }

            if value != filtered {
                value = filtered
            }
        }
    }
}
