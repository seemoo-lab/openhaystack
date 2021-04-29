//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

#import "BoringSSL.h"

#include <CNIOBoringSSL.h>
#include <CNIOBoringSSL_ec.h>
#include <CNIOBoringSSL_ec_key.h>
#include <CNIOBoringSSL_evp.h>
#include <CNIOBoringSSL_hkdf.h>
#include <CNIOBoringSSL_pkcs7.h>

@implementation BoringSSL

+ (NSData *_Nullable)deriveSharedKeyFromPrivateKey:(NSData *)privateKey andEphemeralKey:(NSData *)ephemeralKeyPoint {

    NSLog(@"Private key %@", [privateKey base64EncodedStringWithOptions:0]);
    NSLog(@"Ephemeral key %@", [ephemeralKeyPoint base64EncodedStringWithOptions:0]);

    EC_GROUP *curve = EC_GROUP_new_by_curve_name(NID_secp224r1);

    EC_KEY *key = [self deriveEllipticCurvePrivateKey:privateKey group:curve];

    const EC_POINT *genPubKey = EC_KEY_get0_public_key(key);
    [self printPoint:genPubKey withGroup:curve];

    EC_POINT *publicKey = EC_POINT_new(curve);
    size_t load_success = EC_POINT_oct2point(curve, publicKey, ephemeralKeyPoint.bytes, ephemeralKeyPoint.length, NULL);
    if (load_success == 0) {
        NSLog(@"Failed loading public key!");
        return nil;
    }

    NSMutableData *sharedKey = [[NSMutableData alloc] initWithLength:28];

    int res = ECDH_compute_key(sharedKey.mutableBytes, sharedKey.length, publicKey, key, nil);

    if (res < 1) {
        NSLog(@"Failed with error: %d", res);
        BIO *bio = BIO_new(BIO_s_mem());
        ERR_print_errors(bio);
        char *buf;
        BIO_get_mem_data(bio, &buf);
        NSLog(@"Generating shared key failed %s", buf);
        free(buf);
        BIO_free(bio);
    }

    // NSLog(@"Shared key: %@", [sharedKey base64EncodedStringWithOptions:0]);
    //Free
    EC_KEY_free(key);
    EC_GROUP_free(curve);
    EC_POINT_free(publicKey);

    return sharedKey;
}

+ (EC_POINT *_Nullable)loadEllipticCurvePublicBytesWith:(EC_GROUP *)group andPointBytes:(NSData *)pointBytes {

    EC_POINT *point = EC_POINT_new(group);

    // Create big number context
    BN_CTX *ctx = BN_CTX_new();
    BN_CTX_start(ctx);

    // Public key will be stored in point
    int res = EC_POINT_oct2point(group, point, pointBytes.bytes, pointBytes.length, ctx);
    [self printPoint:point withGroup:group];

    // Free the big numbers
    BN_CTX_free(ctx);

    if (res != 1) {
        // Failed
        return nil;
    }

    return point;
}

/// Get the private key on the curve from the private key bytes
/// @param privateKeyData NSData representing the private key
/// @param group The EC group representing the curve to use
+ (EC_KEY *_Nullable)deriveEllipticCurvePrivateKey:(NSData *)privateKeyData group:(EC_GROUP *)group {
    EC_KEY *key = EC_KEY_new_by_curve_name(NID_secp224r1);
    EC_POINT *point = EC_POINT_new(group);

    BN_CTX *ctx = BN_CTX_new();
    BN_CTX_start(ctx);

    // Read in the private key data
    BIGNUM *privateKeyNum = BN_bin2bn(privateKeyData.bytes, privateKeyData.length, nil);
    int res = EC_POINT_mul(group, point, privateKeyNum, nil, nil, ctx);
    
    if (res != 1) {
        NSLog(@"Failed");
        return nil;
    }

    res = EC_KEY_set_public_key(key, point);
    EC_POINT_free(point);
    
    if (res != 1) {
        NSLog(@"Failed");
        return nil;
    }


    EC_KEY_set_private_key(key, privateKeyNum);
    BN_free(privateKeyNum);

    // Free
    BN_CTX_free(ctx);
    
    
    
    return key;
}

/// Derive a public key from a given private key
/// @param privateKeyData an EC private key on the P-224 curve
+ (NSData *_Nullable)derivePublicKeyFromPrivateKey:(NSData *)privateKeyData {
    EC_GROUP *curve = EC_GROUP_new_by_curve_name(NID_secp224r1);
    EC_KEY *key = [self deriveEllipticCurvePrivateKey:privateKeyData group:curve];

    const EC_POINT *publicKey = EC_KEY_get0_public_key(key);

    size_t keySize = 28 + 1;
    NSMutableData *publicKeyBytes = [[NSMutableData alloc] initWithLength:keySize];

    size_t size = EC_POINT_point2oct(curve, publicKey, POINT_CONVERSION_COMPRESSED, publicKeyBytes.mutableBytes, keySize, NULL);

    //Free
    EC_KEY_free(key);
    EC_GROUP_free(curve);
    
    if (size == 0) {
        return nil;
    }

    return publicKeyBytes;
}

+ (NSData *_Nullable)generateNewPrivateKey {
    EC_KEY *key = EC_KEY_new_by_curve_name(NID_secp224r1);
    if (EC_KEY_generate_key_fips(key) == 0) {
        return nil;
    }

    const BIGNUM *privateKey = EC_KEY_get0_private_key(key);
    size_t keySize = BN_num_bytes(privateKey);
    // Convert to bytes
    NSMutableData *privateKeyBytes = [[NSMutableData alloc] initWithLength:keySize];

    size_t size = BN_bn2bin(privateKey, privateKeyBytes.mutableBytes);

    EC_KEY_free(key); 
    if (size == 0) {
        return nil;
    }

    return privateKeyBytes;
}

+ (void)printPoint:(const EC_POINT *)point withGroup:(EC_GROUP *)group {
    NSMutableData *pointData = [[NSMutableData alloc] initWithLength:256];

    size_t len = pointData.length;
    BN_CTX *ctx = BN_CTX_new();
    BN_CTX_start(ctx);
    size_t res = EC_POINT_point2oct(group, point, POINT_CONVERSION_UNCOMPRESSED, pointData.mutableBytes, len, ctx);
    // Free the big numbers
    BN_CTX_free(ctx);

    NSData *written = [[NSData alloc] initWithBytes:pointData.bytes length:res];

    NSLog(@"Point data is: %@", [written base64EncodedStringWithOptions:0]);
}

@end
