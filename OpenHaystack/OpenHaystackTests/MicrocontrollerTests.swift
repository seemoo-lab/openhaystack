//
//  MicrocontrollerTests.swift
//  OpenHaystackTests
//
//  Created by Alex - SEEMOO on 09.03.21.
//  Copyright © 2021 SEEMOO - TU Darmstadt. All rights reserved.
//

import XCTest
@testable import OpenHaystack

class MicrocontrollerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMicrobitDeploy() throws {
        let urls = try MicrobitController.findMicrobits()

        if let mBitURL = urls.first {
            let firmware = try Data(contentsOf: Bundle(for: Self.self).url(forResource: "sample", withExtension: "bin")!)
            try MicrobitController.deployToMicrobit(mBitURL, firmwareFile: firmware)
        }
    }

    func testBinaryPatching() throws {
        // Patching sample.bin should fail
        do {
            let firmware = try Data(contentsOf: Bundle(for: Self.self).url(forResource: "sample", withExtension: "bin")!)
            let pattern = Data([0xa, 0xb, 0xc, 0xd, 0xe, 0xf, 0x0, 0x1])
            let key = Data([1, 1, 1, 1, 1, 1, 1, 1])
            _ = try MicrobitController.patchFirmware(firmware, pattern: pattern, with: key)
            XCTFail("Should thrown an erorr before")
        } catch PatchingError.patternNotFound {
            // This should be thrown
        } catch {
            XCTFail("Unexpected error")
        }

        // Patching the sample should be successful
        do {
            let firmware = try Data(contentsOf: Bundle(for: Self.self).url(forResource: "pattern_sample", withExtension: "bin")!)
            let pattern = Data([0xaa, 0xaa, 0xaa, 0xaa, 0xbb, 0xbb, 0xbb, 0xcc])
            let key = Data([1, 1, 1, 1, 1, 1, 1, 1])
            _ = try MicrobitController.patchFirmware(firmware, pattern: pattern, with: key)
        } catch {
            XCTFail("Unexpected error \(String(describing: error))")
        }

        // Patching key too short

        // Patching the sample should be successful
        do {
            let firmware = try Data(contentsOf: Bundle(for: Self.self).url(forResource: "pattern_sample", withExtension: "bin")!)
            let pattern = Data([0xaa, 0xaa, 0xaa, 0xaa, 0xbb, 0xbb, 0xbb, 0xcc])
            let key = Data([1, 1, 1, 1, 1, 1, 1])
            _ = try MicrobitController.patchFirmware(firmware, pattern: pattern, with: key)
        } catch PatchingError.inequalLength {

        } catch {
            XCTFail("Unexpected error \(String(describing: error))")
        }

        // Testing with the actual firmware
        do {
            let firmware = try Data(contentsOf: Bundle(for: Self.self).url(forResource: "offline-finding", withExtension: "bin")!)
            let pattern = "OFFLINEFINDINGPUBLICKEYHERE!".data(using: .ascii)!
            let key = Data(repeating: 0xaa, count: 28)
            _ = try MicrobitController.patchFirmware(firmware, pattern: pattern, with: key)
        } catch PatchingError.inequalLength {

        } catch {
            XCTFail("Unexpected error \(String(describing: error))")
        }

    }

    func testFindESP32Port() {
        let port = ESP32Controller.findPort()
        XCTAssertNotNil(port)
    }

    func testESP32Deploy() throws {
        let accessory = try Accessory(name: "Sample")
        let expect = expectation(description: "ESP32 Flash")
        try ESP32Controller.flashToESP32(accessory: accessory) { result in
            expect.fulfill()
            switch result {
            case .success(_):
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 60.0)
    }

}
