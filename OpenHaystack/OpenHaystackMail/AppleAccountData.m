//
//  AppleAccountData.m
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

#import "AppleAccountData.h"
#import "ALTAnisetteData.h"

@implementation AppleAccountData

- (instancetype)initWithMachineID:(NSString *)machineID
                  oneTimePassword:(NSString *)oneTimePassword
                      localUserID:(NSString *)localUserID
                      routingInfo:(unsigned long long)routingInfo
           deviceUniqueIdentifier:(NSString *)deviceUniqueIdentifier
               deviceSerialNumber:(NSString *)deviceSerialNumber
                deviceDescription:(NSString *)deviceDescription
                             date:(NSDate *)date
                           locale:(NSLocale *)locale
                         timeZone:(NSTimeZone *)timeZone {

    self = [super init];
    if (self) {
        _machineID = [machineID copy];
        _oneTimePassword = [oneTimePassword copy];
        _localUserID = [localUserID copy];
        _routingInfo = routingInfo;

        _deviceUniqueIdentifier = [deviceUniqueIdentifier copy];
        _deviceSerialNumber = [deviceSerialNumber copy];
        _deviceDescription = [deviceDescription copy];

        _date = [date copy];
        _locale = [locale copy];
        _timeZone = [timeZone copy];
        _searchPartyToken = nil;
    }

    return self;
}

- (instancetype)initFromALTAnissetteData:(ALTAnisetteData *)altAnisetteData {
    self = [super init];

    if (self) {
        _machineID = [altAnisetteData.machineID copy];
        _oneTimePassword = [altAnisetteData.oneTimePassword copy];
        _localUserID = [altAnisetteData.localUserID copy];
        _routingInfo = altAnisetteData.routingInfo;

        _deviceUniqueIdentifier = [altAnisetteData.deviceUniqueIdentifier copy];
        _deviceSerialNumber = [altAnisetteData.deviceSerialNumber copy];
        _deviceDescription = [altAnisetteData.deviceDescription copy];

        _date = [altAnisetteData.date copy];
        _locale = [altAnisetteData.locale copy];
        _timeZone = [altAnisetteData.timeZone copy];
        _searchPartyToken = nil;
    }

    return self;
}

#pragma mark - NSObject -

- (NSString *)description {
    return [NSString stringWithFormat:@"Machine ID: %@\nOne-Time Password: %@\nLocal User ID: %@\nRouting Info: %@\nDevice UDID: %@\nDevice Serial Number: %@\nDevice Description: "
                                      @"%@\nDate: %@\nLocale: %@\nTime Zone: %@ Search Party token %@",
                                      self.machineID, self.oneTimePassword, self.localUserID, @(self.routingInfo), self.deviceUniqueIdentifier, self.deviceSerialNumber,
                                      self.deviceDescription, self.date, self.locale.localeIdentifier, self.timeZone, self.searchPartyToken];
}

- (BOOL)isEqual:(id)object {
    AppleAccountData *anisetteData = (AppleAccountData *)object;
    if (![anisetteData isKindOfClass:[AppleAccountData class]]) {
        return NO;
    }

    BOOL isEqual = ([self.machineID isEqualToString:anisetteData.machineID] && [self.oneTimePassword isEqualToString:anisetteData.oneTimePassword] &&
                    [self.localUserID isEqualToString:anisetteData.localUserID] && [@(self.routingInfo) isEqualToNumber:@(anisetteData.routingInfo)] &&
                    [self.deviceUniqueIdentifier isEqualToString:anisetteData.deviceUniqueIdentifier] &&
                    [self.deviceSerialNumber isEqualToString:anisetteData.deviceSerialNumber] && [self.deviceDescription isEqualToString:anisetteData.deviceDescription] &&
                    [self.date isEqualToDate:anisetteData.date] && [self.locale isEqual:anisetteData.locale] && [self.timeZone isEqualToTimeZone:anisetteData.timeZone]);
    return isEqual;
}

- (NSUInteger)hash {
    return (self.machineID.hash ^ self.oneTimePassword.hash ^ self.localUserID.hash ^ @(self.routingInfo).hash ^ self.deviceUniqueIdentifier.hash ^ self.deviceSerialNumber.hash ^
            self.deviceDescription.hash ^ self.date.hash ^ self.locale.hash ^ self.searchPartyToken.hash ^ self.timeZone.hash);
    ;
}

#pragma mark - <NSCopying> -

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    AppleAccountData *copy = [[AppleAccountData alloc] initWithMachineID:self.machineID
                                                         oneTimePassword:self.oneTimePassword
                                                             localUserID:self.localUserID
                                                             routingInfo:self.routingInfo
                                                  deviceUniqueIdentifier:self.deviceUniqueIdentifier
                                                      deviceSerialNumber:self.deviceSerialNumber
                                                       deviceDescription:self.deviceDescription
                                                                    date:self.date
                                                                  locale:self.locale
                                                                timeZone:self.timeZone];

    return copy;
}

#pragma mark - <NSSecureCoding> -

- (instancetype)initWithCoder:(NSCoder *)decoder {
    NSString *machineID = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(machineID))];
    NSString *oneTimePassword = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(oneTimePassword))];
    NSString *localUserID = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(localUserID))];
    NSNumber *routingInfo = [decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(routingInfo))];

    NSString *deviceUniqueIdentifier = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(deviceUniqueIdentifier))];
    NSString *deviceSerialNumber = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(deviceSerialNumber))];
    NSString *deviceDescription = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(deviceDescription))];

    NSDate *date = [decoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(date))];
    NSLocale *locale = [decoder decodeObjectOfClass:[NSLocale class] forKey:NSStringFromSelector(@selector(locale))];
    NSTimeZone *timeZone = [decoder decodeObjectOfClass:[NSTimeZone class] forKey:NSStringFromSelector(@selector(timeZone))];

    NSData *searchPartyToken = [decoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(searchPartyToken))];

    self = [self initWithMachineID:machineID
                   oneTimePassword:oneTimePassword
                       localUserID:localUserID
                       routingInfo:[routingInfo unsignedLongLongValue]
            deviceUniqueIdentifier:deviceUniqueIdentifier
                deviceSerialNumber:deviceSerialNumber
                 deviceDescription:deviceDescription
                              date:date
                            locale:locale
                          timeZone:timeZone];

    self.searchPartyToken = searchPartyToken;

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.machineID forKey:NSStringFromSelector(@selector(machineID))];
    [encoder encodeObject:self.oneTimePassword forKey:NSStringFromSelector(@selector(oneTimePassword))];
    [encoder encodeObject:self.localUserID forKey:NSStringFromSelector(@selector(localUserID))];
    [encoder encodeObject:@(self.routingInfo) forKey:NSStringFromSelector(@selector(routingInfo))];

    [encoder encodeObject:self.deviceUniqueIdentifier forKey:NSStringFromSelector(@selector(deviceUniqueIdentifier))];
    [encoder encodeObject:self.deviceSerialNumber forKey:NSStringFromSelector(@selector(deviceSerialNumber))];
    [encoder encodeObject:self.deviceDescription forKey:NSStringFromSelector(@selector(deviceDescription))];

    [encoder encodeObject:self.date forKey:NSStringFromSelector(@selector(date))];
    [encoder encodeObject:self.locale forKey:NSStringFromSelector(@selector(locale))];
    [encoder encodeObject:self.timeZone forKey:NSStringFromSelector(@selector(timeZone))];
    [encoder encodeObject:self.searchPartyToken forKey:NSStringFromSelector(@selector(searchPartyToken))];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
