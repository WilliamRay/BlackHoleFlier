//
//  XYZMyScene.m
//  BlackHoleFlyer
//
//  Created by William Ray on 01/08/2014.
//  Copyright (c) 2014 Roger Ray. All rights reserved.
//

#import "XYZMyScene.h"
#import "XYZGameOverScene.h"
#import <CoreMotion/CoreMotion.h>
#import <GameKit/GameKit.h>

@interface XYZMyScene () <SKPhysicsContactDelegate> {
    int lastDirection;
}

@property (strong) CMMotionManager *motionManager;
@property float spaceshipWidth;
@property NSMutableArray *xPositions;
@property NSInteger leftHoleCount;
@property NSInteger score;
@property SKLabelNode *scoreLabel;
@property BOOL isStarted;

@end

typedef NS_OPTIONS(uint32_t, CollisionCategory) {
    CollisionCategoryShip = 0x1 << 1,
    CollisionCategoryBlackhole = 0x1 << 2,
    CollisionCategoryWorld = 0x1 << 3,
    CollisionCategoryScorer = 0x1 << 4
};
float speed;
static const float speedConst = 100;

@implementation XYZMyScene

-(id)initWithSize:(CGSize)size andReplay:(BOOL)replay {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        SKAction *preload = [SKAction playSoundFileNamed:@"point.caf" waitForCompletion:NO];
        
        
        //Create the background
        SKTexture *background = [SKTexture textureWithImageNamed:@"background"];
        float duration;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            duration = (background.size.height/speedConst)/2;
        }
        else {
            duration = background.size.height/speedConst;
        }
        SKAction *moveBackground = [SKAction moveByX:0 y:-background.size.height*2 duration:duration];
        speed = (background.size.height*2) / duration;
        SKAction *resetBackground = [SKAction moveByX:0 y:background.size.height*2 duration:0];
        SKAction *moveBackgroundForever = [SKAction repeatActionForever:[SKAction sequence:@[moveBackground, resetBackground]]];
        self.physicsWorld.contactDelegate = self;
        
        for(int i = 0; i < 3 + self.frame.size.height/(background.size.height * 2); ++i ) {
            SKSpriteNode* backgroundSprite = [SKSpriteNode spriteNodeWithTexture:background];
            backgroundSprite.position = CGPointMake(backgroundSprite.size.width / 2, i * backgroundSprite.size.height);
            [backgroundSprite runAction:moveBackgroundForever];
            [self addChild:backgroundSprite];
        }
    }
    self.xPositions = [NSMutableArray new];
    
    SKSpriteNode *spaceship = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    spaceship.zPosition = 10;
    spaceship.name = @"ship";
    spaceship.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) * 0.5);
    spaceship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(spaceship.frame.size.width/2, spaceship.frame.size.height)];
    spaceship.physicsBody.dynamic = YES;
    spaceship.physicsBody.affectedByGravity = NO;
    spaceship.physicsBody.mass = 0.02;
    spaceship.physicsBody.allowsRotation = NO;
    spaceship.physicsBody.categoryBitMask = CollisionCategoryShip;
    spaceship.physicsBody.contactTestBitMask = CollisionCategoryBlackhole | CollisionCategoryScorer | CollisionCategoryWorld;
    spaceship.physicsBody.collisionBitMask = CollisionCategoryWorld;
    self.spaceshipWidth = spaceship.frame.size.width;
    [self addChild:spaceship];
    
    if (replay) {
        [self beginGame];
    } else {
        SKSpriteNode *startButton = [SKSpriteNode spriteNodeWithImageNamed:@"startButton"];
        startButton.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)*1.2);
        startButton.name = @"start";
        [self addChild:startButton];
        self.isStarted = NO;
        
        SKSpriteNode *leaderBoardButton = [SKSpriteNode spriteNodeWithImageNamed:@"leaderboardButton"];
        leaderBoardButton.position = CGPointMake(leaderBoardButton.size.width*0.85, leaderBoardButton.size.height*0.85);
        leaderBoardButton.name = @"leaderboard";
        [self addChild:leaderBoardButton];
        
        SKSpriteNode *achievementButton = [SKSpriteNode spriteNodeWithImageNamed:@"achievementButton"];
        achievementButton.position = CGPointMake(CGRectGetMaxX(self.frame)-(achievementButton.size.width*0.85), (achievementButton.size.height*0.85));
        achievementButton.name = @"achievement";
        [self addChild:achievementButton];
        
        
    }
    
    return self;
}


