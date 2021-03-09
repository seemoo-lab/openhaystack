//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import CryptoKit
import XCTest

@testable import OpenHaystack

class OpenHaystackTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testAnisetteDataFromAltStore() throws {
        let manager = AnisetteDataManager.shared

        let expect = self.expectation(description: "Anisette data fetched")
        manager.requestAnisetteData { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                print("Accessed anisette data \(data.description)")
            }
            expect.fulfill()
        }

        self.wait(for: [expect], timeout: 3.0)

    }

    func testKeyGeneration() throws {
        let key = BoringSSL.generateNewPrivateKey()!

        XCTAssertNotEqual(key, Data(repeating: 0, count: 28))
    }

    func testDerivePublicKey() throws {
        let privateKey = BoringSSL.generateNewPrivateKey()!
        let publicKeyBytes = BoringSSL.derivePublicKey(fromPrivateKey: privateKey)

        XCTAssertNotNil(publicKeyBytes)

    }

    func testGetPublicKey() throws {
        let accessory = try Accessory(name: "Some item")
        let publicKey = try accessory.getAdvertisementKey()
        XCTAssertEqual(publicKey.count, 28)

        XCTAssertNotEqual(publicKey, Data(repeating: 0, count: 28))
        XCTAssertNotEqual(publicKey, accessory.privateKey)
    }

    func testStoreAccessories() throws {
        let accessory = try Accessory(name: "Test accessory")
        try KeychainController.storeInKeychain(accessories: [accessory], test: true)
        let fetchedAccessories = KeychainController.loadAccessoriesFromKeychain(test: true)
        XCTAssertEqual(accessory, fetchedAccessories[0])

        // Add an accessory
        let updatedAccessories = fetchedAccessories + [try Accessory(name: "Test 2")]
        try KeychainController.storeInKeychain(accessories: updatedAccessories, test: true)

        let fetchedAccessories2 = KeychainController.loadAccessoriesFromKeychain(test: true)
        XCTAssertEqual(updatedAccessories, fetchedAccessories2)

        // Remove the accessories
        try KeychainController.storeInKeychain(accessories: [], test: true)
    }

    func testKeyIDGeneration() throws {
        // Import keys with their respective id from a plist
        let plist = try Data(contentsOf: Bundle(for: Self.self).url(forResource: "sampleKeys", withExtension: "plist")!)
        let devices = try PropertyListDecoder().decode([FindMyDevice].self, from: plist)

        let keys = devices.first!.keys
        for key in keys {
            let publicKey = key.advertisedKey
            var sha = SHA256()
            sha.update(data: publicKey)
            let digest = sha.finalize()
            let hashedKey = Data(digest)

            XCTAssertEqual(key.hashedKey, hashedKey)
        }

    }

    func testECDHWithPublicKey() throws {
        let receivedAccessory = try Accessory(name: "test")
        let receivedPublicKey = try receivedAccessory.getActualPublicKey()

        // Generate ephemeral key pair by using a second accessory
        let ephAccessory = try Accessory(name: "Ephemeral Key")
        let ephPrivate = ephAccessory.privateKey
        let ephPublicKey = try ephAccessory.getActualPublicKey()

        // Now we need a ECDH key exchange
        // In the first round ephemeral key is the public key
        let sharedKey = BoringSSL.deriveSharedKey(fromPrivateKey: ephPrivate, andEphemeralKey: receivedPublicKey)!
        XCTAssertNotNil(sharedKey)

        // Now we follow the standard key derivation used in OF
        let derivedKey = DecryptReports.kdf(fromSharedSecret: sharedKey, andEphemeralKey: ephPublicKey)
        // Let's encrypt some test string
        let message = "This is a message that should be encrypted"
        let messageData = message.data(using: .ascii)!

        let encryptionKey = derivedKey.subdata(in: derivedKey.startIndex..<16)
        let encryptionIV = derivedKey.subdata(in: 16..<derivedKey.endIndex)

        let sealed = try AES.GCM.seal(messageData, using: SymmetricKey(data: encryptionKey), nonce: .init(data: encryptionIV))

        // Now we decrypt it by performing it the other way around

        // ECDH with public ephemeral and private received key

        let sharedKey2 = BoringSSL.deriveSharedKey(fromPrivateKey: receivedAccessory.privateKey, andEphemeralKey: ephPublicKey)!
        XCTAssertNotNil(sharedKey2)
        XCTAssertEqual(sharedKey2, sharedKey)

        // Decrypt to see if we get the same text
        let derivedKey2 = DecryptReports.kdf(fromSharedSecret: sharedKey2, andEphemeralKey: ephPublicKey)
        XCTAssertEqual(derivedKey2, derivedKey)

        let decryptionKey = derivedKey2.subdata(in: derivedKey2.startIndex..<16)
        let decryptionIV = derivedKey2.subdata(in: 16..<derivedKey2.endIndex)
        XCTAssertEqual(decryptionIV, encryptionIV)
        XCTAssertEqual(decryptionKey, encryptionKey)

        let decryptedMessage = try AES.GCM.open(sealed, using: SymmetricKey(data: decryptionKey))
        XCTAssertEqual(decryptedMessage, messageData)
        let decryptedText = String(data: decryptedMessage, encoding: .ascii)
        XCTAssertEqual(message, decryptedText)

    }

    func testGenerateKeyPair() {
        let keyData = BoringSSL.generateNewPrivateKey()
        XCTAssertNotNil(keyData)
    }

    func testPluginInstallation() {
        do {
            let pluginManager = MailPluginManager()
            if pluginManager.isMailPluginInstalled {
                try pluginManager.uninstallMailPlugin()
            }
            try pluginManager.installMailPlugin()

            XCTAssert(FileManager.default.fileExists(atPath: pluginManager.pluginURL.path))

        } catch {
            XCTFail(String(describing: error))
        }
    }
}
