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

@interface BFActivityIndicatorView : NSView {
	@private
		BFActivityIndicatorViewStyle _activityIndicatorViewStyle;
		BOOL _hidesWhenStopped;
		BOOL _animating;
}

@property (nonatomic, assign) BOOL hidesWhenStopped;
@property (nonatomic, assign) BFActivityIndicatorViewStyle activityIndicatorViewStyle;

- (id)initWithActivityIndicatorStyle:(BFActivityIndicatorViewStyle)style;
- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end
