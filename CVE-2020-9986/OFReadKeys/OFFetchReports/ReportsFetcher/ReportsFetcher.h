//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

#import <Foundation/Foundation.h>
//https://github.com/Matchstic/ReProvision/issues/96#issuecomment-551928795
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

@interface AKAppleIDSession : NSObject
- (id)_pairedDeviceAnisetteController;
- (id)_nativeAnisetteController;
- (void)_handleURLResponse:(id)arg1 forRequest:(id)arg2 withCompletion:(id)arg3;
- (void)_generateAppleIDHeadersForSessionTask:(id)arg1 withCompletion:(id)arg2;
- (id)_generateAppleIDHeadersForRequest:(id)arg1 error:(id)arg2;
- (id)_genericAppleIDHeadersDictionaryForRequest:(id)arg1;
- (void)handleResponse:(id)arg1 forRequest:(id)arg2 shouldRetry:(char *)arg3;
- (id)appleIDHeadersForRequest:(id)arg1;
- (void)URLSession:(id)arg1 task:(id)arg2 getAppleIDHeadersForResponse:(id)arg3 completionHandler:(id)arg4;
- (id)relevantHTTPStatusCodes;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (id)initWithIdentifier:(id)arg1;
- (id)init;

@end

@interface AKDevice
+ (AKDevice *)currentDevice;
- (NSString *)uniqueDeviceIdentifier;
- (NSString *)serialNumber;
- (NSString *)serverFriendlyDescription;
@end



@interface ReportsFetcher : NSObject

/// WARNING: Runs synchronous network request. Please run this in a background thread.
/// Query location reports for an array of public key hashes (ids)
/// @param publicKeys Array of hashed public keys (in Base64)
/// @param date Start date
/// @param duration Duration checked
/// @param searchPartyToken Search Party token
/// @param completion Called when finished
- (void) queryForHashes:(NSArray *)publicKeys startDate: (NSDate *) date duration: (double) duration searchPartyToken:(nonnull NSData *)searchPartyToken completion: (void (^)(NSData* _Nullable)) completion;

/// Fetches the search party token from the macOS Keychain. Returns null if it fails 
- (NSData * _Nullable) fetchSearchpartyToken;

/// Get AnisetteData from AuthKit or return an empty dictionary
- (NSDictionary *_Nonnull) anisetteDataDictionary;

@end

NS_ASSUME_NONNULL_END
