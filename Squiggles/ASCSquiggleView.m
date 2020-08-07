/*
     File: ASCSquiggleView.m
 Abstract: ASCSquiggleView is a subclass of NSView that supports custom drawing and event handling.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "ASCSquiggleView.h"
#import "ASCSquiggle.h"

#import <QuartzCore/QuartzCore.h>

//i am seeing previous view momentarily when spooling on and timer off -- issues goes away with CACHE_LAYER ON
#define SPOOLING 1
#define MAX_SPOOL_FACTOR 5
#define NSVIEW_CANVAS_CACHING (SPOOLING && 0)
#define CUSTOM_LAYER 1
#define LAYER_DELEGATE_DRAW 0
#define CACHE_LAYER ((CUSTOM_LAYER || LAYER_DELEGATE_DRAW) && 0)
#define PERIODIC_INVALIDATE 0

@interface MyWindow : NSWindow

@end

@implementation MyWindow

//- (CGFloat)alphaValue {
//    CGFloat val = 1.0;
//    return val;
//}

- (BOOL)isOpaque {
    
    BOOL val = NO;
    return val;
}


- (NSColor*) backgroundColor {
    return [NSColor systemBlueColor];
}

@end

@implementation MyView

// The designated initializer for NSView.
- (id)initWithFrame:(NSRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        // Default view has one rotation.
        _bgColor = [NSColor systemGreenColor];

        _makeOpaque = YES;
        
        _viewID = @"deafult";
        
        [self setCanDrawSubviewsIntoLayer:YES];
    }
    return self;
}

- (BOOL)isOpaque {
    return _makeOpaque;
}

- (void)drawRect:(NSRect)rect {

    // Clear our current background and make it white.
    static int count = 0;
    NSColor* color = (count % 2 == 0) ? _bgColor : [NSColor systemRedColor];
    [color set];
    NSRectFill(rect);
   // count ^= 1;           //enable to toggle color alternatively
}

@end

@interface ASCSquiggleView()

@property NSMutableArray *squiggles;

- (void)customDrawLayer:(CALayer*)layer
inContext:(CGContextRef)ctx;

@end

#if CUSTOM_LAYER

@interface MyLayer : CALayer {

    ASCSquiggleView* fView;
}

- (id)initWithView:(ASCSquiggleView*)view;

#if !LAYER_DELEGATE_DRAW
- (void)drawInContext:(CGContextRef)ctx;
#endif

@end


@implementation MyLayer {
}

- (id)initWithView:(ASCSquiggleView*)view {

    fView = view;
    return [self init];
    }

- (BOOL) isOpaque {
 return YES;  // this needs to be YES even in NSView is opaque, otherwise it is flickering when spooling on and (CUSTOM_LAYER 1
                // and LAYER_DELEGATE_DRAW 1)
}

#if !LAYER_DELEGATE_DRAW
- (void)drawInContext:(CGContextRef)ctx {
    
    [fView customDrawLayer:self inContext:ctx];
}
#endif

@end
#endif // CUSTOM_LAYER


@implementation ASCSquiggleView

- (void)invalidateRect: (NSRect)rect
whole:(BOOL)val {
    if(val)
    {
        [self setNeedsDisplayInRect: CGRectMake(0, 0, rect.size.width, rect.size.height)];
        //[self setNeedsDisplay:YES];
    }
    else
    {
        [self setNeedsDisplayInRect: CGRectMake(0, 0, rect.size.width, rect.size.height)];
    }
}

- (void)customDrawLayer:(CALayer*)layer
inContext:(CGContextRef)ctx {
    
    // Technically this is wrong. We should probably provide a drawing delegate
    // to the CALayer rather than override this routine. For now, this is just
    // test code.

    // Can we limit the back buffer blit to just what is invalid??

#if CACHE_LAYER
    static CGImageRef fDoubleBuffer = nullptr;
    
    if (fDoubleBuffer != nullptr) {

        // Ok if the buffer exists we need to validate it. Is it the
        // same size, scroll position, etc... if not don't blit it.
        // or maybe not - it seems to work just fine since it is
        // auto corrected below.

        CGContextSaveGState( ctx );
        CGRect r = CGRectMake(0, 0, CGImageGetWidth(fDoubleBuffer), CGImageGetHeight(fDoubleBuffer));

        CGContextTranslateCTM(ctx, 0, 0);

//        CGAffineTransform flipTransform = { 1, 0, 0, -1, 0, r.size.height };
//        CGContextConcatCTM( ctx, flipTransform );

        CGContextSetBlendMode(ctx, kCGBlendModeNormal);

        CGContextDrawImage (ctx, r, fDoubleBuffer);
        CGContextRestoreGState (ctx);
    }
#endif //#if CACHE_LAYER

    NSGraphicsContext* old = [NSGraphicsContext currentContext];
    NSGraphicsContext* ng = [NSGraphicsContext graphicsContextWithCGContext: ctx flipped:NO];
    [NSGraphicsContext setCurrentContext:ng];

    // This should be limited to clip bounds if possible
    [self drawRect:self.bounds];

    [NSGraphicsContext setCurrentContext:old];

#if CACHE_LAYER
    if (fDoubleBuffer != nullptr)
        CGImageRelease(fDoubleBuffer);

    // If I understand this function correctly it should be copy on write
    // and very fast.
    fDoubleBuffer = CGBitmapContextCreateImage(ctx);
#endif //#if CACHE_LAYER
}


static CGFloat randomComponent(void) {
    return (CGFloat)(random() / (CGFloat)INT_MAX);
}

#pragma mark - Init Methods

// The designated initializer for NSView.
- (id)initWithFrame:(NSRect)frame {
    
    self = [super initWithFrame:frame];

    if (self) {
        // Default view has one rotation.
        _rotations = 1;

        // Default view has no squiggles.
        _squiggles = [NSMutableArray array];
        
#if PERIODIC_INVALIDATE
        _timer =  [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).2
                                     target:self
                                   selector:@selector(timerFireMethod:)
                                   userInfo:nil
                                    repeats:YES];
#endif
        
#if NSVIEW_CANVAS_CACHING
        _cachedBitmap = [[NSBitmapImageRep alloc] initForIncrementalLoad];
#endif

    }
    return self;
}

#pragma mark - Public Methods

// Removes all squiggles from the view.
- (void)removeAllSquiggles {
    
    [self.squiggles removeAllObjects];
    [self invalidateRect:[self bounds] whole:YES];
}


- (void)setRotations:(NSUInteger)rotations {
    /*
     Updates the number of rotations and redisplay if "rotations" is different than the current number of rotations.
     */    
    if (_rotations != rotations) {
        _rotations = rotations;
        [self setNeedsDisplay:YES];
    }
}

