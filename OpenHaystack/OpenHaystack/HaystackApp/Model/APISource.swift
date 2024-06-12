//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

enum APISource {
    static let storageKey = "api_source"
    struct ServerOptions {
        var url: URL?
        var authorizationHeader: String?
        var isProtected: Bool { authorizationHeader != nil }
    }
    
    case mailPlugin
    case reportsServer(ServerOptions)
}

extension APISource: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.mailPlugin, .mailPlugin),
             (.reportsServer, .reportsServer):
            return true
        default:
            return false
        }
    }
}

extension APISource: Hashable {
    private struct MailPluginHash: Hashable {}
    private struct ReportsServerHash: Hashable {}
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .mailPlugin:
            hasher.combine(MailPluginHash())
        case .reportsServer:
            hasher.combine(ReportsServerHash())
        }
    }
}

extension APISource: RawRepresentable {
    private static let separator: Character = "|"
    private static let mailPluginIdenitifier = "mailPlugin"
    private static let reportsServerIdentifier = "reportsServer"
    
    init?(rawValue: String) {
        let components = rawValue.split(separator: APISource.separator)
        guard let rawType = components.first else { return nil }
        switch rawType {
        case APISource.mailPluginIdenitifier:
            self = .mailPlugin
        case APISource.reportsServerIdentifier where components.count == 1:
            self = .reportsServer(.init())
        case APISource.reportsServerIdentifier where components.count == 2:
            self = .reportsServer(.init(url: URL(string: String(components[1]))))
        case APISource.reportsServerIdentifier where components.count == 3:
            self = .reportsServer(.init(url: URL(string: String(components[1])), authorizationHeader: String(components[2])))
        default:
            return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .mailPlugin:
            return APISource.mailPluginIdenitifier
        case .reportsServer(let serverOptions):
            var components: [String] = [APISource.reportsServerIdentifier]
            guard let url = serverOptions.url else { return components.joined(separator: String(APISource.separator)) }
            components.append(url.absoluteString)
            if let authorizationHeader = serverOptions.authorizationHeader {
                components.append(authorizationHeader)
            }
            return components.joined(separator: String(APISource.separator))
        }
    }
}
