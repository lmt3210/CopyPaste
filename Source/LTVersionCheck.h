// 
// LTVersionCheck.h
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
//    distribution.
//

#import <Cocoa/Cocoa.h>

#import "LTPopup.h"
#import "LTLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTVersionCheck : NSObject
{
    // For popup window
    LTPopup *mPopupWindow;
    NSMutableString *mText;
    
    // For version check
    int mCheckCount;
    NSString *mAppName;
    NSString *mAppVersion;
    NSString *mLatestVersion;
    NSURLSessionDataTask *mDataTask;
    NSTimer *mVersionTimer;

    // For logging
    os_log_t mLog;
    NSString *mLogFile;
}

- (id)initWithAppName:(NSString *)appName
       withAppVersion:(NSString *)appVersion
        withLogHandle:(os_log_t)log
          withLogFile:(NSString *)logFile;

@end

NS_ASSUME_NONNULL_END
