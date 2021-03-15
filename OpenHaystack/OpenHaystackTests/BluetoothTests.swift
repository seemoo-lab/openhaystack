//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import CoreBluetooth
import XCTest

@testable import OpenHaystack

class BluetoothTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNoManufacturerData() throws {
        let data: [String: Any] = [
            "": Data()
        ]
        let adv = Advertisement(fromAdvertisementData: data)
        XCTAssertNil(adv)
    }

    func testEmptyManufacturerData() throws {
        let data: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: Data()
        ]
        let adv = Advertisement(fromAdvertisementData: data)
        XCTAssertNil(adv)
    }

    func testCorrectAdvertisement() throws {
        let publicKey = "11111111111111111111111111111111111111111111".hexaData
        let data = "4c00121900111111111111111111111111111111111111111111110100".hexaData
        let adv = Advertisement(fromManufacturerData: data)
        XCTAssertNotNil(adv)
        XCTAssertEqual(adv?.publicKeyPayload, publicKey)
    }
}

extension StringProtocol {
    var hexaData: Data { .init(hexa) }
    var hexaBytes: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}
