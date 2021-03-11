//
//  ALTPluginService.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenHaystackPluginService : NSObject

+ (instancetype)sharedService;

@end

NS_ASSUME_NONNULL_END
