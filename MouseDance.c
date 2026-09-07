#include <ApplicationServices/ApplicationServices.h>
#include <signal.h>
#include <stdio.h>
#include <time.h>

static volatile sig_atomic_t keep_running = 1;

static void stop_running(int signal_number) {
    (void)signal_number;
    keep_running = 0;
}

static void pause_for(long seconds, long nanoseconds) {
    struct timespec requested = {.tv_sec = seconds, .tv_nsec = nanoseconds};
    struct timespec remaining;

    while (keep_running && nanosleep(&requested, &remaining) == -1) {
        requested = remaining;
    }
}

static void post_mouse_move(CGPoint point) {
    CGEventRef event = CGEventCreateMouseEvent(
        NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft
    );

    if (event != NULL) {
        CGEventPost(kCGHIDEventTap, event);
        CFRelease(event);
    }
}

static CGFloat horizontal_offset(CGPoint point) {
    CGDirectDisplayID displays[32];
    uint32_t count = 0;

    if (CGGetActiveDisplayList(32, displays, &count) == kCGErrorSuccess) {
        for (uint32_t index = 0; index < count; index++) {
            CGRect bounds = CGDisplayBounds(displays[index]);
            if (CGRectContainsPoint(bounds, point)) {
                return point.x + 1 < CGRectGetMaxX(bounds) ? 1 : -1;
            }
        }
    }

    return 1;
}

static void nudge_cursor(void) {
    CGEventRef current_event = CGEventCreate(NULL);
    if (current_event == NULL) {
        return;
    }

    CGPoint original = CGEventGetLocation(current_event);
    CFRelease(current_event);

    CGPoint nudged = original;
    nudged.x += horizontal_offset(original);

    post_mouse_move(nudged);
    pause_for(0, 80000000L);
    post_mouse_move(original);
}

int main(void) {
    signal(SIGINT, stop_running);
    signal(SIGTERM, stop_running);

    puts("MouseDance is running: nudging the pointer every 3 seconds.");
    puts("Press Control-C to stop.\n");

    while (keep_running) {
        nudge_cursor();
        pause_for(3, 0);
    }

    puts("\nMouseDance stopped.");
    return 0;
}
