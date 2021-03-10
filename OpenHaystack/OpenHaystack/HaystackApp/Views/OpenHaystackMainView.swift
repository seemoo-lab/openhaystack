//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import MapKit
import OSLog
import SwiftUI

struct OpenHaystackMainView: View {

    @State var loading = false
    @EnvironmentObject var accessoryController: AccessoryController
    @EnvironmentObject var findMyController: FindMyController
    var accessories: [Accessory] {
        return self.accessoryController.accessories
    }

    @State var showKeyError = false
    @State var alertType: AlertType?
    @State var popUpAlertType: PopUpAlertType?
    @State var errorDescription: String?
    @State var searchPartyToken: String = ""
    @State var searchPartyTokenLoaded = false
    @State var mapType: MKMapType = .standard
    @State var isLoading = false
    @State var focusedAccessory: Accessory?
    @State var accessoryToDeploy: Accessory?

    @State var showESP32DeploySheet = false

    var body: some View {

        NavigationView {

            ManageAccessoriesView(
                alertType: self.$alertType,
                focusedAccessory: self.$focusedAccessory,
                accessoryToDeploy: self.$accessoryToDeploy,
                showESP32DeploySheet: self.$showESP32DeploySheet
            )
            .navigationTitle(self.focusedAccessory?.name ?? "OpenHaystack")

            ZStack {
                self.mapView
                if self.popUpAlertType != nil {
                    VStack {
                        Spacer()
                        PopUpAlertView(alertType: self.popUpAlertType!)
                            .transition(AnyTransition.move(edge: .bottom))
                            .padding(.bottom, 30)
                    }
                }
            }
            .ignoresSafeArea(.all)
            .alert(
                item: self.$alertType,
                content: { alertType in
                    return self.alert(for: alertType)
                }
            )
            .onChange(of: self.searchPartyToken) { (searchPartyToken) in
                guard !searchPartyToken.isEmpty, self.accessories.isEmpty == false else { return }
                self.downloadLocationReports()
            }
            .onChange(
                of: self.popUpAlertType,
                perform: { popUpAlert in
                    guard popUpAlert != nil else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.popUpAlertType = nil
                    }
                }
            )
            .onAppear {
                self.onAppear()
            }
        }
    }

    // MARK: Subviews

    /// Overlay for the map that is gray and shows an activity indicator when loading.
    var mapOverlay: some View {
        ZStack {
            if self.isLoading {
                Rectangle()
                    .fill(Color.gray)
                    .opacity(0.5)

                ActivityIndicator(size: .large)
            }
        }
    }

    /// Right side of the view showing a map with all items presented.
    var mapView: some View {
        ZStack {

            AccessoryMapView(accessoryController: self.accessoryController, mapType: self.$mapType, focusedAccessory: self.focusedAccessory)
                .overlay(self.mapOverlay)

            VStack {
                Spacer()
                HStack {

                    Picker("", selection: self.$mapType) {
                        Text("Satellite").tag(MKMapType.hybrid)
                        Text("Standard").tag(MKMapType.standard)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150, alignment: .center)

                    Button(
                        action: self.downloadLocationReports,
                        label: {
                            Image(systemName: "arrow.clockwise")
                            Text("Reload")
                        }
                    )
                    .opacity(1.0)
                    .disabled(self.accessories.isEmpty)
                }
                .padding(.bottom, 25)
            }
        }
    }

    func onAppear() {

        /// Checks if the search party token can be fetched without the Mail Plugin. If true the plugin is not needed for this environment. (e.g.  when SIP is disabled)
        let reportsFetcher = ReportsFetcher()
        if let token = reportsFetcher.fetchSearchpartyToken(),
            let tokenString = String(data: token, encoding: .ascii)
        {
            self.searchPartyToken = tokenString
            return
        }

        let pluginManager = MailPluginManager()

        // Check if the plugin is installed
        if pluginManager.isMailPluginInstalled == false {
            // Install the mail plugin
            self.alertType = .activatePlugin
        } else {
            self.checkPluginIsRunning(nil)
        }
    }

    /// Download the location reports for all current accessories. Shows an error if something fails, like plug-in is missing
    func downloadLocationReports() {

        self.checkPluginIsRunning { (running) in
            guard running else {
                self.alertType = .activatePlugin
                return
            }

            guard !self.searchPartyToken.isEmpty,
                let tokenData = self.searchPartyToken.data(using: .utf8)
            else {
                self.alertType = .searchPartyToken
                return
            }

            withAnimation {
                self.isLoading = true
            }

            findMyController.fetchReports(for: accessories, with: tokenData) { result in
                switch result {
                case .failure(let error):
                    os_log(.error, "Downloading reports failed %@", error.localizedDescription)
                case .success(let devices):
                    let reports = devices.compactMap({ $0.reports }).flatMap({ $0 })
                    if reports.isEmpty {
                        withAnimation {
                            self.popUpAlertType = .noReportsFound
                        }
                    }
                }
                withAnimation {
                    self.isLoading = false
                }
            }
        }

    }

    func deploy(accessory: Accessory) {
        self.accessoryToDeploy = accessory
        self.alertType = .selectDepoyTarget
    }

    /// Deploy the public key of the accessory to a BBC microbit.
    func deployAccessoryToMicrobit(accessory: Accessory) {
        do {
            try MicrobitController.deploy(accessory: accessory)
        } catch {
            os_log("Error occurred %@", String(describing: error))
            self.alertType = .deployFailed
            return
        }

        self.alertType = .deployedSuccessfully

        self.accessoryToDeploy = nil
    }

    /// Ask to install and activate the mail plugin.
    func installMailPlugin() {
        let pluginManager = MailPluginManager()
        guard pluginManager.isMailPluginInstalled == false else {

            return
        }
        do {
            try pluginManager.installMailPlugin()
        } catch {
            DispatchQueue.main.async {
                self.alertType = .pluginInstallFailed
                os_log(.error, "Could not install mail plugin\n %@", String(describing: error))
            }
        }
    }

    func checkPluginIsRunning(_ completion: ((Bool) -> Void)?) {
        // Check if Mail plugin is active
        AnisetteDataManager.shared.requestAnisetteData { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let accountData):

                    withAnimation {
                        self.searchPartyToken = String(data: accountData.searchPartyToken, encoding: .ascii) ?? ""
                        if self.searchPartyToken.isEmpty == false {
                            self.searchPartyTokenLoaded = true
                        }
                    }
                    completion?(true)
                case .failure(let error):
                    if let error = error as? AnisetteDataError {
                        switch error {
                        case .pluginNotFound:
                            self.alertType = .activatePlugin
                        default:
                            self.alertType = .activatePlugin
                        }
                    }
                    completion?(false)
                }
            }
        }
    }

    func downloadPlugin() {
        do {
            try MailPluginManager().pluginDownload()
        } catch {
            self.alertType = .pluginInstallFailed
        }
    }

    // MARK: - Alerts

    // swiftlint:disable function_body_length
    /// Create an alert for the given alert type.
    ///
    /// - Parameter alertType: current alert type
    /// - Returns: A SwiftUI Alert
    func alert(for alertType: AlertType) -> Alert {
        switch alertType {
        case .keyError:
            return Alert(title: Text("Could not create accessory"), message: Text(String(describing: self.errorDescription)), dismissButton: Alert.Button.cancel())
        case .searchPartyToken:
            return Alert(
                title: Text("Add the search party token"),
                message: Text(
                    """
                    Please paste the search party token below after copying itfrom the macOS Keychain.
                    The item that contains the key can be found by searching for:
                    com.apple.account.DeviceLocator.search-party-token
                    """
                ),
                dismissButton: Alert.Button.okay())
        case .deployFailed:
            return Alert(
                title: Text("Could not deploy"),
                message: Text("Deploying to microbit failed. Please reconnect the device over USB"),
                dismissButton: Alert.Button.okay())
        case .deployedSuccessfully:
            return Alert(
                title: Text("Deploy successfull"),
                message: Text("This device will now be tracked by all iPhones and you can use this app to find its last reported location"),
                dismissButton: Alert.Button.okay())
        case .deletionFailed:
            return Alert(title: Text("Could not delete accessory"), dismissButton: Alert.Button.okay())

        case .noReportsFound:
            return Alert(
                title: Text("No reports found"),
                message: Text("Your accessory might have not been found yet or it is not powered. Make sure it has enough power to be found by nearby iPhones"),
                dismissButton: Alert.Button.okay())
        case .activatePlugin:
            let message =
                """
                To access your Apple ID for downloading location reports we need to use a plugin in Apple Mail.
                Please make sure Apple Mail is running.
                Open Mail -> Preferences -> General -> Manage Plug-Ins... -> Select Haystack

                We do not access any of your e-mail data. This is just necessary, because Apple blocks access to certain iCloud tokens otherwise.
                """

            return Alert(
                title: Text("Install & Activate Mail Plugin"), message: Text(message),
                primaryButton: .default(Text("Okay"), action: { self.installMailPlugin() }),
                secondaryButton: .cancel())

        case .pluginInstallFailed:
            return Alert(
                title: Text("Mail Plugin installation failed"),
                message: Text(
                    "To access the location reports of your devices an Apple Mail plugin is necessary"
                        + "\nThe installtion of this plugin has failed.\n\n Please download it manually unzip it and move it to /Library/Mail/Bundles"),
                primaryButton: .default(
                    Text("Download plug-in"),
                    action: {
                        self.downloadPlugin()
                    }), secondaryButton: .cancel())
        case .selectDepoyTarget:
            let microbitButton = Alert.Button.default(Text("Microbit"), action: { self.deployAccessoryToMicrobit(accessory: self.accessoryToDeploy!) })

            let esp32Button = Alert.Button.default(
                Text("ESP32"),
                action: {
                    self.showESP32DeploySheet = true
                })

            return Alert(
                title: Text("Select target"),
                message: Text("Please select to which device you want to deploy"),
                primaryButton: microbitButton,
                secondaryButton: esp32Button)
        }
    }

    enum AlertType: Int, Identifiable {
        var id: Int {
            return self.rawValue
        }

        case keyError
        case searchPartyToken
        case deployFailed
        case deployedSuccessfully
        case deletionFailed
        case noReportsFound
        case activatePlugin
        case pluginInstallFailed
        case selectDepoyTarget
    }

}

struct OpenHaystackMainView_Previews: PreviewProvider {
    static var accessoryController = AccessoryControllerPreview(accessories: PreviewData.accessories) as AccessoryController

    static var previews: some View {
        OpenHaystackMainView()
            .environmentObject(accessoryController)
    }
}

extension Alert.Button {
    static func okay() -> Alert.Button {
        Alert.Button.default(Text("Okay"))
    }
}
