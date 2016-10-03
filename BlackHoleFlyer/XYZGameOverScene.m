 //
//  XYZGameOverScene.m
//  BlackHoleFlyer
//
//  Created by William Ray on 03/10/2014.
//  Copyright (c) 2014 Roger Ray. All rights reserved.
//

#import "XYZGameOverScene.h"
#import "XYZMyScene.h"
#import "XYZViewController.h"
#import <GameKit/GameKit.h>


@implementation XYZGameOverScene

-(id)initWithSize:(CGSize)size andScore:(NSInteger)score {
    if (self = [super initWithSize:size]) {
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild:background];
        
        SKSpriteNode *gameOverButton = [SKSpriteNode spriteNodeWithImageNamed:@"buttonRetry"];
        gameOverButton.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) *0.8);
        gameOverButton.name = @"retry";
        [self addChild:gameOverButton];        
        
        SKLabelNode *gameOver = [SKLabelNode labelNodeWithFontNamed:@"MarkerFelt-Wide"];
        gameOver.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame)*0.8);
        gameOver.fontColor = [SKColor whiteColor];
        gameOver.fontSize = [self returnFontSize:35];
        gameOver.text = @"Game Over";
        [self addChild:gameOver];
        
        SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"MarkerFelt-Thin"];
        scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)*1.3);
        scoreLabel.fontColor = [SKColor whiteColor];
        scoreLabel.text = [NSString stringWithFormat:@"Score: %li", (long)score];
        scoreLabel.fontSize = [self returnFontSize:25];
        [self addChild:scoreLabel];
        
        SKLabelNode *highScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"MarkerFelt-Thin"];
        highScoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), scoreLabel.position.y - (scoreLabel.fontSize*1.6));
        highScoreLabel.fontColor = [SKColor whiteColor];
        highScoreLabel.text = [NSString stringWithFormat:@"Best: %li", (long)[self saveHighScore:score]];
        highScoreLabel.fontSize = [self returnFontSize:25];
        [self addChild:highScoreLabel];
        
        //Leaderboard
        SKSpriteNode *leaderBoardButton = [SKSpriteNode spriteNodeWithImageNamed:@"leaderboardButton"];
        leaderBoardButton.position = CGPointMake(leaderBoardButton.size.width*0.85, leaderBoardButton.size.height*0.85);
        leaderBoardButton.name = @"leaderboard";
        [self addChild:leaderBoardButton];
        
        //Achievement
        SKSpriteNode *achievementButton = [SKSpriteNode spriteNodeWithImageNamed:@"achievementButton"];
        achievementButton.position = CGPointMake(CGRectGetMaxX(self.frame)-(achievementButton.size.width*0.85), (achievementButton.size.height*0.85));
        achievementButton.name = @"achievement";
        [self addChild:achievementButton];

    }
    
    return self;
}

-(NSInteger)saveHighScore:(NSInteger)score {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger highScore = [userDefaults integerForKey:@"highscore"];
    
    
    if (!highScore) {
        highScore = score;
        [userDefaults setInteger:score forKey:@"highscore"];
    } else if (highScore < score) {
        highScore = score;
        [userDefaults setInteger:score forKey:@"highscore"];
    }
    
    [userDefaults synchronize];
    [self reportScore:highScore];
    
    return highScore;
}


-(void)didMoveToView:(SKView *)view {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayAd" object:self];
}

- (void)reportScore:(NSInteger)score {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInteger:score]] forKeys:@[@"score"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportScore" object:self userInfo:userInfo];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    for (SKNode *node in [self nodesAtPoint:touchLocation]) {
        if ([node.name isEqualToString:@"retry"]) {
            SKView *skView = self.view;
            SKScene * scene = [[XYZMyScene alloc] initWithSize:skView.frame.size andReplay:YES];
            scene.scaleMode = SKSceneScaleModeAspectFill;
            [skView presentScene:scene];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HideAd" object:self];
        }
        if ([node.name isEqualToString:@"leaderboard"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayLeaderboard" object:self];
        
        } else if ([node.name isEqualToString:@"achievement"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayAchievements" object:self];
            
        }

    }
}

-(int)returnFontSize:(int)fontSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return fontSize * 2;
    }
    else {
        return fontSize;
    }
}

@end
