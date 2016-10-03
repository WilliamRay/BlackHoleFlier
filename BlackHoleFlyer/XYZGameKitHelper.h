//
//  XYZGameKitHelper.h
//  Blackhole Flyer
//
//  Created by William Ray on 16/10/2014.
//  Copyright (c) 2014 Roger Ray. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

extern NSString *const PresentAuthenticationViewController;

@interface XYZGameKitHelper : NSObject

@property (nonatomic, readonly) UIViewController *authenticationViewController;
@property (nonatomic, readonly) NSError *lastError;

+ (instancetype)sharedGameKitHelper;
- (void)authenticateLocalPlayer;

@end
