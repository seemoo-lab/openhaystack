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

    @State var keyName: String = ""
    @State var accessoryColor: Color = Color.white
    @State var selectedIcon: String = "briefcase.fill"

    @State var loading = false
    @ObservedObject var accessoryController = AccessoryController.shared
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

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    HStack {
                        self.accessoryView
                            .frame(width: geo.size.width * 0.5)

                        Spacer()

                        VStack {
                            self.mapView
                        }.frame(width: geo.size.width * 0.5, alignment: .trailing)

                    }

                    if searchPartyTokenLoaded == false {
                        TextField("Search Party token", text: self.$searchPartyToken)
                    }
                }

                if self.popUpAlertType != nil {
                    VStack {
                        Spacer()

                        PopUpAlertView(alertType: self.popUpAlertType!)
                            .transition(AnyTransition.move(edge: .bottom))
                            .padding(.bottom, 30)
                    }

                }
            }
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
        .padding([.leading, .trailing, .bottom])
        .frame(minWidth: 720, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
    }

    // MARK: Subviews

    /// Left side of the view. Shows a list of accessories and the possibility to add accessories
    var accessoryView: some View {
        VStack {
            Text("Create a new tracking accessory")
                .font(.title2)
                .padding(.top)

            Text("A BBC Microbit can be used to track anything you care about. Connect it over USB, name the accessory (e.g. Backpack) generate the key and deploy it")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundColor(.gray)

            HStack {
                TextField("Name", text: self.$keyName)
                ColorPicker("", selection: self.$accessoryColor)
                    .frame(maxWidth: 50, maxHeight: 20)
                IconSelectionView(selectedImageName: self.$selectedIcon)
            }

            Button(
                action: self.addAccessory,
                label: {
                    Text("Generate key and deploy")
                }
            )
            .disabled(self.keyName.isEmpty)
            .padding(.bottom)

            Divider()

            Text("Your accessories")
                .font(.title2)
                .padding(.top)

            if self.accessories.isEmpty {
                Spacer()
                Text("No accessories have been added yet. Go ahead and add one above")
                    .multilineTextAlignment(.center)
            } else {
                self.accessoryList
            }

            Spacer()

        }
    }

    /// Accessory List view.
    var accessoryList: some View {
        List(self.accessories) { accessory in
            AccessoryListEntry(
                accessory: accessory,
                alertType: self.$alertType,
                delete: self.delete(accessory:),
                deployAccessoryToMicrobit: self.deploy(accessory:),
                zoomOn: { self.focusedAccessory = $0 })
        }
        .background(Color.clear)
        .cornerRadius(15.0)
    }

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
                .cornerRadius(15.0)
                .clipped()
                .padding([.top, .bottom], 15)

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

    /// Add an accessory with the provided details.
    func addAccessory() {
        let keyName = self.keyName
        self.keyName = ""

        do {
            let accessory = try Accessory(name: keyName, color: self.accessoryColor, iconName: self.selectedIcon)

            let accessories = self.accessories + [accessory]

            withAnimation {
                self.accessoryController.accessories = accessories
            }
            try self.accessoryController.save()

            if let microbits = try? MicrobitController.findMicrobits(), microbits.isEmpty == false {
                self.deployAccessoryToMicrobit(accessory: accessory)
            } else if ESP32Controller.portURL != nil {
                self.deployAccessoryToESP32(accessory: accessory)
            }

        } catch {
            self.errorDescription = String(describing: error)
            self.showKeyError = true
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

            let findMyDevices = self.accessories.compactMap({ acc -> FindMyDevice? in
                do {
                    return try acc.toFindMyDevice()
                } catch {
                    os_log("Failed getting id for key %@", String(describing: error))
                    return nil
                }
            })

            FindMyController.shared.devices = findMyDevices
            FindMyController.shared.fetchReports(with: tokenData) { error in

                let reports = FindMyController.shared.devices.compactMap({ $0.reports }).flatMap({ $0 })
                if reports.isEmpty {
                    withAnimation {
                        self.popUpAlertType = .noReportsFound
                    }
                } else {
                    self.accessoryController.updateWithDecryptedReports(devices: FindMyController.shared.devices)
                }

                withAnimation {
                    self.isLoading = false
                }

                guard error != nil else { return }
                os_log("Error: %@", String(describing: error))

            }
        }

    }

    /// Delete an accessory from the list of accessories.
    func delete(accessory: Accessory) {
        do {
            var accessories = self.accessories
            guard let idx = accessories.firstIndex(of: accessory) else { return }

            accessories.remove(at: idx)

            withAnimation {
                self.accessoryController.accessories = accessories
            }
            try self.accessoryController.save()

        } catch {
            self.alertType = .deletionFailed
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

    func deployAccessoryToESP32(accessory: Accessory) {
        do {
            try ESP32Controller.flashToESP32(accessory: accessory, completion: { result in
                switch result {
                case .success(_):
                    self.alertType = .deployedSuccessfully
                case .failure(let error):
                    os_log(.error, "Flashing to ESP32 failed %@", String(describing: error))
                    self.alertType = .deployFailed
                }
            })
        } catch {
            os_log(.error, "Execution of script failed %@", String(describing: error))
            self.alertType = .deployFailed
        }

        self.accessoryToDeploy = nil
    }

    func onAppear() {

        /// Checks if the search party token can be fetched without the Mail Plugin. If true the plugin is not needed for this environment. (e.g.  when SIP is disabled)
        let reportsFetcher = ReportsFetcher()
        if let token = reportsFetcher.fetchSearchpartyToken(),
            let tokenString = String(data: token, encoding: .ascii) {
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
            let microbitButton = Alert.Button.default(Text("Microbit"), action: {self.deployAccessoryToMicrobit(accessory: self.accessoryToDeploy!)})

            let esp32Button = Alert.Button.default(Text("ESP32"), action: {
                self.deployAccessoryToESP32(accessory: self.accessoryToDeploy!)
            })

            return Alert(title: Text("Select target"),
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

    static var accessories: [Accessory] = PreviewData.accessories

    static var previews: some View {
        OpenHaystackMainView(accessoryController: AccessoryController(accessories: accessories))
            .frame(width: 640, height: 480, alignment: .center)
    }
}

extension Alert.Button {
    static func okay() -> Alert.Button {
        Alert.Button.default(Text("Okay"))
    }
}
