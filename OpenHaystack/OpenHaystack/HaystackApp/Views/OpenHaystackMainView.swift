//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import MapKit
import OSLog
import SwiftUI

struct OpenHaystackMainView: View {

    @State var loading = false
    @EnvironmentObject var accessoryController: AccessoryController

    var accessories: [Accessory] {
        return self.accessoryController.accessories
    }

    @State var alertType: AlertType?
    @State var popUpAlertType: PopUpAlertType?
    @State var errorDescription: String?
    @State var scriptOutput: String?
    @State var searchPartyToken: String = ""
    @State var searchPartyTokenLoaded = false
    @State var mapType: MKMapType = .standard
    @State var isLoading = false
    @State var focusedAccessory: Accessory?
    @State var historyMapView = false
    @State var historySeconds: TimeInterval = TimeInterval.Units.day.rawValue
    @State var accessoryToDeploy: Accessory?
    @State var showMailPlugInPopover = false

    @State var mailPluginIsActive = false

    @State var showESP32DeploySheet = false

    @AppStorage("searchPartyToken") private var settingsSPToken: String?
    @AppStorage("useMailPlugin") private var settingsUseMailPlugin: Bool = false

    var body: some View {

        NavigationView {

            ManageAccessoriesView(
                alertType: self.$alertType,
                scriptOutput: self.$scriptOutput,
                focusedAccessory: self.$focusedAccessory,
                accessoryToDeploy: self.$accessoryToDeploy,
                showESP32DeploySheet: self.$showESP32DeploySheet
            )
            .frame(minWidth: 250, idealWidth: 280, maxWidth: .infinity, minHeight: 300, idealHeight: 400, maxHeight: .infinity, alignment: .center)

            ZStack {
                AccessoryMapView(
                    accessoryController: self.accessoryController, mapType: self.$mapType, focusedAccessory: self.$focusedAccessory, showHistory: self.$historyMapView,
                    showPastHistory: self.$historySeconds
                )
                .overlay(self.mapOverlay)
                if self.popUpAlertType != nil {
                    VStack {
                        Spacer()
                        PopUpAlertView(alertType: self.popUpAlertType!)
                            .transition(AnyTransition.move(edge: .bottom))
                            .padding(.bottom, 30)
                    }
                }
            }
            .frame(minWidth: 500, idealWidth: 500, maxWidth: .infinity, minHeight: 300, idealHeight: 400, maxHeight: .infinity, alignment: .center)
            .toolbar(content: {
                self.toolbarView
            })
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
        .navigationTitle(self.focusedAccessory?.name ?? "Your accessories")

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

    /// All toolbar items shown.
    var toolbarView: some View {
        Group {
            if self.historyMapView {
                Text("\(TimeInterval(self.historySeconds).description)")
                Slider<Text, EmptyView>.withLogScale(value: $historySeconds, in: 30 * TimeInterval.Units.minute.rawValue...TimeInterval.Units.week.rawValue) {
                    Text("Past time to show")
                }
                .frame(width: 80)
            }
            Toggle(isOn: $historyMapView) {
                Label("Show location history", systemImage: "clock")
            }
            .disabled(self.focusedAccessory == nil)

            Picker("", selection: self.$mapType) {
                Text("Satellite").tag(MKMapType.hybrid)
                Text("Standard").tag(MKMapType.standard)
            }
            .pickerStyle(SegmentedPickerStyle())

            Button(
                action: {
                    if self.settingsUseMailPlugin && !self.mailPluginIsActive {
                        self.showMailPlugInPopover.toggle()
                        self.checkPluginIsRunning(silent: true, nil)
                    } else {
                        self.downloadLocationReports()
                    }

                },
                label: {
                    HStack {
                        Circle()
                            .fill(self.mailPluginIsActive ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Label("Reload", systemImage: "arrow.clockwise")
                            .disabled(!self.mailPluginIsActive)
                    }

                }
            )
            .disabled(self.accessories.isEmpty)
            .popover(
                isPresented: $showMailPlugInPopover,
                content: {
                    self.mailStatePopover
                })
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

        /// Checks if the search party token was set in the settings. If true the plugin is also not needed
        if let tokenString = self.settingsSPToken {
            self.searchPartyToken = tokenString
            return
        }

        /// Uses mail plugin if enabled in settings
        if self.settingsUseMailPlugin {
            let pluginManager = MailPluginManager()
            // Check if the plugin is installed
            if pluginManager.isMailPluginInstalled == false {
                // Install the mail plugin
                self.alertType = .activatePlugin
                self.checkPluginIsRunning(silent: true, nil)
            } else {
                self.checkPluginIsRunning(nil)
            }
        }


    }

    /// Download the location reports for all current accessories. Shows an error if something fails, like plug-in is missing
    func downloadLocationReports() {
        self.isLoading = true
        self.accessoryController.downloadLocationReports { result in
            self.isLoading = false
            switch result {
            case .failure(let alert):
                if alert == .noReportsFound {
                    self.popUpAlertType = .noReportsFound
                } else {
                    if alert == .activatePlugin {
                        self.mailPluginIsActive = false
                    }
                    self.alertType = alert
                }
            case .success(_):
                break
            }
        }
    }

    var mailStatePopover: some View {
        VStack {
            HStack {
                Image(systemName: "envelope")
                    .font(.title)
                    .foregroundColor(self.mailPluginIsActive ? .green : .red)

                if self.mailPluginIsActive {
                    Text("The mail plug-in is up and running")
                } else {
                    Text("Cannot connect to the mail plug-in. Open Apple Mail and make sure the plug-in is enabled")
                }
            }
            .padding()
        }
        .frame(width: 250, height: 120)
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

    func checkPluginIsRunning(silent: Bool = false, _ completion: ((Bool) -> Void)?) {
        // Check if Mail plugin is active
        AnisetteDataManager.shared.requestAnisetteData { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let accountData):

                    withAnimation {
                        if let token = accountData.searchPartyToken {
                            self.searchPartyToken = String(data: token, encoding: .ascii) ?? ""
                            if self.searchPartyToken.isEmpty == false {
                                self.searchPartyTokenLoaded = true
                            }
                        }
                    }
                    self.mailPluginIsActive = true
                    self.showMailPlugInPopover = false
                    completion?(true)
                case .failure(let error):
                    if let error = error as? AnisetteDataError, silent == false {
                        switch error {
                        case .pluginNotFound:
                            self.alertType = .activatePlugin
                        default:
                            self.alertType = .activatePlugin
                        }
                    }
                    self.mailPluginIsActive = false
                    completion?(false)

                    //Check again in 5s
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 5,
                        execute: {
                            self.checkPluginIsRunning(silent: true, nil)
                        })
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
                    Please paste the search party token in the settings after copying it from the macOS Keychain.
                    The item that contains the key can be found by searching for:
                    com.apple.account.DeviceLocator.search-party-token
                    """
                ),
                dismissButton: Alert.Button.okay())
        case .invalidSearchPartyToken:
            return Alert(
                title: Text("Invalid search party token"),
                message: Text(
                    """
                    The request returned an empty result, this is probably due to an invalid search party token.
                    Please consider updating your search party token in the settings after copying it from the macOS Keychain.
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
        case .nrfDeployFailed:
            return Alert(
                title: Text("Could not deploy"),
                message: Text(self.scriptOutput ?? "Unknown Error"),
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
        case .downloadingReportsFailed:
            return Alert(
                title: Text("Downloading locations failed"),
                message: Text("We could not download any locations from Apple. Please try again later"),
                dismissButton: Alert.Button.okay())
        case .exportFailed:
            return Alert(
                title: Text("Export failed"),
                message: Text("Please check that no the folder is writable and that you have the most current version of the app"),
                dismissButton: .okay())
        case .importFailed:
            return Alert(
                title: Text("Import failed"),
                message: Text("Could not import the selected file. Please make sure it has not been modified and that you have the current version of the app."),
                dismissButton: .okay())
        }
    }

    enum AlertType: Int, Identifiable, Error {
        var id: Int {
            return self.rawValue
        }

        case keyError
        case searchPartyToken
        case invalidSearchPartyToken
        case deployFailed
        case nrfDeployFailed
        case deployedSuccessfully
        case deletionFailed
        case noReportsFound
        case downloadingReportsFailed
        case activatePlugin
        case pluginInstallFailed
        case exportFailed
        case importFailed
    }

}

struct OpenHaystackMainView_Previews: PreviewProvider {
    static var accessoryController = AccessoryControllerPreview(accessories: PreviewData.accessories, findMyController: FindMyController()) as AccessoryController

    static var previews: some View {
        OpenHaystackMainView()
            .environmentObject(self.accessoryController)
    }
}

extension Alert.Button {
    static func okay() -> Alert.Button {
        Alert.Button.default(Text("Okay"))
    }
}

extension TimeInterval {
    var description: String {
        var value = 0
        var unit = Units.second
        Units.allCases.forEach { u in
            if self.rounded() >= u.rawValue {
                value = Int((self / u.rawValue).rounded())
                unit = u
            }
        }
        return "\(value) \(unit.description)\(value > 1 ? "s" : "")"
    }

    enum Units: Double, CaseIterable {
        case second = 1
        case minute = 60
        case hour = 3600
        case day = 86400
        case week = 604800

        var description: String {
            switch self {
            case .second: return "Second"
            case .minute: return "Minute"
            case .hour: return "Hour"
            case .day: return "Day"
            case .week: return "Week"
            }
        }
    }
}
