#import <objc/runtime.h>
/*
#define kTweakName @"Grams"
#ifdef DEBUG
    #define NSLog(FORMAT, ...) NSLog(@"[%@: %s - %i] %@", kTweakName, __FILE__, __LINE__, [NSString stringWithFormat:FORMAT, ##__VA_ARGS__])
#else
    #define NSLog(FORMAT, ...) do {} while(0)
#endif */

#import <UIKit/UIKit.h>
#include <objc/runtime.h>

@interface SBCCMediaControlsSectionController : UIViewController
- (NSString *)sectionIdentifier;
- (CGSize)contentSizeForOrientation:(long)arg1;
@end
@interface SBControlCenterContentView : UIView
@end

@interface GRMDashedLineView : UIView
@end

@implementation GRMDashedLineView
-(id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _addBorder];
    }
    return self;
}
-(void)_addBorder {
    //border definitions
    CGFloat cornerRadius = 0;
    CGFloat borderWidth = 1;
    NSInteger dashPattern1 = 4;
    NSInteger dashPattern2 = 4;
    UIColor *lineColor = [UIColor blackColor];

    //drawing
    CGRect frame = self.bounds;

    CAShapeLayer *_shapeLayer = [CAShapeLayer layer];

    //creating a path
    CGMutablePathRef path = CGPathCreateMutable();

    //drawing a border around a view
    CGPathMoveToPoint(path, NULL, 0, frame.size.height - cornerRadius);
    CGPathAddLineToPoint(path, NULL, 0, cornerRadius);
    CGPathAddArc(path, NULL, cornerRadius, cornerRadius, cornerRadius, M_PI, -M_PI_2, NO);
    CGPathAddLineToPoint(path, NULL, frame.size.width - cornerRadius, 0);
    CGPathAddArc(path, NULL, frame.size.width - cornerRadius, cornerRadius, cornerRadius, -M_PI_2, 0, NO);
    CGPathAddLineToPoint(path, NULL, frame.size.width, frame.size.height - cornerRadius);
    CGPathAddArc(path, NULL, frame.size.width - cornerRadius, frame.size.height - cornerRadius, cornerRadius, 0, M_PI_2, NO);
    CGPathAddLineToPoint(path, NULL, cornerRadius, frame.size.height);
    CGPathAddArc(path, NULL, cornerRadius, frame.size.height - cornerRadius, cornerRadius, M_PI_2, M_PI, NO);

    //path is set as the _shapeLayer object's path
    _shapeLayer.path = path;
    CGPathRelease(path);

    _shapeLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _shapeLayer.frame = frame;
    _shapeLayer.masksToBounds = NO;
    [_shapeLayer setValue:[NSNumber numberWithBool:NO] forKey:@"isCircle"];
    _shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    _shapeLayer.strokeColor = [lineColor CGColor];
    _shapeLayer.lineWidth = borderWidth;
    _shapeLayer.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInt:dashPattern1], [NSNumber numberWithInt:dashPattern2], nil];
    _shapeLayer.lineCap = kCALineCapRound;

    //_shapeLayer is added as a sublayer of the view, the border is visible
    [self.layer addSublayer:_shapeLayer];
    self.layer.cornerRadius = cornerRadius;
}
@end

@interface GRMScaleView : UIView
@property (nonatomic, retain) UILabel *weightLabel;
- (void)updateWithForce:(CGFloat)force;
@end