#pragma mark - Drawing Methods

#if LAYER_DELEGATE_DRAW
- (void)drawLayer:(CALayer *)layer
        inContext:(CGContextRef)ctx {
    [self customDrawLayer:layer inContext:ctx];
}
#endif

#if CUSTOM_LAYER
-(CALayer*)makeBackingLayer {

    CALayer* l = [[MyLayer alloc] initWithView:self];
    
    //[l setBackgroundColor: CGColorCreateGenericRGB(0.0, 1.0, 0.0, 1.0)];
    return l;
    }
#endif

// The method invoked when it is time for an NSView to draw itself.
- (void)drawRect:(NSRect)rect {
    
#if SPOOLING
    static int spool = -1;
    
    int maxSpoolFactor = MAX_SPOOL_FACTOR;
    spool = (spool + 1) % maxSpoolFactor;
    if(spool > maxSpoolFactor/2 && spool < maxSpoolFactor)
    {
#if NSVIEW_CANVAS_CACHING
        NSImage* image = [[NSImage alloc] initWithCGImage:[_cachedBitmap CGImage] size:NSZeroSize];
        [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
#endif
        return;
    }
#endif

    // Clear our current background and make it white.
    [[NSColor whiteColor] set];
    NSRectFill(rect);

    /*
      Create a coordinate transformation based on the value of the rotation slider (to be repeatedly applied below).
     */
    CGFloat widthOverTwo = self.bounds.size.width / 2.0;
    CGFloat heightOverTwo = self.bounds.size.height / 2.0;
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:widthOverTwo yBy:heightOverTwo];
    
    [transform rotateByDegrees:360.f / self.rotations];

    [transform translateXBy:-widthOverTwo yBy:-heightOverTwo];

	// For each rotation, draw the the full list of squiggles.
    for (NSUInteger idx = 0; idx < self.rotations; idx++) {

        [self.squiggles enumerateObjectsUsingBlock:^(ASCSquiggle *squiggle, NSUInteger squiggleIndex, BOOL *stop) {
            [squiggle draw];
        }];

        // Apply the transform to rotate in preparation for the next pass.
        [transform concat];
    }

#if NSVIEW_CANVAS_CACHING
    if(!_cachedBitmap)
        _cachedBitmap = [self bitmapImageRepForCachingDisplayInRect:[self bounds]];
    
    [self cacheDisplayInRect:[self bounds] toBitmapImageRep:_cachedBitmap];
#endif

}

