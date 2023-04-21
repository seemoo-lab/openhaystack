//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import XCTest

@testable import OpenHaystack

class UpdateCheckTests: XCTestCase {

    func testCompareVersions() {
        let i1 = "1.0.3"
        let a1 = "1.0.4"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a1, installedVersion: i1), .older)
        let a11 = "1.1"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a11, installedVersion: i1), .older)
        let a12 = "2"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a12, installedVersion: i1), .older)

        let a2 = "1.0.3"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a2, installedVersion: i1), .same)

        let a3 = "1.0.2"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a3, installedVersion: i1), .newer)
        let a31 = "1.0"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a31, installedVersion: i1), .newer)
        let a32 = "0.10.1"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a32, installedVersion: i1), .newer)

        let a4 = "1.1.1"
        let i4 = "1.1.2"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a4, installedVersion: i4), .newer)
        let a41 = "1.0.2"
        XCTAssertEqual(UpdateCheckController.compareVersions(availableVersion: a41, installedVersion: i1), .newer)
    }

    func testHTMLVersionCompare() {
        let github =
            """
            <h1 data-view-component="true" class="d-inline mr-3"><a href="/seemoo-lab/openhaystack/releases/tag/v0.4.1" data-view-component="true" class="Link--primary">Release v0.4.1</a></h1>
            <h1 data-view-component="true" class="d-inline mr-3"><a href="/seemoo-lab/openhaystack/releases/tag/v0.4.1" data-view-component="true" class="Link--primary">Release v0.4.1</a></h1>
            <a href="/seemoo-lab/openhaystack/releases/tag/v0.4.1" data-view-component="true" class="Link--primary">Release v0.4.1</a>
            """

        XCTAssertEqual(UpdateCheckController.getVersion(from: github), "0.4.1")

        let h1 = "<h1>Release v0.4.1</h1> <h1>Release v0.3.1</h1>"
        XCTAssertEqual(UpdateCheckController.getVersion(from: h1), "0.4.1")
        let h2 = "<h1>Release v0.5</h1>"
        XCTAssertEqual(UpdateCheckController.getVersion(from: h2), "0.5")
        let h3 = "<h1>Release v1.5</h1>"
        XCTAssertEqual(UpdateCheckController.getVersion(from: h3), "1.5")
        let h4 = "<h1>Release v1</h1>"
        XCTAssertEqual(UpdateCheckController.getVersion(from: h4), "1")
    }

    func testDownload() {
        let expect = expectation(description: "Update download")
        UpdateCheckController.downloadUpdate(
            version: "0.4.1",
            finished: { success in
                XCTAssertTrue(success)
                expect.fulfill()
            })
        wait(for: [expect], timeout: 20.0)

    }
}
