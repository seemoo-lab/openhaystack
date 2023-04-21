//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import OSLog

/// Uses the AltStore Mail plugin to access recent anisette data.
public class AnisetteDataManager: NSObject {
    @objc static let shared = AnisetteDataManager()
    private var anisetteDataCompletionHandlers: [String: (Result<AppleAccountData, Error>) -> Void] = [:]
    private var anisetteDataTimers: [String: Timer] = [:]

    private override init() {
        super.init()

        dlopen("/System/Library/PrivateFrameworks/AuthKit.framework/AuthKit", RTLD_NOW)

        DistributedNotificationCenter.default()
            .addObserver(
                self, selector: #selector(AnisetteDataManager.handleAppleDataResponse(_:)),
                name: Notification.Name("de.tu-darmstadt.seemoo.OpenHaystack.AnisetteDataResponse"), object: nil)
    }

    func requestAnisetteData(_ completion: @escaping (Result<AppleAccountData, Error>) -> Void) {
        if let accountData = self.requestAnisetteDataAuthKit() {
            os_log(.debug, "Anisette Data loaded %@", accountData.debugDescription)
            completion(.success(accountData))
            return
        }

        let requestUUID = UUID().uuidString
        self.anisetteDataCompletionHandlers[requestUUID] = completion

        let timer = Timer(timeInterval: 1.0, repeats: false) { (_) in
            self.finishRequest(forUUID: requestUUID, result: .failure(AnisetteDataError.pluginNotFound))
        }
        self.anisetteDataTimers[requestUUID] = timer

        RunLoop.main.add(timer, forMode: .default)

        DistributedNotificationCenter.default()
            .postNotificationName(
                Notification.Name("de.tu-darmstadt.seemoo.OpenHaystack.FetchAnisetteData"),
                object: nil, userInfo: ["requestUUID": requestUUID], options: .deliverImmediately)
    }

    func requestAnisetteDataAuthKit() -> AppleAccountData? {
        let anisetteData = ReportsFetcher().anisetteDataDictionary()

        let dateFormatter = ISO8601DateFormatter()

        guard let machineID = anisetteData["X-Apple-I-MD-M"] as? String,
            let otp = anisetteData["X-Apple-I-MD"] as? String,
            let localUserId = anisetteData["X-Apple-I-MD-LU"] as? String,
            let dateString = anisetteData["X-Apple-I-Client-Time"] as? String,
            let date = dateFormatter.date(from: dateString),
            let deviceClass = NSClassFromString("AKDevice")
        else {
            return nil
        }
        let device: AKDevice = deviceClass.current()

        let routingInfo = (anisetteData["X-Apple-I-MD-RINFO"] as? NSNumber)?.uint64Value ?? 0
        let accountData = AppleAccountData(
            machineID: machineID,
            oneTimePassword: otp,
            localUserID: localUserId,
            routingInfo: routingInfo,
            deviceUniqueIdentifier: device.uniqueDeviceIdentifier(),
            deviceSerialNumber: device.serialNumber(),
            deviceDescription: device.serverFriendlyDescription(),
            date: date,
            locale: Locale.current,
            timeZone: TimeZone.current)

        if let spToken = ReportsFetcher().fetchSearchpartyToken() {
            accountData.searchPartyToken = spToken
        }

        return accountData
    }

    @objc func requestAnisetteDataObjc(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        self.requestAnisetteData { result in
            switch result {
            case .failure:
                completion(nil)
            case .success(let data):
                // Return only the headers
                completion(
                    [
                        "X-Apple-I-MD-M": data.machineID,
                        "X-Apple-I-MD": data.oneTimePassword,
                        "X-Apple-I-TimeZone": String(data.timeZone.abbreviation() ?? "UTC"),
                        //                        "X-Apple-I-Client-Time": ISO8601DateFormatter().string(from: data.date),
                        "X-Apple-I-Client-Time": ISO8601DateFormatter().string(from: Date()),
                        "X-Apple-I-MD-RINFO": String(data.routingInfo),
                    ] as [AnyHashable: Any])
            }
        }
    }
}

extension AnisetteDataManager {

    @objc fileprivate func handleAppleDataResponse(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let requestUUID = userInfo["requestUUID"] as? String else { return }

        if let archivedAnisetteData = userInfo["anisetteData"] as? Data,
            let appleAccountData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: AppleAccountData.self, from: archivedAnisetteData)
        {
            if let range = appleAccountData.deviceDescription.lowercased().range(of: "(com.apple.mail") {
                var adjustedDescription = appleAccountData.deviceDescription[..<range.lowerBound]
                adjustedDescription += "(com.apple.dt.Xcode/3594.4.19)>"

                appleAccountData.deviceDescription = String(adjustedDescription)
            }

            self.finishRequest(forUUID: requestUUID, result: .success(appleAccountData))
        } else {
            self.finishRequest(forUUID: requestUUID, result: .failure(AnisetteDataError.invalidAnisetteData))
        }
    }

    @objc fileprivate func handleAnisetteDataResponse(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let requestUUID = userInfo["requestUUID"] as? String else { return }

        if let archivedAnisetteData = userInfo["anisetteData"] as? Data,
            let anisetteData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ALTAnisetteData.self, from: archivedAnisetteData)
        {
            if let range = anisetteData.deviceDescription.lowercased().range(of: "(com.apple.mail") {
                var adjustedDescription = anisetteData.deviceDescription[..<range.lowerBound]
                adjustedDescription += "(com.apple.dt.Xcode/3594.4.19)>"

                anisetteData.deviceDescription = String(adjustedDescription)
            }

            let appleAccountData = AppleAccountData(fromALTAnissetteData: anisetteData)
            self.finishRequest(forUUID: requestUUID, result: .success(appleAccountData))
        } else {
            self.finishRequest(forUUID: requestUUID, result: .failure(AnisetteDataError.invalidAnisetteData))
        }
    }

    fileprivate func finishRequest(forUUID requestUUID: String, result: Result<AppleAccountData, Error>) {
        let completionHandler = self.anisetteDataCompletionHandlers[requestUUID]
        self.anisetteDataCompletionHandlers[requestUUID] = nil

        let timer = self.anisetteDataTimers[requestUUID]
        self.anisetteDataTimers[requestUUID] = nil

        timer?.invalidate()
        completionHandler?(result)
    }
}

enum AnisetteDataError: Error {
    case pluginNotFound
    case invalidAnisetteData
}