@implementation GRMScaleView
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _weightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 20)];
        [_weightLabel setCenter:[self center]];
        [_weightLabel setText:@"Place object here"];
        [_weightLabel setTextAlignment:NSTextAlignmentCenter];
        [_weightLabel setTextColor:[UIColor darkGrayColor]];
        [self addSubview:_weightLabel];
    }
    return self;
}
- (void)updateWithForce:(CGFloat)force {
    CGFloat convertedForce = ((force/6.6666666675) * 385);
    NSLog(@"convertedForce: %f", convertedForce);

    [_weightLabel setText:[NSString stringWithFormat:@"%.2f grams", convertedForce]];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
/*
    [UIView animateWithDuration:0.25 animations:^{
        _weightLabel.alpha = 0.0;
    } completion:^(BOOL finished){
*/
        UITouch* touch = [touches anyObject];
        [self updateWithForce:touch.force];
/*
        [UIView animateWithDuration:0.5 animations:^{
            _weightLabel.alpha = 1.0;
        }];
    }];
*/
}
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    [self updateWithForce:touch.force];
}
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent *)event {
    [self resetForNextUse];
}
-(void)resetForNextUse {
    [UIView animateWithDuration:0.25 animations:^{
        _weightLabel.alpha = 0.0;
    } completion:^(BOOL finished){
        [_weightLabel setText:@"Place object here"];

        [UIView animateWithDuration:0.5 animations:^{
            _weightLabel.alpha = 1.0;
        }];
    }];
}
@end

@interface SBControlCenterContentView (GRMExtensions)
@property (nonatomic, retain, setter=grams_setAssociatedMediaControlsSectionController:) SBCCMediaControlsSectionController* grams_associatedMediaControlsSectionController;
@end


static int lastOrientation = [[UIDevice currentDevice] orientation];

%hook SBCCMediaControlsSectionController

- (CGSize)contentSizeForOrientation:(long)arg1 {

    CGSize originalSize = %orig;

    if (arg1 == 4 || arg1 == 3)
        return CGSizeMake(originalSize.width, originalSize.height - 90);

    return originalSize;
}

%end

%hook SBControlCenterContentView
- (NSMutableArray*)_allSections {
    NSMutableArray* sections = %orig;

    NSInteger index = 2;
    for (id section in sections) {
        if ([section isKindOfClass:%c(SBCCMediaControlsSectionController)]) {
            index = [sections indexOfObject:section] + 1;
            break;
        }
    }

    if (!self.grams_associatedMediaControlsSectionController || (lastOrientation != [[UIDevice currentDevice] orientation] && self.grams_associatedMediaControlsSectionController)) {
        SBCCMediaControlsSectionController* sectionController = [[%c(SBCCMediaControlsSectionController) alloc] init];

        CGSize contentSize = [sectionController contentSizeForOrientation:[[UIDevice currentDevice] orientation]];
        [[sectionController view] setFrame:CGRectMake(0, 0, contentSize.width, contentSize.height)];

        [[[sectionController view] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if ([[[self.grams_associatedMediaControlsSectionController view] subviews] count] > 0)
            [[[self.grams_associatedMediaControlsSectionController view] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

        lastOrientation = [[UIDevice currentDevice] orientation];
        CGFloat scaleWidth = (lastOrientation == 4 || lastOrientation == 3) ? [[UIScreen mainScreen] bounds].size.width - 250 : [[UIScreen mainScreen] bounds].size.width;
        
        GRMScaleView* scaleView = [[GRMScaleView alloc] initWithFrame:CGRectMake(0, 0, scaleWidth, contentSize.height)];
        [scaleView setBackgroundColor:[UIColor clearColor]];

        GRMDashedLineView* dashedLineView = [[GRMDashedLineView alloc] initWithFrame:CGRectInset(scaleView.frame, 15, 15)];
        [dashedLineView setBackgroundColor:[UIColor clearColor]];
        [dashedLineView setUserInteractionEnabled:NO];
        [scaleView addSubview:dashedLineView];

        [[sectionController view] addSubview:scaleView];

        self.grams_associatedMediaControlsSectionController = sectionController;
    }

    [sections insertObject:self.grams_associatedMediaControlsSectionController atIndex:index];

    return sections;
}
%new
-(void)grams_setAssociatedMediaControlsSectionController:(id)sectionController {
     objc_setAssociatedObject(self, @selector(grams_associatedMediaControlsSectionController), sectionController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
-(id)grams_associatedMediaControlsSectionController {
    return objc_getAssociatedObject(self, @selector(grams_associatedMediaControlsSectionController));
}
%end