-(void)showTutorial {
    BOOL shownTutorial = [[NSUserDefaults standardUserDefaults] boolForKey:@"shownTutorial"];
    
    if (!shownTutorial) {
        SKLabelNode *tutorialLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        tutorialLabel.text = @"Tilt to avoid the blackholes!";
        tutorialLabel.fontSize = [self returnFontSize:20];
        tutorialLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        tutorialLabel.zPosition = 100;
        [self addChild:tutorialLabel];
        
        SKAction *wait = [SKAction waitForDuration:2];
        SKAction *dissapear = [SKAction fadeAlphaTo:0 duration:1.5];
        SKAction *grow = [SKAction scaleBy:2 duration:1.5];
        SKAction *sequenceGrow = [SKAction sequence:@[wait, grow]];
        SKAction *sequenceDissapear = [SKAction sequence:@[wait, dissapear]];
        [tutorialLabel runAction:sequenceDissapear];
        [tutorialLabel runAction:sequenceGrow];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shownTutorial"];
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    if (contact.bodyA.categoryBitMask == CollisionCategoryBlackhole) {
        [self gameOver:contact.bodyA.node.position];
    } else if (contact.bodyB.categoryBitMask == CollisionCategoryBlackhole) {
        [self gameOver:contact.bodyB.node.position];
    }
    
    if ((contact.bodyA.categoryBitMask == CollisionCategoryScorer) || (contact.bodyB.categoryBitMask == CollisionCategoryScorer)) {
        _score ++;
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"muteSound"]) {
            SKAction *play = [SKAction playSoundFileNamed:@"point.caf" waitForCompletion:NO];
            [self runAction:play];
        }
        if (([contact.bodyA.node.name isEqualToString:@"double"] || [contact.bodyB.node.name isEqualToString:@"double"])) {
            _score ++;
            [self reportAchievementsWithDouble:YES];
        } else {
            [self reportAchievementsWithDouble:NO];
        }
        _scoreLabel.text = [NSString stringWithFormat:@"Score: %li", (long)_score];
    }
    
    if ((contact.bodyA.categoryBitMask == CollisionCategoryWorld) || (contact.bodyB.categoryBitMask == CollisionCategoryWorld)) {
        float force = 6;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            force = force * 1.5;
        }
        if (contact.bodyA.categoryBitMask == CollisionCategoryShip) {
            
            if (contact.contactPoint.x < 10) {
                [contact.bodyA applyImpulse:CGVectorMake(force, 0)];
            } else {
                [contact.bodyA applyImpulse:CGVectorMake(-force, 0)];
            }
        } else {
            if (contact.contactPoint.x < 10) {
                [contact.bodyB applyImpulse:CGVectorMake(force, 0)];
            } else {
                [contact.bodyB applyImpulse:CGVectorMake(-force, 0)];
            }
        }
    }
}

