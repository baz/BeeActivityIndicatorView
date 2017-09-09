//
//	BeeActivityIndicatorView.m
//
//	Created by Basil Shkara on 17/07/12.
//	Copyright (c) 2012 Neat.io. All rights reserved.
//
//  Port of UIActivityIndicatorView from the Chameleon project: https://github.com/BigZaphod/Chameleon

#import "BeeActivityIndicatorView.h"
#import <QuartzCore/QuartzCore.h>

typedef struct {
	CGFloat toothWidth;
	CGFloat toothHeight;
	CGFloat toothCornerRadius;
} BeeActivityIndicatorToothProperties;

static NSSize BeeActivityIndicatorViewStyleSize(BeeActivityIndicatorViewStyle style) {
	if (style == BeeActivityIndicatorViewStyleWhiteLarge) {
		return NSMakeSize(37, 37);
	} else {
		return NSMakeSize(20, 20);
	}
}

static CGImageRef BeeActivityIndicatorViewFrameImage(BeeActivityIndicatorViewStyle style,
													NSColor *color,
													NSColor *strokeColor,
													NSInteger frameNumber,
													NSInteger numberOfFrames,
													NSUInteger numberOfTeeth,
													NSSize frameSize,
													CGFloat scale,
													BeeActivityIndicatorToothProperties toothProperties) {
	frameSize.width *= scale;
	frameSize.height *= scale;
	toothProperties.toothWidth *= scale;
	toothProperties.toothHeight *= scale;
	toothProperties.toothCornerRadius *= scale;

	const CGFloat radius = frameSize.width / 2.f;
	const CGFloat TWOPI = - M_PI * 2.f;

	NSRect offscreenRect = NSMakeRect(0.0, 0.0, frameSize.width, frameSize.height);
	if (NSEqualRects(offscreenRect, NSZeroRect)) return NULL;

	NSBitmapImageRep *offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																			 pixelsWide:offscreenRect.size.width
																			 pixelsHigh:offscreenRect.size.height
																		  bitsPerSample:8
																		samplesPerPixel:4
																			   hasAlpha:YES
																			   isPlanar:NO
																		 colorSpaceName:NSCalibratedRGBColorSpace
																			bytesPerRow:(4 * offscreenRect.size.width)
																		   bitsPerPixel:32];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep];
	if (!graphicsContext) return NULL;

	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:graphicsContext];

	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];

	// First put the origin in the center of the frame. this makes things easier later
	CGContextTranslateCTM(context, radius, radius);

	// Now rotate the entire thing depending which frameNumber we're trying to generate
	CGContextRotateCTM(context, frameNumber / (CGFloat)numberOfFrames * TWOPI);

	CGFloat toothWidth = toothProperties.toothWidth;
	CGFloat toothHeight = toothProperties.toothHeight;
	CGFloat toothCornerRadius = toothProperties.toothCornerRadius;

	// Draw all the teeth
	for (NSInteger toothNumber=0; toothNumber<numberOfTeeth; toothNumber++) {
		CGFloat numTeeth = numberOfTeeth * 1.0;

		// Set the correct color for the tooth, dividing by more than the number of teeth to prevent the last tooth from being too translucent
		const CGFloat alpha = 0.3 + ((toothNumber / numTeeth) * 0.7);

		// Position and draw the tooth
		CGContextRotateCTM(context, 1 / numTeeth * TWOPI);

		NSRect innerRect = NSMakeRect(-toothWidth / 2.f, -radius, toothWidth, toothHeight ? toothHeight : ceilf(radius * .54f));

		// First the stroke if provided
		if (strokeColor) {
			const CGFloat outset = 0.75;
			[[strokeColor colorWithAlphaComponent:alpha] setFill];
			NSRect outerRect = NSInsetRect(innerRect, -outset, -outset);
			[[NSBezierPath bezierPathWithRoundedRect:outerRect xRadius:toothCornerRadius - 1 yRadius:toothCornerRadius - 1] fill];
		}

		// Inner tooth
		[[color colorWithAlphaComponent:alpha] setFill];
		[[NSBezierPath bezierPathWithRoundedRect:innerRect xRadius:toothCornerRadius yRadius:toothCornerRadius] fill];
	}

	[graphicsContext flushGraphics];
	[NSGraphicsContext restoreGraphicsState];

	return [offscreenRep CGImage];
}

