//
// AppDelegate.m
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

#import <sys/types.h>
#import <pwd.h>
#import <uuid/uuid.h>
#import <sys/utsname.h>

#import "AppDelegate.h"
#import "NSFileManager+DirectoryLocations.h"


@implementation AppDelegate

@synthesize mStatusBar;
@synthesize mStatusMenu;
@synthesize mPrefs;
@synthesize mCopyDCMenu;
@synthesize mCopyDragMenu;
@synthesize mPasteMenu;
@synthesize mRightPasteMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Set up logging
    mLog = os_log_create("com.larrymtaylor.CopyPaste", "AppDelegate");
    NSBundle *appBundle = [NSBundle mainBundle];
    NSString *path =
        [[NSFileManager defaultManager] applicationSupportDirectory];
    mLogFile = [[NSString alloc] initWithFormat:@"%@/logFile.txt", path];
    UInt64 fileSize = [[[NSFileManager defaultManager]
                        attributesOfItemAtPath:mLogFile error:nil] fileSize];

    if (fileSize > (1024 * 1024))
    {
        [[NSFileManager defaultManager] removeItemAtPath:mLogFile error:nil];
    }

    // Get macOS version
    NSOperatingSystemVersion sysVersion =
        [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *systemVersion = [NSString stringWithFormat:@"%ld.%ld",
                               sysVersion.majorVersion,
                               sysVersion.minorVersion];
    
    // Log some basic information
    NSDictionary *appInfo = [appBundle infoDictionary];
    NSString *appVersion =
        [appInfo objectForKey:@"CFBundleShortVersionString"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy h:mm a"];
    NSString *day = [dateFormatter stringFromDate:[NSDate date]];
    struct utsname osinfo;
    uname(&osinfo);
    NSString *info = [NSString stringWithUTF8String:osinfo.version];
    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
          @"\nCopyPaste v%@ running on macOS %@ (%@)\n%@",
          appVersion, systemVersion, day, info);

    // Setup status bar menu
    mStatusBar = [[NSStatusBar systemStatusBar]
        statusItemWithLength:NSVariableStatusItemLength];
    mStatusBar.menu = mStatusMenu;
    mStatusBar.highlightMode = YES;
    [mStatusBar setImage:[NSImage imageNamed:@"copy-16.png"]];
    
    // Get preferences
    mPrefs = [NSUserDefaults standardUserDefaults];
    
    NSNumber *pref = [mPrefs objectForKey:@"Copy Enable"];
    
    if (pref == nil)
    {
        mCopyEnable = 0;
    }
    else
    {
        mCopyEnable = [pref intValue];
    }
    
    pref = [mPrefs objectForKey:@"Drag Enable"];
    
    if (pref == nil)
    {
        mDragEnable = 0;
    }
    else
    {
        mDragEnable = [pref intValue];
    }

    pref = [mPrefs objectForKey:@"Paste Enable"];
    
    if (pref == nil)
    {
        mPasteEnable = 0;
    }
    else
    {
        mPasteEnable = [pref intValue];
    }

    pref = [mPrefs objectForKey:@"Right Paste Enable"];
    
    if (pref == nil)
    {
        mRightPasteEnable = 0;
    }
    else
    {
        mRightPasteEnable = [pref intValue];
    }

    // Initialize preferences panel checkboxes
    [mCopyDCMenu setState:mCopyEnable];
    [mCopyDragMenu setState:mDragEnable];
    [mPasteMenu setState:mPasteEnable];
    [mRightPasteMenu setState:mRightPasteEnable];
    
    // Version check
    mVersionCheck = [[LTVersionCheck alloc] initWithAppName:@"CopyPaste"
                     withAppVersion:appVersion
                     withLogHandle:mLog withLogFile:@""];
    
    // Start task
    mTask = nil;
    [self startTask];
    
    // Task monitor timer
    mTimer = [NSTimer scheduledTimerWithTimeInterval:5
              target:self selector:@selector(taskTimer:)
              userInfo:nil repeats:YES];

    // Check accessibility status
    BOOL hasAccessibilityPermission = AXIsProcessTrusted();
    NSString *permission;
    
    if (hasAccessibilityPermission == false)
    {
        // Show popup window with message
        LTPopup *popupWindow = [[LTPopup alloc]
                                initWithWindowNibName:@"LTPopup"];
        NSMutableString *pText = [[NSMutableString alloc] init];
        [pText setString:@""];
        [pText appendString:@"Please add CopyPaste to the list of apps "
                             "allowed to control your computer in "
                             "Settings...Security & Privacy...Privacy..."
                             "Accessibility and in "
                             "Settings...Security & Privacy...Privacy..."
                             "Input Monitoring."];
        [popupWindow show];
        [popupWindow setText:(NSString *)pText];
        
        [self openAccessibilitySettings];
        permission = @"false";
    }
    else
    {
        permission = @"true";
    }

    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO, @"Accessibility = %@", permission);
}