-(void)reportAchievementsWithDouble:(BOOL)isDouble {
    NSArray *identifiers = @[@"double_black_hole",@"50_black_holes", @"40_black_holes", @"30_black_holes", @"20_black_holes", @"10_black_holes", @"5_black_holes"];
    NSMutableArray *progress = [[NSMutableArray alloc] init];
    if (isDouble) {
        [progress addObject:[NSNumber numberWithDouble:100]];
    } else {
        [progress addObject:[NSNumber numberWithDouble:0]];
    }
    [progress addObject:[NSNumber numberWithDouble:_score*100/50]];
    [progress addObject:[NSNumber numberWithDouble:_score*100/40]];
    [progress addObject:[NSNumber numberWithDouble:_score*100/30]];
    [progress addObject:[NSNumber numberWithDouble:_score*100/20]];
    [progress addObject:[NSNumber numberWithDouble:_score*100/10]];
    [progress addObject:[NSNumber numberWithDouble:_score*100/5]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[identifiers, progress] forKeys:@[@"identifier", @"progress"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportAchievements" object:self userInfo:userInfo];
}

-(void)beginGame {
    _motionManager = [[CMMotionManager alloc] init];
    [_motionManager startAccelerometerUpdates];
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody.categoryBitMask = CollisionCategoryWorld;
    
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"MarkerFelt-Thin"];
    _scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame)*0.75);
    _scoreLabel.fontSize = [self returnFontSize:28];
    _scoreLabel.fontColor = [SKColor whiteColor];
    _scoreLabel.zPosition = 100;
    _scoreLabel.text = @"Score: 0";
    [self addChild:_scoreLabel];
    
    SKAction *addBlackhole = [SKAction performSelector:@selector(addBlackHole) onTarget:self];
    SKAction *waitBlackhole = [SKAction waitForDuration:1.8];
    SKAction *sequence = [SKAction sequence:@[addBlackhole, waitBlackhole]];
    SKAction *addBlackholesForever = [SKAction repeatActionForever:sequence];
    [self runAction:addBlackholesForever];
    _isStarted = YES;
    
    SKSpriteNode *spaceship = (SKSpriteNode *)[self childNodeWithName:@"ship"];
    SKEmitterNode *rocketJets = [SKEmitterNode nodeWithFileNamed:@"RocketJets"];
    rocketJets.zRotation = M_PI;
    rocketJets.position = CGPointMake(-spaceship.size.width * 0.1, -spaceship.size.height * 0.4);
    [spaceship addChild:rocketJets];
    SKEmitterNode *rocketJets2 = [SKEmitterNode nodeWithFileNamed:@"RocketJets"];
    rocketJets2.zRotation = M_PI;
    rocketJets2.position = CGPointMake(spaceship.size.width * 0.1, -spaceship.size.height * 0.4);
    [spaceship addChild:rocketJets2];
    
    lastDirection = 0;
}

-(void)processUserMotionForUpdate:(NSTimeInterval)currentTime {
    SKSpriteNode *spaceship = (SKSpriteNode*)[self childNodeWithName:@"ship"];
    CMAccelerometerData *data = _motionManager.accelerometerData;
    if (fabs(data.acceleration.x) > 0.12) {
        [spaceship.physicsBody applyForce:CGVectorMake(30.0 * data.acceleration.x, 0)];
        
        if ((data.acceleration.x < 0) && (lastDirection != -1)) {
            lastDirection = -1;
            [self addSideBoostersWithDirection:-1];
        } else if ((data.acceleration.x > 0) && (lastDirection != 1)) {
            lastDirection = 1;
            [self addSideBoostersWithDirection:1];
        }
    } else {
        [self addSideBoostersWithDirection:0];
        lastDirection = 0;
    }
    [self enumerateChildNodesWithName:@"blackhole" usingBlock:^(SKNode *blackhole, BOOL *stop){
        float deltaX = blackhole.position.x - spaceship.position.x;
        float deltaY = blackhole.position.y - spaceship.position.y;
        float distance = sqrtf((deltaX*deltaX) + (deltaY * deltaY));
        if (blackhole.position.y < 0 - blackhole.frame.size.height/2) {
            [blackhole removeFromParent];
            NSNumber *x = [NSNumber numberWithInt:blackhole.position.x];
            [_xPositions removeObject:x];
        }
        if ((distance < self.frame.size.width*0.8) && (deltaX > 0)) {
            [spaceship.physicsBody applyForce:CGVectorMake(9, 0)];
        } else if ((distance < self.frame.size.width*0.75) && (deltaX < 0)) {
            [spaceship.physicsBody applyForce:CGVectorMake(-9, 0)];
        }
    }];
}

