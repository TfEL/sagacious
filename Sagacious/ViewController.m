//
//  ViewController.m
//  Sagacious
//
//  Created by Aidan Cornelius-Bell on 14/09/2015.
//  Copyright © 2015 Department for Education and Child Development. All rights reserved.
//

#import "ViewController.h"
#import "ZipZap.h"


@implementation ViewController

@synthesize filePath, backupButton, majorProgress, minorProgress, progressText, mediaFileLabel;

bool subviewStarted;
bool conversionCompletion;
NSURL *originalFile;
NSURL *lastMediaFile;
double totalFilesToConvert;
double totalFilesConverted;
double runonce;
ZZArchive *ZZoriginalFile;
NSArray *contents;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    if (subviewStarted) {
        [majorProgress incrementBy:0.0];
        [minorProgress incrementBy:100.0];
        [progressText setStringValue:@"Starting..."];
        [mediaFileLabel setStringValue:[NSString stringWithFormat:@"%@", [originalFile.pathComponents lastObject]]];
        
        if ([originalFile.pathExtension isEqualToString:@"pptx"]) {
            
            NSLog(@"Passed PPTX initial validation...");
            
            // Start decompression and file type detection
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/compressorWorkingTemp", [originalFile URLByDeletingLastPathComponent]]];
            ZZoriginalFile = [ZZArchive archiveWithURL:originalFile error:nil];
            NSUInteger fileMaxCount = [ZZoriginalFile.entries count];
            double count = 0;
            
            minorProgress.doubleValue = 0.0;
            minorProgress.maxValue = fileMaxCount;
            
            // Tell the user what up
            [progressText setStringValue:@"Extracting PowerPoint File..."];

            // Do some archive stuff...
            for (ZZArchiveEntry* entry in ZZoriginalFile.entries) {
                
                count++;
                minorProgress.doubleValue = count;
                
                // Create a target
                NSURL *targetPath = [path URLByAppendingPathComponent:entry.fileName];
                
                // Catch directories
                if (entry.fileMode & S_IFDIR)
                    [fileManager createDirectoryAtURL:targetPath withIntermediateDirectories:YES attributes:nil error:nil];
                
                else {
                    [fileManager createDirectoryAtURL:[targetPath URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                    
                    [[entry newDataWithError:nil] writeToURL:targetPath
                                                  atomically:NO];
                    
                    [mediaFileLabel setStringValue:[NSString stringWithFormat:@"%@", [entry fileName]]];
                    
                     NSLog(@"%@", entry);
                }
            }
            
            if (count == fileMaxCount) {
                majorProgress.doubleValue = 25.0;
                minorProgress.maxValue = 100.0;
                minorProgress.doubleValue = 0.0;
                
                [progressText setStringValue:@"Starting Compressor..."];
                
                NSURL *mediaPath = [NSURL URLWithString:[NSString stringWithFormat:@"%@compressorWorkingTemp/ppt/media/", [originalFile URLByDeletingLastPathComponent]]];
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                contents = [fileManager contentsOfDirectoryAtURL:mediaPath
                                               includingPropertiesForKeys:@[]
                                                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                    error:nil];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'mp4'"];
                
                // Progress bar
                fileMaxCount = [[contents filteredArrayUsingPredicate:predicate] count];
                minorProgress.doubleValue = 0.0;
                minorProgress.maxValue = fileMaxCount;
                majorProgress.maxValue = 1 + fileMaxCount;
                majorProgress.doubleValue = 1;
                count = 0;
                
                totalFilesToConvert = fileMaxCount;
                
                [majorProgress incrementBy:totalFilesConverted];
                
                for (NSURL *fileURL in [contents filteredArrayUsingPredicate:predicate]) {
                    // Enumerate each file in directory
                    [mediaFileLabel setStringValue:[NSString stringWithFormat:@"%@", [fileURL lastPathComponent]]];
                    [progressText setStringValue:@"Compressing..."];
                    [minorProgress setIndeterminate:YES];
                    NSLog(@"Crunch for: %@", fileURL);
                    // Do some conversion...
                    
                    lastMediaFile = fileURL;
                    
                    [self convertVideoToLowQualityWithInputURL:fileURL outputURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@.n", fileURL]] successHandler:^{
                        [self completedAConversion];
                    } failureHandler:^(NSError *error) {
                        NSLog(@"%@", error);
                    }];

                };
            }
            
        } else {
            NSAlert *noFileSelected =[[NSAlert alloc] init];
            [noFileSelected addButtonWithTitle:@"Continue..."];
            [noFileSelected setMessageText:@"You did not select a file to compress"];
            [noFileSelected setInformativeText:@"To proceed you will need to select a Microsoft PowerPoint file (PPTX). Please do not use Keynote (KEY) or PowerPoint (PPT) files."];
            [noFileSelected setAlertStyle:NSWarningAlertStyle];
            
            [noFileSelected runModal];
            
            [self presentViewControllerAsModalWindow:self];
        }
        
    }
}

