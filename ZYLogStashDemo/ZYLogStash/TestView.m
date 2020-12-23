//
//  TestView.m
//  ZYLogStash
//
//  Created by 吴鹏举 on 2020/12/17.
//

#import "TestView.h"

@interface TestView ()

//@property (nonatomic, strong)

@end

@implementation TestView

- (instancetype)init{
    self = [super init];
    if (self) {
        
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesAction:)];
        [self addGestureRecognizer:tapGes];
        
        UILongPressGestureRecognizer *longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressgesAction:)];
        longPressGes.minimumPressDuration = 1.0f;
        [self addGestureRecognizer:longPressGes];
        
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesAction:)];
        [self addGestureRecognizer:panGes];
        [tapGes requireGestureRecognizerToFail:longPressGes];
//
    }
    return self;
}

- (void)tapGesAction:(UIGestureRecognizer *)tapGes{
    NSLog(@"点击");
}

- (void)longPressgesAction:(UIGestureRecognizer *)longPressGes{
    if (longPressGes.state == UIGestureRecognizerStateChanged) {
        
        UIWindow *window ;//= [UIApplication sharedApplication].delegate.window;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        window = windowScene.windows.firstObject;
                    }
                }
            };
        }
        if (window) {
            CGPoint point = [longPressGes locationInView:self];
            NSLog(@"当前点 == %@", NSStringFromCGPoint(point));
        }
    }
}

- (void)panGesAction:(UIGestureRecognizer *)panGes{
    NSLog(@"平移");
}

- (void)drawRect:(CGRect)rect{
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);//设置颜色有很多方法，我觉得这个方法最好用
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetFillColorWithColor(context, [UIColor purpleColor].CGColor);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineCap(context, kCGLineCapButt);
    
    BOOL showRect = NO;
    if (showRect) {
        // 分割线
        CGMutablePathRef linePath = CGPathCreateMutable();
        NSInteger lineNum = 5;
        BOOL isHorizon = NO;
        CGFloat lineInterval = isHorizon?CGRectGetHeight(rect)/(lineNum+1):CGRectGetWidth(rect)/(lineNum+1);
        for (NSInteger idx = 0; idx < lineNum; idx++) {
            CGFloat lineCenterX = lineInterval*(idx+1);
            if (isHorizon) {
                CGPathMoveToPoint(linePath, &CGAffineTransformIdentity, 0, lineCenterX);
                CGPathAddLineToPoint(linePath, &CGAffineTransformIdentity, CGRectGetWidth(rect), lineCenterX);
            } else {
                CGPathMoveToPoint(linePath, &CGAffineTransformIdentity, lineCenterX, 0);
                CGPathAddLineToPoint(linePath, &CGAffineTransformIdentity, lineCenterX, CGRectGetHeight(rect));
            }
        }
        CGContextAddPath(context, linePath);
        CGContextStrokePath(context);
        // 框
        CGFloat cornerRadius = 5.0f;
        CGFloat insets = 1.0f;
        CGRect drawRect=CGRectMake(insets, insets, CGRectGetWidth(rect)-insets*2, CGRectGetHeight(rect)-insets*2);
        CGContextSetLineWidth(context, 1.0f);
        CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:drawRect
                                                              cornerRadius:cornerRadius];
        CGContextAddPath(context, bezierPath.CGPath);
        CGContextStrokePath(context);
    } else {
        // 分割线
        CGMutablePathRef linePath = CGPathCreateMutable();
        CGPathMoveToPoint(linePath, &CGAffineTransformIdentity, 0, CGRectGetMidY(rect));
        CGPathAddLineToPoint(linePath, &CGAffineTransformIdentity, CGRectGetMaxX(rect), CGRectGetMidY(rect));
        CGPathMoveToPoint(linePath, &CGAffineTransformIdentity, CGRectGetMidX(rect), 0);
        CGPathAddLineToPoint(linePath, &CGAffineTransformIdentity, CGRectGetMidX(rect), CGRectGetMaxY(rect));
        CGContextAddPath(context, linePath);
        CGContextStrokePath(context);
        // 圆
        CGFloat insets = 1.0f;
        CGContextSetLineWidth(context, 1.0f);
        CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
                                                                  radius:CGRectGetMidX(rect)-insets
                                                              startAngle:0
                                                                endAngle:M_PI*2
                                                               clockwise:YES];
        CGContextAddPath(context, bezierPath.CGPath);
        CGContextStrokePath(context);
    }
}

@end