-(void)addSideBoostersWithDirection:(int)direction {
    SKSpriteNode *spaceship = (SKSpriteNode *)[self childNodeWithName:@"ship"];
    [[spaceship childNodeWithName:@"sideBooster"] removeFromParent];
    [[spaceship childNodeWithName:@"sideBooster2"] removeFromParent];
    [[spaceship childNodeWithName:@"sideBooster3"] removeFromParent];
    
    if (direction != 0) {
        SKEmitterNode *sideBooster = [SKEmitterNode nodeWithFileNamed:@"SideBoosters"];
        sideBooster.position = CGPointMake((-spaceship.size.width/2)*direction, 0);
        sideBooster.zRotation = (M_PI/2)*direction;
        sideBooster.name = @"sideBooster";
        [spaceship addChild:sideBooster];
        SKEmitterNode *sideBooster2 = [SKEmitterNode nodeWithFileNamed:@"SideBoosters"];
        sideBooster2.position = CGPointMake((-spaceship.size.width/2)*direction, -spaceship.size.height/5);
        sideBooster2.zRotation = (M_PI/2)*direction;
        sideBooster2.name = @"sideBooster2";
        [spaceship addChild:sideBooster2];
        SKEmitterNode *sideBooster3 = [SKEmitterNode nodeWithFileNamed:@"SideBoosters"];
        sideBooster3.position = CGPointMake((-spaceship.size.width/4)*direction, spaceship.size.height/4);
        sideBooster3.zRotation = (M_PI/2)*direction;
        sideBooster3.name = @"sideBooster3";
        [spaceship addChild:sideBooster3];
    }
}

-(void)addBlackHole {
    BOOL isDouble = NO;
    
    SKSpriteNode *blackhole = [self createBlackHole];
    [self addChild:blackhole];
    
    if (arc4random() %10 == 0) {
        int yCoord = CGRectGetMaxY(self.frame)+ blackhole.size.width;
        SKSpriteNode *blackhole2 = [self createBlackHole];
        [self addChild:blackhole2];
        int xOffSet = arc4random_uniform(blackhole.size.width/4);
        blackhole.position = CGPointMake(CGRectGetMaxX(self.frame) + xOffSet - blackhole.size.width/2, yCoord);
        blackhole2.position = CGPointMake(xOffSet + blackhole.size.width/2, yCoord);
        isDouble = YES;
    } else {
        blackhole.position = [self blackholePositionWithWidth:blackhole.size.width];
    }
    
    
    int scorerY = blackhole.position.y + 7*blackhole.size.width/8;
    SKAction *scorerMove = [SKAction moveByX:0 y:-(self.frame.size.height + blackhole.size.height*2) duration:(self.frame.size.height + blackhole.size.height*2)/speed];
    [self addBlackHoleScorerWithYCoord:scorerY andMove:scorerMove isDouble:isDouble];
}

-(SKSpriteNode *)createBlackHole {
    SKSpriteNode *blackhole = [SKSpriteNode spriteNodeWithImageNamed:@"blackhole"];
    blackhole.name = @"blackhole";
    blackhole.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:blackhole.size.width/2];
    blackhole.physicsBody.categoryBitMask = CollisionCategoryBlackhole;
    blackhole.physicsBody.collisionBitMask = 0;
    blackhole.physicsBody.dynamic = NO;
    
    SKAction *moveBlackhole = [SKAction moveByX:0 y:-(self.frame.size.height + blackhole.size.height*2) duration:(self.frame.size.height + blackhole.size.height*2)/speed];
    SKAction *rotateBlackhole = [SKAction repeatActionForever:[SKAction rotateByAngle:M_PI duration:7]];
    [blackhole runAction:moveBlackhole];
    [blackhole runAction:rotateBlackhole];
    
    return blackhole;
}

