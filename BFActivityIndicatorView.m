//
//	BFActivityIndicatorView.m
//
//	Created by Basil Shkara on 17/07/12.
//	Copyright (c) 2012 Neat.io. All rights reserved.
//
//  Port of UIActivityIndicatorView from the Chameleon project: https://github.com/BigZaphod/Chameleon

#import "BFActivityIndicatorView.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kNumberOfTeeth = 12;

static CGSize BFActivityIndicatorViewStyleSize(BFActivityIndicatorViewStyle style) {
	if (style == BFActivityIndicatorViewStyleWhiteLarge) {
		return CGSizeMake(37, 37);
	} else {
		return CGSizeMake(20, 20);
	}
}

static CGImageRef BFActivityIndicatorViewFrameImage(BFActivityIndicatorViewStyle style, NSInteger frame, NSInteger numberOfFrames, CGFloat scale) {
	const CGSize frameSize = BFActivityIndicatorViewStyleSize(style);
	const CGFloat radius = frameSize.width / 2.f;
	const CGFloat TWOPI = - M_PI * 2.f;
	const CGFloat toothWidth = (style == BFActivityIndicatorViewStyleWhiteLarge) ? 3.5 : 2;

	NSColor *toothColor = (style == BFActivityIndicatorViewStyleGray)? [NSColor grayColor] : [NSColor whiteColor];

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
	for (NSInteger toothNumber=0; toothNumber<kNumberOfTeeth; toothNumber++) {
		// set the correct color for the tooth, dividing by more than the number of teeth to prevent the last tooth from being too translucent
		const CGFloat alpha = 0.3 + ((toothNumber / kNumberOfTeeth) * 0.7);
		[[toothColor colorWithAlphaComponent:alpha] setFill];

		// position and draw the tooth
		CGContextRotateCTM(context, 1 / kNumberOfTeeth * TWOPI);
		NSRect rect = NSMakeRect(-toothWidth / 2.f, -radius, toothWidth, ceilf(radius * .54f));
		CGFloat radius = toothWidth / 2.f;
		[[NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius] fill];
	}

	[NSGraphicsContext restoreGraphicsState];

	return [offscreenRep CGImage];
}

@implementation BFActivityIndicatorView


- (id)initWithActivityIndicatorStyle:(BFActivityIndicatorViewStyle)style {
	CGRect frame = CGRectZero;
	frame.size = BFActivityIndicatorViewStyleSize(style);
	
	if ((self = [super initWithFrame:frame])) {
		self.layer = [CALayer layer];
		[self setWantsLayer:YES];
		_animating = NO;
		self.activityIndicatorViewStyle = style;
		self.hidesWhenStopped = YES;
	}

	return self;
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [self initWithActivityIndicatorStyle:BFActivityIndicatorViewStyleWhite])) {
		self.layer = [CALayer layer];
		[self setWantsLayer:YES];
		self.frame = frame;
	}

	return self;
}

- (CGSize)sizeThatFits:(CGSize)aSize {
	BFActivityIndicatorViewStyle style;

	@synchronized (self) {
		style = _activityIndicatorViewStyle;
	}

	return BFActivityIndicatorViewStyleSize(style);
}

- (void)setActivityIndicatorViewStyle:(BFActivityIndicatorViewStyle)style {
	@synchronized (self) {
		if (_activityIndicatorViewStyle != style) {
			_activityIndicatorViewStyle = style;
			[self setNeedsDisplay:YES];

			if (_animating) {
				// This will reset the images in the animation if it was already animating
				[self startAnimating];
			}
		}
	}
}

- (BFActivityIndicatorViewStyle)activityIndicatorViewStyle {
	BFActivityIndicatorViewStyle style;

	@synchronized (self) {
		style = _activityIndicatorViewStyle;
	}

	return style;
}

- (void)setHidesWhenStopped:(BOOL)hides {
	@synchronized (self) {
		_hidesWhenStopped = hides;

		if (_hidesWhenStopped) {
			self.hidden = !_animating;
		} else {
			self.hidden = NO;
		}
	}
}

- (BOOL)hidesWhenStopped {
	BOOL hides;

	@synchronized (self) {
		hides = _hidesWhenStopped;
	}

	return hides;
}

- (void)_startAnimation {
	const NSInteger numberOfFrames = kNumberOfTeeth;
	const CFTimeInterval animationDuration = 0.8;

	NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:numberOfFrames];

	for (NSInteger frameNumber=0; frameNumber<numberOfFrames; frameNumber++) {
		[images addObject:(__bridge id) (BFActivityIndicatorViewFrameImage(_activityIndicatorViewStyle, frameNumber, numberOfFrames, 1.0))];
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
	@synchronized (self) {
		if (!_animating) {
			_animating = YES;
			self.hidden = NO;
			[self performSelectorOnMainThread:@selector(_startAnimation) withObject:nil waitUntilDone:NO];
		}
	}
}

- (BOOL)isFlipped {
	return YES;
}

- (void)stopAnimating {
	@synchronized (self) {
		_animating = NO;
		[self performSelectorOnMainThread:@selector(_stopAnimation) withObject:nil waitUntilDone:NO];
	}
}

- (BOOL)isAnimating {
	BOOL animating;

	@synchronized (self) {
		animating = _animating;
	}

	return animating;
}

- (void)drawRect:(NSRect)rect {
	BFActivityIndicatorViewStyle style;

	@synchronized (self) {
		style = _activityIndicatorViewStyle;
	}
	
	CGImageRef imageRef = BFActivityIndicatorViewFrameImage(style, 0, 1, 1.0);
	NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:self.bounds.size];
	[image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}


@end
