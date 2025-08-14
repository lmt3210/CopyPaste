//
// cmdmain.c
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

#include "macpaste.h"

int main(int argc, char **argv)
{
    CGEventMask emask;
    CFMachPortRef myEventTap;
    CFRunLoopSourceRef eventTapRLSrc;
    struct callbackArgs callArgs;

    callArgs.verbose = 0;
    callArgs.copyEnable = 0;
    callArgs.dragEnable = 0;
    callArgs.pasteEnable = 0;
    callArgs.rightPasteEnable = 0;
    callArgs.displayPositionEnable = 0;
    callArgs.doubleClickTime = DEFAULT_DOUBLE_CLICK_MILLIS;

    // Parse args
    int c;

    while ((c = getopt(argc, argv, "cdprt:vx")) != -1)
    {
        switch (c)
        {
            case 'c':
                callArgs.copyEnable = 1;
                break;
            case 'd':
                callArgs.dragEnable = 1;
                break;
            case 'p':
                callArgs.pasteEnable = 1;
                break;
            case 'r':
                callArgs.rightPasteEnable = 1;
                break;
            case 't':
                callArgs.doubleClickTime = atoi(optarg);
                break;
            case 'v':
                callArgs.verbose = 1;
                break;
            case 'x':
                callArgs.displayPositionEnable = 1;
                break;
            default:
                break;
        }
    }

    if (callArgs.verbose == 1)
    {
        printf("copyEnable = %i, dragEnable = %i, pasteEnable = %i, "
               "rightPasteEnable = %i,\n    displayPositionEnable = %i, "
               "doubleClickTime = %lli\n", callArgs.copyEnable,
               callArgs.dragEnable, callArgs.pasteEnable,
               callArgs.rightPasteEnable, callArgs.displayPositionEnable,
               callArgs.doubleClickTime);
    }

    // We want "other" mouse button click-release, such as middle or exotic
    emask = CGEventMaskBit(kCGEventOtherMouseDown)  |
            CGEventMaskBit(kCGEventLeftMouseDown) |
            CGEventMaskBit(kCGEventLeftMouseUp)   |
            CGEventMaskBit(kCGEventLeftMouseDragged);

    // Create the Tap
    myEventTap = CGEventTapCreate(
        kCGSessionEventTap,          // Catch all events for current user 
        kCGTailAppendEventTap,       // Append to end of EventTap list
        kCGEventTapOptionListenOnly, // We only listen, we don't modify
        emask, &mouseCallback, &callArgs);

    // Create a RunLoop Source for it
    eventTapRLSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,
                                                  myEventTap, 0);

    // Add the source to the current RunLoop
    CFRunLoopAddSource(CFRunLoopGetCurrent(), eventTapRLSrc,
                       kCFRunLoopDefaultMode);

    // Keep the RunLoop running forever
    CFRunLoopRun();

    // Not reached (RunLoop above never stops running)
    return 0;
}