-(void)addBlackHoleScorerWithYCoord:(int)yCoord andMove:(SKAction *)move isDouble:(BOOL)isDouble {
    CGSize size = CGSizeMake(self.frame.size.width, 1);
    SKNode *blackholeScorer = [SKNode new];
    blackholeScorer.position = CGPointMake(CGRectGetMidX(self.frame), yCoord);
    blackholeScorer.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:size];
    blackholeScorer.physicsBody.categoryBitMask = CollisionCategoryScorer;
    blackholeScorer.physicsBody.collisionBitMask = 0;
    blackholeScorer.physicsBody.dynamic = NO;
    if (isDouble) {
        blackholeScorer.name = @"double";
    }
    [self addChild:blackholeScorer];
    [blackholeScorer runAction:move];
}

-(CGPoint)blackholePositionWithWidth:(float)width {
    BOOL addSpaceship = NO;
    int newBlackholeX = arc4random_uniform(CGRectGetMaxX(self.frame) - width) + width/2;
    CGPoint position = CGPointMake(newBlackholeX, CGRectGetMaxY(self.frame)+ width);
    
    while (!addSpaceship) {
        if (_xPositions.count > 0) {
            
            for (NSNumber *x in _xPositions) {
                int xPosition = [x intValue];
                int deltaX = xPosition - newBlackholeX;
                
                if (abs(deltaX) > width) {
                    addSpaceship = YES;
                }
            }
            if (!addSpaceship) {
                newBlackholeX = arc4random_uniform(CGRectGetMaxX(self.frame) - width) + width/2;
                position = CGPointMake(newBlackholeX, position.y);
            }
        } else {
            addSpaceship = YES;
        }
    }
    
    [_xPositions addObject:[NSNumber numberWithInt:newBlackholeX]];
    
    return position;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    [self processUserMotionForUpdate:currentTime];
}

-(void)gameOver:(CGPoint)blackholeLocation {
    float waitDuration = 1;
    [self removeAllActions];
    for (SKNode *node in self.children) {
        [node removeAllActions];
    }
    
    SKAction * rotate = [SKAction rotateByAngle:M_1_PI*2 duration:0.1];
    SKAction * shrink = [SKAction scaleTo:0 duration:waitDuration];
    SKAction * move = [SKAction moveTo:blackholeLocation duration:waitDuration];
    SKAction * wait = [SKAction waitForDuration:waitDuration];
    SKAction * runGameOver = [SKAction runBlock:^(void){
        [self loadGameOverScreen];
    }];
    SKAction *waitRun = [SKAction sequence:@[wait, runGameOver]];
    
    SKSpriteNode *spaceship = (SKSpriteNode *)[self childNodeWithName:@"ship"];
    [spaceship runAction:shrink];
    [spaceship runAction:move];
    [spaceship runAction:[SKAction repeatActionForever:rotate]];
    spaceship.physicsBody.dynamic = NO;
    [self runAction:waitRun];
}

-(void)loadGameOverScreen {
    SKView *skView = self.view;
    SKScene * scene = [[XYZGameOverScene alloc] initWithSize:self.size andScore:_score];
    SKTransition *transition = [SKTransition fadeWithDuration:2];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    [skView presentScene:scene transition:transition];
}

-(int)returnFontSize:(int)fontSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return fontSize * 2;
    }
    else {
        return fontSize;
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!_isStarted) {
        UITouch *touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInNode:self];
        for (SKNode *node in [self nodesAtPoint:touchLocation]) {
            if ([node.name isEqualToString:@"start"]) {
                [node removeFromParent];
                [[self childNodeWithName:@"startLabel"] removeFromParent];
                [[self childNodeWithName:@"leaderboard"] removeFromParent];
                [[self childNodeWithName:@"achievement"] removeFromParent];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"HideAd" object:self];
                [self showTutorial];
                [self beginGame];
            } else if ([node.name isEqualToString:@"leaderboard"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayLeaderboard" object:self];
            } else if ([node.name isEqualToString:@"achievement"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayAchievements" object:self];
            }
            
        }
    }
}

@end
