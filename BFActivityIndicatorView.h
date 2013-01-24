//
//	BFActivityIndicatorView.h
//
//	Created by Basil Shkara on 17/07/12.
//	Copyright (c) 2012 Neat.io. All rights reserved.
//
//  Port of UIActivityIndicatorView from the Chameleon project: https://github.com/BigZaphod/Chameleon

#import <Cocoa/Cocoa.h>

typedef enum {
	BFActivityIndicatorViewStyleWhiteLarge,
	BFActivityIndicatorViewStyleWhite,
	BFActivityIndicatorViewStyleGray,
} BFActivityIndicatorViewStyle;

@interface BFActivityIndicatorView : NSView

@property (assign) BOOL hidesWhenStopped;
@property (assign) BFActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (assign) NSUInteger numberOfTeeth;
@property (assign) CGFloat toothWidth;
@property (assign) CGFloat toothHeight;
@property (assign) CGFloat animationDuration;
@property (copy) NSColor *color;

- (id)initWithActivityIndicatorStyle:(BFActivityIndicatorViewStyle)style;
- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end