- (void)openAccessibilitySettings
{
    NSOperatingSystemVersion version =
        [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *systemVersion = [NSString stringWithFormat:@"%ld.%ld",
                               version.majorVersion, version.minorVersion];
    BOOL isPreCatalina;
    
    if (([systemVersion isEqualToString:@"10.15"]) ||
        (version.majorVersion >= 11))
    {
        isPreCatalina = false;
    }
    else
    {
        isPreCatalina = true;
    }
    
    if (isPreCatalina == true)
    {
        NSAppleScript *a = [[NSAppleScript alloc] initWithSource:
                            @"tell application \"System Preferences\"\n"
                            "activate\n"
                            "reveal anchor \"Privacy_Accessibility\" of "
                            "pane \"com.apple.preference.security\"\n"
                            "end tell"];
        [a executeAndReturnError:nil];
    }
    else
    {
        NSURL* url = [NSURL URLWithString:@"x-apple.systempreferences:com."
                                           "apple.preference.security?"
                                           "Privacy_Accessibility"];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    if (mTask != nil)
    {
        [mTask cancelAllOperations];
    }
}

- (void)manageTask
{
    mArgs.copyEnable = mCopyEnable;
    mArgs.dragEnable = mDragEnable;
    mArgs.pasteEnable = mPasteEnable;
    mArgs.rightPasteEnable = mRightPasteEnable;
    mArgs.displayPositionEnable = 0;
    mArgs.doubleClickTime = (long)(DEFAULT_DOUBLE_CLICK_MILLIS *
                            [NSEvent doubleClickInterval]);;
    mArgs.verbose = 0;

    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO, @"manageTask: copyEnable = %i, "
           "dragEnable = %i, pasteEnable = %i, rightPasteEnable = %i, "
           "doubleClickTime = %lli\n", mArgs.copyEnable, mArgs.dragEnable,
          mArgs.pasteEnable, mArgs.rightPasteEnable, mArgs.doubleClickTime);
}

- (void)startTask
{
    mArgs.copyEnable = mCopyEnable;
    mArgs.dragEnable = mDragEnable;
    mArgs.pasteEnable = mPasteEnable;
    mArgs.rightPasteEnable = mRightPasteEnable;
    mArgs.doubleClickTime = (long)(DEFAULT_DOUBLE_CLICK_MILLIS *
                            [NSEvent doubleClickInterval]);;
    mArgs.verbose = 0;
    
    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO, @"startTask: copyEnable = %i, "
          "dragEnable = %i, pasteEnable = %i, rightPasteEnable = %i, "
          "doubleClickTime = %lli\n", mArgs.copyEnable, mArgs.dragEnable,
          mArgs.pasteEnable, mArgs.rightPasteEnable, mArgs.doubleClickTime);
    
    mTask = [[NSOperationQueue alloc] init];
    [mTask setName:@"CopyPasteTask"];
    
    [mTask addOperationWithBlock:^{
        CGEventMask emask;
        CFMachPortRef myEventTap;
        CFRunLoopSourceRef eventTapRLSrc;

        // Set mask for desired actions
        emask = CGEventMaskBit(kCGEventOtherMouseDown) |
                CGEventMaskBit(kCGEventLeftMouseDown)  |
                CGEventMaskBit(kCGEventLeftMouseUp)    |
                CGEventMaskBit(kCGEventRightMouseDown) |
                CGEventMaskBit(kCGEventRightMouseUp)   |
                CGEventMaskBit(kCGEventLeftMouseDragged);

        // Create the Tap
        myEventTap = CGEventTapCreate(
            kCGSessionEventTap,          // Catch all events for current user 
            kCGTailAppendEventTap,       // Append to end of EventTap list
            kCGEventTapOptionListenOnly, // We only listen, we don't modify
            emask, &mouseCallback, &self->mArgs);

        // Create a RunLoop Source for it
        eventTapRLSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,
                                                      myEventTap, 0);

        // Add the source to the current RunLoop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), eventTapRLSrc,
                           kCFRunLoopDefaultMode);

        // Keep the RunLoop running forever
        CFRunLoopRun();

        // Not reached (RunLoop above never stops running)
        return;
    }];
}

- (IBAction)copyDCAction:(id)sender
{
    (mCopyEnable == 1) ? (mCopyEnable = 0) : (mCopyEnable = 1);
    [mCopyDCMenu setState:mCopyEnable];
    [mPrefs setObject:[NSNumber numberWithInt:mCopyEnable]
     forKey:@"Copy Enable"];
    [self manageTask];
}

- (IBAction)copyDragAction:(id)sender
{
    (mDragEnable == 1) ? (mDragEnable = 0) : (mDragEnable = 1);
    [mCopyDragMenu setState:mDragEnable];
    [mPrefs setObject:[NSNumber numberWithInt:mDragEnable]
     forKey:@"Drag Enable"];
    [self manageTask];
}

- (IBAction)pasteAction:(id)sender
{
    (mPasteEnable == 1) ? (mPasteEnable = 0) : (mPasteEnable = 1);
    [mPasteMenu setState:mPasteEnable];
    [mPrefs setObject:[NSNumber numberWithInt:mPasteEnable]
     forKey:@"Paste Enable"];
    [self manageTask];
}

- (IBAction)rightPasteAction:(id)sender
{
    (mRightPasteEnable == 1) ? (mRightPasteEnable = 0) :
        (mRightPasteEnable = 1);
    [mRightPasteMenu setState:mRightPasteEnable];
    [mPrefs setObject:[NSNumber numberWithInt:mRightPasteEnable]
     forKey:@"Right Paste Enable"];
    [self manageTask];
}

- (void)taskTimer:(NSTimer *)timer
{
    BOOL suspended = [mTask isSuspended];
    
    if (suspended == true)
    {
        if (mTask != nil)
        {
            [mTask cancelAllOperations];
        }
        
        [self startTask];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy h:mm a"];
        NSString *day = [dateFormatter stringFromDate:[NSDate date]];
        LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO, @"Task restarted %@", day);
    }
}

@end
