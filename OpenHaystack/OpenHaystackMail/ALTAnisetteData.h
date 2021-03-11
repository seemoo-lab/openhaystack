//
//  ALTAnisetteData.h
//  AltSign
//
//  Created by Riley Testut on 11/13/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
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

@interface ALTAnisetteData : NSObject <NSCopying, NSSecureCoding>

@property(nonatomic, copy) NSString *machineID;
@property(nonatomic, copy) NSString *oneTimePassword;
@property(nonatomic, copy) NSString *localUserID;
@property(nonatomic) unsigned long long routingInfo;

@property(nonatomic, copy) NSString *deviceUniqueIdentifier;
@property(nonatomic, copy) NSString *deviceSerialNumber;
@property(nonatomic, copy) NSString *deviceDescription;

@property(nonatomic, copy) NSDate *date;
@property(nonatomic, copy) NSLocale *locale;
@property(nonatomic, copy) NSTimeZone *timeZone;

- (instancetype)initWithMachineID:(NSString *)machineID
                  oneTimePassword:(NSString *)oneTimePassword
                      localUserID:(NSString *)localUserID
                      routingInfo:(unsigned long long)routingInfo
           deviceUniqueIdentifier:(NSString *)deviceUniqueIdentifier
               deviceSerialNumber:(NSString *)deviceSerialNumber
                deviceDescription:(NSString *)deviceDescription
                             date:(NSDate *)date
                           locale:(NSLocale *)locale
                         timeZone:(NSTimeZone *)timeZone;

@end

NS_ASSUME_NONNULL_END