#pragma mark - Mouse Event Methods

/*
 Override two of NSResponder's mouse handling methods to respond to the events we want.
 */

// Start drawing a new squiggle on mouse down.
- (void)mouseDown:(NSEvent *)event {

	// Convert from the window's coordinate system to this view's coordinates.
    NSPoint locationInView = [self convertPoint:event.locationInWindow fromView:nil];

    ASCSquiggle *newSquiggle = [[ASCSquiggle alloc] initWithInitialPoint:locationInView];
    
    CGFloat red     = randomComponent(),
            green   = randomComponent(),
            blue    = randomComponent(),
            alpha   = randomComponent() / 2.f + .5f;

    newSquiggle.color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];

    newSquiggle.thickness = 1 + 3.f * randomComponent();

    [self.squiggles addObject:newSquiggle];

    [self invalidateRect:[self bounds] whole:YES];
}

// Draw points on existing squiggle on mouse drag.
- (void)mouseDragged:(NSEvent *)event {
    
	// Convert from the window's coordinate system to this view's coordinates.
    NSPoint locationInView = [self convertPoint:event.locationInWindow
                                       fromView:nil];

    ASCSquiggle *currentSquiggle = [self.squiggles lastObject];

    [currentSquiggle addPoint:locationInView];

    [self invalidateRect:[self bounds] whole:YES];
}

#pragma mark - NSView display optimization

/*
 Opaque content drawing can allow some optimizations to happen. The default value is NO.
 */
- (BOOL)isOpaque {

	return YES;
}

#if PERIODIC_INVALIDATE
- (void)timerFireMethod:(NSTimer *)timer {
    //NSLog(@"timer fired");
    int cond = 1;
    
    cond =  cond;
    int offset = 20;  //offset for invalidating a part of superview.
    switch (cond) {
        case 0:
            [self setNeedsDisplay:YES];
        break;
        case 1:
            [self setNeedsDisplayInRect: CGRectMake(0, -offset, [self bounds].size.width/2, [self bounds].size.height/2 + offset)];
           //[self displayRectIgnoringOpacity: CGRectMake(0, 0, [self bounds].size.width/2, [self bounds].size.height/2)];
        break;
        case 2:
            [self setNeedsDisplayInRect: CGRectMake(0, 0, [self bounds].size.width, [self bounds].size.height)];
        break;
        default:
        break;
    }
}
#endif //PERIODIC_INVALIDATE

@end