- (void) completedAConversion {
    NSLog(@"Conversion Completed. %f", majorProgress.maxValue);
    
    NSURL *mediaPath = [NSURL URLWithString:[NSString stringWithFormat:@"%@compressorWorkingTemp/ppt/media/", [originalFile URLByDeletingLastPathComponent]]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtURL:mediaPath
                                   includingPropertiesForKeys:@[]
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        error:nil];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'n'"];
    
    for (NSURL *fileURL in [contents filteredArrayUsingPredicate:predicate]) {
        NSError *error;
        
        NSURL *woFile = [fileURL URLByDeletingPathExtension];
        
        NSString *fUrl = [woFile path];
        
        [fileManager removeItemAtPath:fUrl error:&error];
        
        if (error) { NSLog(@"%@", error); }
        
        [fileManager moveItemAtPath:[NSString stringWithFormat:@"%@", [fileURL path]] toPath:fUrl error:&error];
        
        if (error) { NSLog(@"%@", error); }
        
        totalFilesConverted++;
    }
    
    [majorProgress incrementBy:1.0];
    [majorProgress incrementBy:totalFilesConverted];
    [minorProgress setIndeterminate:NO];
    minorProgress.doubleValue = 0.0;
    progressText.stringValue = @"Finalising...";
    
    NSLog(@"%f / %f converted", totalFilesConverted, totalFilesToConvert);
    
    if ([NSNumber numberWithDouble:totalFilesToConvert] == [NSNumber numberWithDouble:totalFilesConverted]) {
        
        // More progress...
        majorProgress.maxValue = 10.0;
        minorProgress.maxValue = 1.0;
        majorProgress.doubleValue = 9.0;
        minorProgress.doubleValue = 0.0;
        NSLog(@"At final stage, compress new pptx...");
        
        ZZArchive* newArchive = [[ZZArchive alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@_Compressed.pptx", [originalFile URLByDeletingPathExtension]]]
                                                       options:@{ZZOpenOptionsCreateIfMissingKey : @YES}
                                                         error:nil];
        
        
        [newArchive updateEntries:ZZoriginalFile.entries error:nil];
        
        // Done
        majorProgress.doubleValue = 10.0;
        
        if (runonce >= 1) { } else {
            
            runonce = 5;
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            
            // CleanUp
            NSAlert *noFileSelected =[[NSAlert alloc] init];
            [noFileSelected addButtonWithTitle:@"Done"];
            [noFileSelected setMessageText:@"Compression Complete"];
            [noFileSelected setInformativeText:@"Put down that cup of tea, your PowerPoint presentation has been compressed successfully."];
            [noFileSelected setAlertStyle:NSWarningAlertStyle];

            dispatch_sync(dispatch_get_main_queue(), ^(void){
                [noFileSelected runModal];
            });
        
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self dismissViewController:self];
                totalFilesToConvert = 0;
                totalFilesConverted = 0;
            });
            
        });
        
        }
        
    } else {
        NSLog(@"Still more to do...");
    }
}

- (void)convertVideoToLowQualityWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL successHandler:(void (^)())successHandler failureHandler:(void (^)(NSError *))failureHandler
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetLowQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler: ^(void) {
        if (exportSession.status == AVAssetExportSessionStatusCompleted)
        {
            conversionCompletion = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ConversionCompleted" object:self];
            successHandler();
        }
        else if (AVAssetExportSessionStatusFailed == exportSession.status)
        {
            conversionCompletion = NO;
            NSError *error = [NSError errorWithDomain:@"Export Failed" code:exportSession.status userInfo:nil];
            failureHandler( error );
        }
        else
        {
            [progressText setStringValue:[NSString stringWithFormat:@"Convert: %ld", (long)exportSession.status]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ConversionNotCompleted" object:self];
        }
    }];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)convertPressed:(id)sender {
    BOOL continueConversion = NO;
    
    if (filePath.URL != NULL) {
        NSLog(@"URL: %@", filePath.URL);
        continueConversion = YES;
        originalFile = filePath.URL;
    } else {
        NSAlert *noFileSelected =[[NSAlert alloc] init];
        [noFileSelected addButtonWithTitle:@"Continue..."];
        [noFileSelected setMessageText:@"You did not select a file to compress"];
        [noFileSelected setInformativeText:@"To proceed you will need to select a Microsoft PowerPoint file (PPTX). Please do not use Keynote (KEY) or PowerPoint (PPT) files."];
        [noFileSelected setAlertStyle:NSWarningAlertStyle];
        
        [noFileSelected runModal];
    }
    
    if (continueConversion == YES) {
        subviewStarted = YES;
        
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        
        NSViewController *progressView = [storyboard instantiateControllerWithIdentifier:@"progressView"];
        
        [self presentViewControllerAsSheet:progressView];
                
        [majorProgress incrementBy:50.0];
        [progressText setStringValue:@""];
        [mediaFileLabel setStringValue:[NSString stringWithFormat:@"%@", originalFile]];
    }
    
}

@end