@interface BeeActivityIndicatorView()
	@property (assign) BOOL animating;
@end

@implementation BeeActivityIndicatorView


- (id)initWithActivityIndicatorStyle:(BeeActivityIndicatorViewStyle)style {
	NSRect frame = NSZeroRect;
	frame.size = BeeActivityIndicatorViewStyleSize(style);

	if ((self = [super initWithFrame:frame])) {
		self.layer = [CALayer layer];
		[self setWantsLayer:YES];
		self.activityIndicatorViewStyle = style;
		self.hidesWhenStopped = YES;
		self.color = (style == BeeActivityIndicatorViewStyleGray) ? [NSColor grayColor] : [NSColor whiteColor];
		self.numberOfTeeth = 12;
		self.toothWidth = (style == BeeActivityIndicatorViewStyleWhiteLarge) ? 3.5 : 3;
		self.toothCornerRadius = self.toothWidth / 2.f;
		self.animationDuration = 0.8;
	}

	return self;
}

- (id)initWithFrame:(NSRect)frame {
	if ((self = [self initWithActivityIndicatorStyle:BeeActivityIndicatorViewStyleWhite])) {
		self.layer = [CALayer layer];
		[self setWantsLayer:YES];
		self.frame = frame;
		self.color = [NSColor whiteColor];
		self.numberOfTeeth = 12;
		self.toothWidth = 3.5;
		self.toothCornerRadius = self.toothWidth / 2.f;
		self.animationDuration = 0.8;
	}

	return self;
}

- (NSSize)sizeThatFits:(NSSize)aSize {
	return BeeActivityIndicatorViewStyleSize(self.activityIndicatorViewStyle);
}

- (void)_startAnimation {
	const NSInteger numberOfFrames = self.numberOfTeeth;
	const CFTimeInterval animationDuration = self.animationDuration;

	NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:numberOfFrames];

	for (NSInteger frameNumber=0; frameNumber<numberOfFrames; frameNumber++) {
		CGImageRef imageRef = BeeActivityIndicatorViewFrameImage(_activityIndicatorViewStyle, _color, _strokeColor, frameNumber, numberOfFrames, numberOfFrames, self.frame.size, [self scale], [self currentToothProperties]);
		if (imageRef) [images addObject:(__bridge id) imageRef];
	}

	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	animation.calculationMode = kCAAnimationDiscrete;
	animation.duration = animationDuration;
	animation.repeatCount = FLT_MAX;
	animation.values = images;
	animation.removedOnCompletion = NO;
	animation.fillMode = kCAFillModeBoth;

	[self.layer addAnimation:animation forKey:@"contents"];
}

- (void)_stopAnimation {
	[self.layer removeAnimationForKey:@"contents"];

	if (self.hidesWhenStopped) {
		self.hidden = YES;
	}
}

- (void)startAnimating {
	[self.layer removeAnimationForKey:@"contents"];

	_animating = YES;
	self.hidden = NO;
	[self _startAnimation];
}

- (BOOL)isFlipped {
	return YES;
}

- (void)stopAnimating {
	_animating = NO;
	[self _stopAnimation];
}

- (BOOL)isAnimating {
	return _animating;
}

- (void)drawRect:(NSRect)rect {
	CGImageRef imageRef = BeeActivityIndicatorViewFrameImage(_activityIndicatorViewStyle, _color, _strokeColor, 0, 1, _numberOfTeeth, self.frame.size, [self scale], [self currentToothProperties]);
	if (imageRef) {
		NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:self.bounds.size];
		[image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
}

- (BeeActivityIndicatorToothProperties)currentToothProperties {
	BeeActivityIndicatorToothProperties properties = {.toothWidth = self.toothWidth,
		.toothHeight = self.toothHeight,
		.toothCornerRadius = self.toothCornerRadius
	};

	return properties;
}

- (CGFloat)scale {
	CGFloat scale = [self.window.screen backingScaleFactor];

	return scale ? scale : 2.0;
}

- (void)viewDidChangeBackingProperties {
	if ([self isAnimating]) [self _startAnimation];
}


@end
