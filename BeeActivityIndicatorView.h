//
//	BeeActivityIndicatorView.h
//
//	Created by Basil Shkara on 17/07/12.
//	Copyright (c) 2012 Neat.io. All rights reserved.
//
//  Port of UIActivityIndicatorView from the Chameleon project: https://github.com/BigZaphod/Chameleon

#import <Cocoa/Cocoa.h>

typedef enum {
	BeeActivityIndicatorViewStyleWhiteLarge,
	BeeActivityIndicatorViewStyleWhite,
	BeeActivityIndicatorViewStyleGray,
} BeeActivityIndicatorViewStyle;

@interface BeeActivityIndicatorView : NSView

@property (assign) BOOL hidesWhenStopped;
@property (assign) BeeActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (assign) NSUInteger numberOfTeeth;
@property (assign) CGFloat toothWidth;
@property (assign) CGFloat toothHeight;
@property (assign) CGFloat toothCornerRadius;
@property (assign) CGFloat animationDuration;
@property (copy) NSColor *color;
@property (copy) NSColor *strokeColor;

- (id)initWithActivityIndicatorStyle:(BeeActivityIndicatorViewStyle)style;
- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end
