//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BoringSSL : NSObject

+ (NSData *_Nullable)deriveSharedKeyFromPrivateKey:(NSData *)privateKey andEphemeralKey:(NSData *)ephemeralKeyPoint;

/// Derive a public key from a given private key
/// @param privateKeyData an EC private key on the P-224 curve
/// @returns The public key in a compressed format using 29 bytes. The first byte is used for identifying if its odd or even.
/// For OF the first byte has to be dropped
+ (NSData *_Nullable)derivePublicKeyFromPrivateKey:(NSData *)privateKeyData;

/// Derive a public key from a given private key
/// @param privateKeyData an EC private key on the P-224 curve
/// @returns The public key in a uncompressed format using 28*2+1 bytes. The first byte is used for identifying if its odd or even.
+ (NSData *_Nullable)deriveUncompressedPublicKeyFromPrivateKey:(NSData *)privateKeyData ;

/// Generate a new EC private key and exports it as data
+ (NSData *_Nullable)generateNewPrivateKey;

/// Calculate private key from derived data
+ (NSData *_Nullable)calculatePrivateKeyFromSharedData:(NSData *)sharedData masterBeaconPrivateKey:(NSData *)masterBeaconPrivateKey;

@end

NS_ASSUME_NONNULL_END
