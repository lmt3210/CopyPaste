// Public Domain License 2016
//
// Simulate right-handed unix/linux X11 middle-mouse-click copy and paste.
//
// References:
// http://stackoverflow.com/questions/3134901/mouse-tracking-daemon
// http://stackoverflow.com/questions/2379867/
//     simulating-key-press-events-in-mac-os-x#2380280
//

#include "macpaste.h"

void paste(CGEventRef event)
{
    // Mouse click to focus and position insertion cursor
    CGPoint mouseLocation = CGEventGetLocation(event);
    CGEventRef mouseClickDown = CGEventCreateMouseEvent(NULL,
                                                        kCGEventLeftMouseDown,
                                                        mouseLocation,
                                                        kCGMouseButtonLeft);
    CGEventRef mouseClickUp =
        CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, mouseLocation,
                                kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, mouseClickDown);
    CGEventPost(kCGHIDEventTap, mouseClickUp);
    CFRelease(mouseClickDown);
    CFRelease(mouseClickUp);

    // Allow click events time to position cursor before pasting
    usleep(1000);

    // Paste
    CGEventSourceRef source =
        CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    CGEventRef kbdEventPasteDown =
        CGEventCreateKeyboardEvent(source, kVK_ANSI_V, 1);
    CGEventRef kbdEventPasteUp =
        CGEventCreateKeyboardEvent(source, kVK_ANSI_V, 0);
    CGEventSetFlags(kbdEventPasteDown, kCGEventFlagMaskCommand);
    CGEventPost(kCGAnnotatedSessionEventTap, kbdEventPasteDown);
    CGEventPost(kCGAnnotatedSessionEventTap, kbdEventPasteUp);
    CFRelease(kbdEventPasteDown);
    CFRelease(kbdEventPasteUp);
    CFRelease(source);
}

void copy(void)
{
    CGEventSourceRef source =
        CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    CGEventRef kbdEventDown =
        CGEventCreateKeyboardEvent(source, kVK_ANSI_C, 1);
    CGEventRef kbdEventUp =
        CGEventCreateKeyboardEvent(source, kVK_ANSI_C, 0);
    CGEventSetFlags(kbdEventDown, kCGEventFlagMaskCommand);
    CGEventPost(kCGAnnotatedSessionEventTap, kbdEventDown);
    CGEventPost(kCGAnnotatedSessionEventTap, kbdEventUp);
    CFRelease(kbdEventDown);
    CFRelease(kbdEventUp);
    CFRelease(source);
}

CGEventRef mouseCallback(CGEventTapProxy proxy, CGEventType type,
                         CGEventRef event, void *refcon)
{
    struct callbackArgs *args = (struct callbackArgs *)refcon;
    static long long prevClickTimeLeft = 0;
    static long long curClickTimeLeft = 0;
    static long long prevClickTimeRight = 0;
    static long long curClickTimeRight = 0;
    static int isDragging;
    struct timeval te;
    CGPoint point;

    switch (type)
    {
        case kCGEventOtherMouseDown:

            if (args->pasteEnable == 1)
            {
                paste(event);
            }

            break;

        case kCGEventLeftMouseDown:

            if (args->displayPositionEnable == 1)
            {
                point = CGEventGetLocation(event);
                printf("x = %f, y = %f\n", point.x, point.y);
            }
            
            prevClickTimeLeft = curClickTimeLeft;
            gettimeofday(&te, NULL);
            curClickTimeLeft = (te.tv_sec * 1000LL) + (te.tv_usec / 1000);
            break;

        case kCGEventLeftMouseUp:

            if ((((curClickTimeLeft - prevClickTimeLeft) < 
                  args->doubleClickTime) && (args->copyEnable == 1))
                  || ((isDragging == 1) && (args->dragEnable == 1)))
            {
                copy();
            }

            isDragging = 0;
            break;

        case kCGEventLeftMouseDragged:
            isDragging = 1;
            break;
            
        case kCGEventRightMouseDown:
            prevClickTimeRight = curClickTimeRight;
            gettimeofday(&te, NULL);
            curClickTimeRight = (te.tv_sec * 1000LL) + (te.tv_usec / 1000);
            break;

        case kCGEventRightMouseUp:

            if ((((curClickTimeRight - prevClickTimeRight) < 
                  args->doubleClickTime)) && (args->rightPasteEnable == 1))
            {
                paste(event);
            }

            break;

        default:
            break;
    }

    // Pass on the event, we must not modify it anyway, we are a listener
    return event;
}
