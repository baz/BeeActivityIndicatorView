//
//	BFActivityIndicatorView.m
//
//	Created by Basil Shkara on 17/07/12.
//	Copyright (c) 2012 Neat.io. All rights reserved.
//
//  Port of UIActivityIndicatorView from the Chameleon project: https://github.com/BigZaphod/Chameleon

#import "BFActivityIndicatorView.h"
#import <QuartzCore/QuartzCore.h>

static CGSize BFActivityIndicatorViewStyleSize(BFActivityIndicatorViewStyle style) {
	if (style == BFActivityIndicatorViewStyleWhiteLarge) {
		return CGSizeMake(37, 37);
	} else {
		return CGSizeMake(20, 20);
	}
}

static CGImageRef BFActivityIndicatorViewFrameImage(BFActivityIndicatorViewStyle style, NSColor *color, NSInteger frame, NSInteger numberOfFrames, NSUInteger numberOfTeeth, CGFloat toothWidth, CGFloat toothHeight, CGSize frameSize, CGFloat scale) {
	const CGFloat radius = frameSize.width / 2.f;
	const CGFloat TWOPI = - M_PI * 2.f;

	NSRect offscreenRect = NSMakeRect(0.0, 0.0, frameSize.width, frameSize.height);
	NSBitmapImageRep *offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
																			 pixelsWide:offscreenRect.size.width
																			 pixelsHigh:offscreenRect.size.height
																		  bitsPerSample:8
																		samplesPerPixel:4
																			   hasAlpha:YES
																			   isPlanar:NO
																		 colorSpaceName:NSCalibratedRGBColorSpace
																		   bitmapFormat:0
																			bytesPerRow:(4 * offscreenRect.size.width)
																		   bitsPerPixel:32];
 
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep]];

	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];

	// first put the origin in the center of the frame. this makes things easier later
	CGContextTranslateCTM(context, radius, radius);

	// now rotate the entire thing depending which frame we're trying to generate
	CGContextRotateCTM(context, frame / (CGFloat)numberOfFrames * TWOPI);

	// draw all the teeth
	for (NSInteger toothNumber=0; toothNumber<numberOfTeeth; toothNumber++) {
		CGFloat numTeeth = numberOfTeeth * 1.0;
		// set the correct color for the tooth, dividing by more than the number of teeth to prevent the last tooth from being too translucent
		const CGFloat alpha = 0.3 + ((toothNumber / numTeeth) * 0.7);
		[[color colorWithAlphaComponent:alpha] setFill];

		// position and draw the tooth
		CGContextRotateCTM(context, 1 / numTeeth * TWOPI);
		NSRect rect = NSMakeRect(-toothWidth / 2.f, -radius, toothWidth, toothHeight ? toothHeight : ceilf(radius * .54f));
		CGFloat radius = toothWidth / 2.f;
		[[NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius] fill];
	}

	[NSGraphicsContext restoreGraphicsState];

	return [offscreenRep CGImage];
}

@interface BFActivityIndicatorView()
	@property (assign) BOOL animating;
@end

@implementation BFActivityIndicatorView


- (id)initWithActivityIndicatorStyle:(BFActivityIndicatorViewStyle)style {
	CGRect frame = CGRectZero;
	frame.size = BFActivityIndicatorViewStyleSize(style);
	
	if ((self = [super initWithFrame:frame])) {
		self.layer = [CALayer layer];
		[self setWantsLayer:YES];
		self.activityIndicatorViewStyle = style;
		self.hidesWhenStopped = YES;
		self.color = (style == BFActivityIndicatorViewStyleGray) ? [NSColor grayColor] : [NSColor whiteColor];
		self.numberOfTeeth = 12;
		self.toothWidth = (style == BFActivityIndicatorViewStyleWhiteLarge) ? 3.5 : 3;
	}

	return self;
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [self initWithActivityIndicatorStyle:BFActivityIndicatorViewStyleWhite])) {
		self.layer = [CALayer layer];
		[self setWantsLayer:YES];
		self.frame = frame;
		self.color = [NSColor whiteColor];
		self.numberOfTeeth = 12;
		self.toothWidth = 3.5;
	}

	return self;
}

- (CGSize)sizeThatFits:(CGSize)aSize {
	return BFActivityIndicatorViewStyleSize(self.activityIndicatorViewStyle);
}

- (void)_startAnimation {
	const NSInteger numberOfFrames = self.numberOfTeeth;
	const CFTimeInterval animationDuration = 0.8;

	NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:numberOfFrames];

	for (NSInteger frameNumber=0; frameNumber<numberOfFrames; frameNumber++) {
		[images addObject:(__bridge id) (BFActivityIndicatorViewFrameImage(_activityIndicatorViewStyle, _color, frameNumber, numberOfFrames, numberOfFrames, self.toothWidth, self.toothHeight, self.frame.size, 1.0))];
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
	CGImageRef imageRef = BFActivityIndicatorViewFrameImage(self.activityIndicatorViewStyle, self.color, 0, 1, self.numberOfTeeth, self.toothWidth, self.toothHeight, self.frame.size, 1.0);
	NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:self.bounds.size];
	[image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}


@end
