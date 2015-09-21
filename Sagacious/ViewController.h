//
//  ViewController.h
//  Sagacious
//
//  Created by Aidan Cornelius-Bell on 14/09/2015.
//  Copyright © 2015 Department for Education and Child Development. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVBase.h>
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVKit/AVKit.h>

@interface ViewController : NSViewController

// Initial View
@property (weak) IBOutlet NSPathControl *filePath;
@property (weak) IBOutlet NSButton *backupButton;

- (IBAction)convertPressed:(id)sender;


// Progress Subview
@property (weak) IBOutlet NSProgressIndicator *majorProgress;
@property (weak) IBOutlet NSProgressIndicator *minorProgress;
@property (weak) IBOutlet NSTextField *progressText;
@property (weak) IBOutlet NSTextField *mediaFileLabel;

@end

