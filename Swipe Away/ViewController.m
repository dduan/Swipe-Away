//
//  ViewController.m
//  Swipe Away
//
//  Created by Daniel Duan on 5/5/14.
//  Copyright (c) 2014 Daniel Duan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGesture;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) CGPoint imageCenter;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  self.animator = [[UIDynamicAnimator alloc] initWithReferenceView: self.view];
  self.imageCenter = self.image.center;
  [self resetImage: self];
}

- (IBAction)resetImage: (id)sender {
  UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:self.image snapToPoint:self.imageCenter];
  [self.animator addBehavior:snap];
}
- (IBAction)handlePan:(UIPanGestureRecognizer *)gesture
{
  static UIAttachmentBehavior *attachment;
  static CGPoint               startCenter;
  
  // variables for calculating angular velocity
  
  static CFAbsoluteTime        lastTime;
  static CGFloat               lastAngle;
  static CGFloat               angularVelocity;
  static const CGFloat         threshHold = 140;
  
  if (gesture.state == UIGestureRecognizerStateBegan)
  {
    [self.animator removeAllBehaviors];
    
    startCenter = gesture.view.center;
    
    // calculate the center offset and anchor point
    
    CGPoint pointWithinAnimatedView = [gesture locationInView:gesture.view];
    
    UIOffset offset = UIOffsetMake(pointWithinAnimatedView.x - gesture.view.bounds.size.width / 2.0,
                                   pointWithinAnimatedView.y - gesture.view.bounds.size.height / 2.0);
    
    CGPoint anchor = [gesture locationInView:gesture.view.superview];
    
    // create attachment behavior
    
    attachment = [[UIAttachmentBehavior alloc] initWithItem:gesture.view
                                           offsetFromCenter:offset
                                           attachedToAnchor:anchor];
    
    // code to calculate angular velocity (seems curious that I have to calculate this myself, but I can if I have to)
    
    lastTime = CFAbsoluteTimeGetCurrent();
    lastAngle = [self angleOfView:gesture.view];
    
    attachment.action = ^{
      CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
      CGFloat angle = [self angleOfView:gesture.view];
      if (time > lastTime) {
        angularVelocity = (angle - lastAngle) / (time - lastTime);
        lastTime = time;
        lastAngle = angle;
      }
    };
    
    // add attachment behavior
    
    [self.animator addBehavior:attachment];
  }
  else if (gesture.state == UIGestureRecognizerStateChanged)
  {
    // as user makes gesture, update attachment behavior's anchor point, achieving drag 'n' rotate
    
    CGPoint anchor = [gesture locationInView:gesture.view.superview];
    attachment.anchorPoint = anchor;
  }
  else if (gesture.state == UIGestureRecognizerStateEnded)
  {
    [self.animator removeAllBehaviors];
    
    CGPoint velocity = [gesture velocityInView:gesture.view.superview];
    
    // if we aren't dragging it fast enough, just snap it back and quit

    if (fabs(velocity.x) < threshHold && fabs(velocity.y) < threshHold) {
      UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:gesture.view snapToPoint:startCenter];
      [self.animator addBehavior:snap];
      return;
    }
    // otherwise, create UIDynamicItemBehavior that carries on animation from where the gesture left off (notably linear and angular velocity)
    gesture.enabled = NO;
    UIDynamicItemBehavior *dynamic = [[UIDynamicItemBehavior alloc] initWithItems:@[gesture.view]];
    [dynamic addLinearVelocity:velocity forItem:gesture.view];
    [dynamic addAngularVelocity:angularVelocity forItem:gesture.view];
    [dynamic setAngularResistance:2];
    
    // when the view no longer intersects with its superview, go ahead and remove it
    
    dynamic.action = ^{
      if (!CGRectIntersectsRect(gesture.view.superview.bounds, gesture.view.frame)) {
        [self.animator removeAllBehaviors];
        gesture.enabled = YES;
      }
    };
    [self.animator addBehavior:dynamic];
    
    // add a little gravity so it accelerates off the screen (in case user gesture was slow)
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[gesture.view]];
    CGVector direction = {velocity.x, velocity.y};
    [gravity setGravityDirection: direction];
    gravity.magnitude = 0.7;
    [self.animator addBehavior:gravity];
  }
}

- (CGFloat)angleOfView:(UIView *)view
{
  // http://stackoverflow.com/a/2051861/1271826
  
  return atan2(view.transform.b, view.transform.a);
}
@end
