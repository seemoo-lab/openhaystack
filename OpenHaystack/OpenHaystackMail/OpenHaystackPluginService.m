//
//  ALTPluginService.m
//  AltPlugin
//
//  Created by Riley Testut on 11/14/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

#import "OpenHaystackPluginService.h"

#import <dlfcn.h>

#import "AppleAccountData.h"
#import <Accounts/Accounts.h>
#import <Security/Security.h>

@import AppKit;

@interface AKAppleIDSession : NSObject
- (id)appleIDHeadersForRequest:(id)arg1;
@end

@interface AKDevice
+ (AKDevice *)currentDevice;
- (NSString *)uniqueDeviceIdentifier;
- (NSString *)serialNumber;
- (NSString *)serverFriendlyDescription;
@end

@interface OpenHaystackPluginService ()

@property(nonatomic, readonly) NSISO8601DateFormatter *dateFormatter;

@end

@implementation OpenHaystackPluginService

+ (instancetype)sharedService {
    static OpenHaystackPluginService *_service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      _service = [[self alloc] init];
    });

    return _service;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    }

    return self;
}

+ (void)initialize {
    [[OpenHaystackPluginService sharedService] start];
}

- (void)start {
    dlopen("/System/Library/PrivateFrameworks/AuthKit.framework/AuthKit", RTLD_NOW);

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(receiveNotification:)
                                                            name:@"de.tu-darmstadt.seemoo.OpenHaystack.FetchAnisetteData"
                                                          object:nil];
}

- (void)receiveNotification:(NSNotification *)notification {
    NSString *requestUUID = notification.userInfo[@"requestUUID"];

    NSMutableURLRequest *req =
        [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"https://developerservices2.apple.com/services/QH65B2/listTeams.action?clientId=XABBG36SBA"]];
    [req setHTTPMethod:@"POST"];

    AKAppleIDSession *session = [[NSClassFromString(@"AKAppleIDSession") alloc] initWithIdentifier:@"com.apple.gs.xcode.auth"];
    NSDictionary *headers = [session appleIDHeadersForRequest:req];

    AKDevice *device = [NSClassFromString(@"AKDevice") currentDevice];
    NSDate *date = [self.dateFormatter dateFromString:headers[@"X-Apple-I-Client-Time"]];

    NSData *sptoken = [self fetchSearchpartyToken];
    AppleAccountData *anisetteData = [[NSClassFromString(@"AppleAccountData") alloc] initWithMachineID:headers[@"X-Apple-I-MD-M"]
                                                                                       oneTimePassword:headers[@"X-Apple-I-MD"]
                                                                                           localUserID:headers[@"X-Apple-I-MD-LU"]
                                                                                           routingInfo:[headers[@"X-Apple-I-MD-RINFO"] longLongValue]
                                                                                deviceUniqueIdentifier:device.uniqueDeviceIdentifier
                                                                                    deviceSerialNumber:device.serialNumber
                                                                                     deviceDescription:device.serverFriendlyDescription
                                                                                                  date:date
                                                                                                locale:[NSLocale currentLocale]
                                                                                              timeZone:[NSTimeZone localTimeZone]];
    if (sptoken != nil) {
        anisetteData.searchPartyToken = [sptoken copy];
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:anisetteData requiringSecureCoding:YES error:nil];

    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"de.tu-darmstadt.seemoo.OpenHaystack.AnisetteDataResponse"
                                                                   object:nil
                                                                 userInfo:@{@"requestUUID" : requestUUID, @"anisetteData" : data}
                                                       deliverImmediately:YES];
}

- (NSData *_Nullable)fetchSearchpartyToken {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.account.AppleAccount"];

    NSArray *appleAccounts = [accountStore accountsWithAccountType:accountType];

    if (appleAccounts == nil && appleAccounts.count > 0) {
        return nil;
    }

    ACAccount *iCloudAccount = appleAccounts[0];
    ACAccountCredential *iCloudCredentials = iCloudAccount.credential;

    if ([iCloudCredentials respondsToSelector:NSSelectorFromString(@"credentialItems")]) {
        NSDictionary *credentialItems = [iCloudCredentials performSelector:NSSelectorFromString(@"credentialItems")];
        NSString *searchPartyToken = credentialItems[@"search-party-token"];
        NSData *tokenData = [searchPartyToken dataUsingEncoding:NSASCIIStringEncoding];
        return tokenData;
    }

    return nil;
}

@end
