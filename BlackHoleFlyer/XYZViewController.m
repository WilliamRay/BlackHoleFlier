//
//  XYZViewController.m
//  BlackHoleFlyer
//
//  Created by William Ray on 01/08/2014.
//  Copyright (c) 2014 Roger Ray. All rights reserved.
//

#import "XYZViewController.h"
#import "XYZMyScene.h"

@interface  XYZViewController()

@property BOOL gameCenterEnabled;
@property NSString *leaderboardIdentifier;
@property(nonatomic, retain) NSMutableDictionary *achievementsDictionary;
@property ADBannerView *bannerView;
@property BOOL bannerHidden;

@end

@implementation XYZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self authenticateLocalPlayer];
    _achievementsDictionary = [[NSMutableDictionary alloc] init];
    _bannerHidden = NO;
    
    // Configure the view.
    SKView * skView = (SKView *)self.view;
    //skView.showsFPS = YES;
    //skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    SKScene * scene = [[XYZMyScene alloc] initWithSize:skView.bounds.size andReplay:NO];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
    
    [self setupAd];
}

-(void)setupAd {
    _bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    _bannerView.delegate = self;
    _bannerView.hidden = YES;
    [_bannerView sizeToFit];
    [self.view addSubview:_bannerView];
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if ((banner.isBannerLoaded) && (!_bannerHidden)) {
        banner.hidden = NO;
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (!banner.isBannerLoaded) {
        banner.hidden = YES;
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)authenticateLocalPlayer{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil) {
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else{
            if ([GKLocalPlayer localPlayer].authenticated) {
                _gameCenterEnabled = YES;
                
                [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
                    
                    if (error != nil) {
                        NSLog(@"%@", [error localizedDescription]);
                    }
                    else{
                        _leaderboardIdentifier = leaderboardIdentifier;
                    }
                }];
                [self loadAchievements];
            }
            
            else{
                _gameCenterEnabled = NO;
            }
        }
    };
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(reportScore:)
     name:@"ReportScore"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(showLeaderboard:)
     name:@"DisplayLeaderboard"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(displayAd:)
     name:@"DisplayAd"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(hideAd:)
     name:@"HideAd"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(showAchievements:)
     name:@"DisplayAchievements"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(reportAchievements:)
     name:@"ReportAchievements"
     object:nil];
}

-(void)reportScore:(NSNotification *) notification {
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *score = (NSNumber *)[userInfo objectForKey:@"score"];
    GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier: @"blackhole_Flier_Leaderboard"];
    scoreReporter.value = [score longLongValue];;
    scoreReporter.context = 0;
    
    NSArray *scores = @[scoreReporter];
    [GKScore reportScores:scores withCompletionHandler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

- (void)showLeaderboard:(NSNotification *)notification
{
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
        gameCenterController.leaderboardIdentifier = @"blackhole_Flier_Leaderboard";
        [self presentViewController: gameCenterController animated: YES completion:nil];
    }
}

-(void)showAchievements:(NSNotification *)notification {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateAchievements;
        [self presentViewController: gameCenterController animated: YES completion:nil];
    }
}

-(void)reportAchievements:(NSNotification *)notification {
    if (_gameCenterEnabled) {
        NSDictionary *userInfo = [notification userInfo];
        NSArray *achievementIdentifiers = (NSArray *)[userInfo objectForKey:@"identifier"];
        NSArray *progress = (NSArray *)[userInfo objectForKey:@"progress"];
        NSMutableArray *achievements  = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < progress.count; i++) {
            GKAchievement *achievement = [self getAchievementForIdentifier:achievementIdentifiers[i]];
            if (achievement.percentComplete != 100) {
                achievement.percentComplete = [progress[i] doubleValue];
                achievement.showsCompletionBanner = YES;
                [achievements addObject:achievement];
            }
        }
        
        if (achievements != nil) {
            [GKAchievement reportAchievements:achievements withCompletionHandler:^(NSError *error) {
                if (error != nil) {
                    NSLog(@"%@", [error localizedDescription]);
                    
                }
            }];
        }
    }
    
}

-(void)loadAchievements {
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error)
     {
         if (error == nil)
         {
             for (GKAchievement* achievement in achievements)
                 [_achievementsDictionary setObject: achievement forKey: achievement.identifier];
         }
     }];
}

-(GKAchievement *)getAchievementForIdentifier:(NSString*) identifier {
    GKAchievement *achievement = [_achievementsDictionary objectForKey:identifier];
    if (achievement == nil)
    {
        achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
        [_achievementsDictionary setObject:achievement forKey:achievement.identifier];
    }
    return achievement;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)displayAd:(NSNotification *)notification
{
    if (_bannerView.isBannerLoaded) {
    _bannerView.hidden = NO;
    _bannerHidden = NO;
    }
}

- (void)hideAd:(NSNotification *)notification
{
    _bannerView.hidden = YES;
    _bannerHidden = YES;
}

@end
