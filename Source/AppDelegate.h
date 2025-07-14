//
// AppDelegate.h
// 
// Copyright (c) 2020-2025 Larry M. Taylor
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software. Permission is granted to anyone to
// use this software for any purpose, including commercial applications, and to
// to alter it and redistribute it freely, subject to 
// the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source
//

#import <Cocoa/Cocoa.h>

#import "macpaste.h"
#import "LTPopup.h"
#import "LTVersionCheck.h"


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    int mCopyEnable;
    int mDragEnable;
    int mPasteEnable;
    int mRightPasteEnable;
    NSOperationQueue *mTask;
    struct callbackArgs mArgs;
    
    // For task monitor
    NSTimer *mTimer;
    
    // For version check
    LTVersionCheck *mVersionCheck;
    
    // For logging
    os_log_t mLog;
    NSString *mLogFile;
}

@property (strong, nonatomic) NSStatusItem *mStatusBar;
@property (strong) IBOutlet NSMenu *mStatusMenu;
@property (strong) NSUserDefaults *mPrefs;
@property (strong) IBOutlet NSMenuItem *mCopyDCMenu;
@property (strong) IBOutlet NSMenuItem *mCopyDragMenu;
@property (strong) IBOutlet NSMenuItem *mPasteMenu;
@property (strong) IBOutlet NSMenuItem *mRightPasteMenu;

- (IBAction)copyDCAction:(id)sender;
- (IBAction)copyDragAction:(id)sender;
- (IBAction)pasteAction:(id)sender;
- (IBAction)rightPasteAction:(id)sender;

@end
