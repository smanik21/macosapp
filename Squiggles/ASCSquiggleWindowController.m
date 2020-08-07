/*
     File: ASCSquiggleWindowController.m
 Abstract: Interface Declaration for the ASCSquiggleWindowController class.
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

#import "ASCSquiggleWindowController.h"
#import "ASCSquiggleView.h"
#import "ASCSquiggle.h"

@interface ASCSquiggleWindowController ()

@property (weak) IBOutlet NSStepper *rotationStepper;
@property (weak) IBOutlet NSTextField *rotationTextField;
@property (weak) IBOutlet MyView *mainView;
@property (nonatomic) ASCSquiggleView *squiggleView;

@end


@implementation ASCSquiggleWindowController

//- (ASCSquiggleView*) squiggleView {
//
//    return [self squiggleView].mainView;
//}
//
//
//- (void) setSquiggleView: (ASCSquiggleView*) view {
//
//    [self squiggleView].mainView = view;
//}

#pragma mark - NSWindowController Methods

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    [_mainView setViewID:@"Main"];
    //[_mainView setMakeOpaque:NO];
    
    //[_mainView setWantsLayer:NO];  //no impact as wantsLayer is anyways NO without this
    
    NSView* parentView = _mainView;
    
//    MyView* v1 = [[MyView alloc] initWithFrame:[_mainView frame]];
//    [v1 setBgColor:[NSColor systemOrangeColor]];
//    [v1 setMakeOpaque:NO];
//    //[v1 setWantsLayer:YES];   //causes all subviews in heirarchy to have own layer
//    [v1 setViewID:@"Orange"];
//    [_mainView addSubview:v1];
//    parentView = v1;
//
//    MyView* v2 = [[MyView alloc] initWithFrame:[_mainView frame]];
//    [v2 setBgColor:[NSColor systemPurpleColor]];
//    //[v2 setMakeOpaque:NO];
//    //[v2 setWantsLayer:YES];  //causes all subviews in heirarchy to have own layer
//    [v2 setViewID:@"Purple"];
//    [v1 addSubview:v2];
//    parentView = v2;
    
    _squiggleView = [[ASCSquiggleView alloc] initWithFrame:[_mainView frame]];
    [_squiggleView setWantsLayer:YES];
    [_squiggleView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    [parentView addSubview:_squiggleView];
    
    /*
      Set the squiggle view rotations to be the value initially set for the text field in MainMenu.xib.
     */
    [self updateRotationCount:self.rotationTextField];
}


#pragma mark - Action Methods

/*
  Get the value from the sender (possibly the stepper *or* the text field) and update squiggleView's number of rotations.
 */
- (IBAction)updateRotationCount:(id)sender {
    
    self.squiggleView.rotations = [sender integerValue];

    /*
      Update both controls to make sure that both of them are up to date.
     */
    self.rotationStepper.integerValue = [sender integerValue];
    self.rotationTextField.integerValue = [sender integerValue];
}


// Remove all squigles from the squiggle view.
- (IBAction)removeAllSquiggles:(NSButton *)sender {
    
    [self.squiggleView removeAllSquiggles];
}


@end
