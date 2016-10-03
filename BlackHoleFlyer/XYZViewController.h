//
//  XYZViewController.h
//  BlackHoleFlyer
//

//  Copyright (c) 2014 Roger Ray. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <GameKit/GameKit.h>
#import <iAd/iAd.h>

@interface XYZViewController : UIViewController <GKGameCenterControllerDelegate, ADBannerViewDelegate>

-(void)authenticateLocalPlayer;

@end
