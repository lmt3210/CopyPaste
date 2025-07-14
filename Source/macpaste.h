// Public Domain License 2016
//
// Simulate right-handed unix/linux X11 middle-mouse-click copy and paste.
//
// References:
// http://stackoverflow.com/questions/3134901/mouse-tracking-daemon
// http://stackoverflow.com/questions/2379867/
//     simulating-key-press-events-in-mac-os-x#2380280
//

#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h> // kVK_ANSI_*
#include <sys/time.h>      // gettimeofday
#include <CoreGraphics/CGEvent.h>

#define DEFAULT_DOUBLE_CLICK_MILLIS 1000

struct callbackArgs
{
    int copyEnable;        // for copy after left double click
    int dragEnable;        // for copy after left drag
    int pasteEnable;       // for paste after middle click
    int rightPasteEnable;  // for paste after right double click
    int displayPositionEnable;
    long long doubleClickTime;
    int verbose;
};

CGEventRef mouseCallback(CGEventTapProxy proxy, CGEventType type,
                         CGEventRef event, void *refcon);

