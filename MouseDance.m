#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

static CGEventRef scrollEventCallback(CGEventTapProxy proxy, CGEventType type,
                                      CGEventRef event, void *userInfo);

@interface MouseDanceAppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic) NSTimeInterval interval;
@property(nonatomic) BOOL enabled;
@property(nonatomic) BOOL independentScrollingEnabled;
@property(nonatomic) BOOL mouseNatural;
@property(nonatomic) BOOL trackpadNatural;
@property(nonatomic) CFMachPortRef scrollEventTap;
@property(nonatomic) CFRunLoopSourceRef scrollRunLoopSource;
@end

@implementation MouseDanceAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.interval = [defaults doubleForKey:@"interval"];
    if (self.interval < 0.2) self.interval = 3.0;
    self.enabled = [defaults objectForKey:@"enabled"] == nil
        ? NO : [defaults boolForKey:@"enabled"];
    self.independentScrollingEnabled =
        [defaults objectForKey:@"independentScrollingEnabled"] == nil
        ? YES : [defaults boolForKey:@"independentScrollingEnabled"];
    self.mouseNatural = [defaults objectForKey:@"mouseNatural"] == nil
        ? NO : [defaults boolForKey:@"mouseNatural"];
    self.trackpadNatural = [defaults objectForKey:@"trackpadNatural"] == nil
        ? YES : [defaults boolForKey:@"trackpadNatural"];

    self.statusItem = [NSStatusBar.systemStatusBar
        statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.toolTip = @"MouseDance";
    [self rebuildMenu];
    [self scheduleTimer];
    [self requestAccessibilityPermission];
    [self setupScrollEventTap];
}

- (void)requestAccessibilityPermission {
    NSDictionary *options = @{
        (__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES
    };
    AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

- (void)saveSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setDouble:self.interval forKey:@"interval"];
    [defaults setBool:self.enabled forKey:@"enabled"];
    [defaults setBool:self.independentScrollingEnabled
               forKey:@"independentScrollingEnabled"];
    [defaults setBool:self.mouseNatural forKey:@"mouseNatural"];
    [defaults setBool:self.trackpadNatural forKey:@"trackpadNatural"];
}

- (NSString *)formattedInterval {
    if (fabs(self.interval - round(self.interval)) < 0.001) {
        return [NSString stringWithFormat:@"%.0f", self.interval];
    }
    return [NSString stringWithFormat:@"%.1f", self.interval];
}

- (void)rebuildMenu {
    self.statusItem.button.title = @"🐭";
    self.statusItem.button.toolTip = self.enabled
        ? @"MouseDance — pointer movement on"
        : @"MouseDance — pointer movement off";
    NSMenu *menu = [[NSMenu alloc] init];

    NSMenuItem *activeItem = [[NSMenuItem alloc]
        initWithTitle:@"Move pointer automatically"
        action:@selector(toggleActive:) keyEquivalent:@""];
    activeItem.target = self;
    activeItem.state = self.enabled ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:activeItem];
    [menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *heading = [[NSMenuItem alloc]
        initWithTitle:[NSString stringWithFormat:@"Move every %@ seconds", self.formattedInterval]
        action:nil keyEquivalent:@""];
    heading.enabled = NO;
    [menu addItem:heading];

    NSArray<NSNumber *> *choices = @[@3, @5, @10, @30, @60];
    for (NSNumber *choice in choices) {
        NSMenuItem *item = [[NSMenuItem alloc]
            initWithTitle:[NSString stringWithFormat:@"%@ seconds", choice]
            action:@selector(selectInterval:) keyEquivalent:@""];
        item.target = self;
        item.representedObject = choice;
        item.state = fabs(self.interval - choice.doubleValue) < 0.001
            ? NSControlStateValueOn : NSControlStateValueOff;
        [menu addItem:item];
    }

    NSMenuItem *customItem = [[NSMenuItem alloc]
        initWithTitle:@"Custom…" action:@selector(chooseCustomInterval:) keyEquivalent:@""];
    customItem.target = self;
    [menu addItem:customItem];
    [menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *scrollingItem = [[NSMenuItem alloc]
        initWithTitle:@"Independent scrolling"
        action:@selector(toggleIndependentScrolling:)
        keyEquivalent:@""];
    scrollingItem.target = self;
    scrollingItem.state = self.independentScrollingEnabled
        ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:scrollingItem];

    NSMenuItem *mouseDirectionItem = [[NSMenuItem alloc]
        initWithTitle:@"Mouse wheel direction" action:nil keyEquivalent:@""];
    mouseDirectionItem.submenu = [self directionMenuForTrackpad:NO];
    [menu addItem:mouseDirectionItem];

    NSMenuItem *trackpadDirectionItem = [[NSMenuItem alloc]
        initWithTitle:@"Trackpad direction" action:nil keyEquivalent:@""];
    trackpadDirectionItem.submenu = [self directionMenuForTrackpad:YES];
    [menu addItem:trackpadDirectionItem];
    [menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *aboutItem = [[NSMenuItem alloc]
        initWithTitle:@"About MouseDance" action:@selector(showAbout:) keyEquivalent:@""];
    aboutItem.target = self;
    [menu addItem:aboutItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc]
        initWithTitle:@"Quit MouseDance" action:@selector(quit:) keyEquivalent:@"q"];
    quitItem.target = self;
    [menu addItem:quitItem];
    self.statusItem.menu = menu;
}

- (NSMenu *)directionMenuForTrackpad:(BOOL)isTrackpad {
    NSMenu *directionMenu = [[NSMenu alloc] init];
    BOOL natural = isTrackpad ? self.trackpadNatural : self.mouseNatural;

    NSMenuItem *naturalItem = [[NSMenuItem alloc]
        initWithTitle:@"Natural (content follows movement)"
        action:@selector(selectScrollDirection:) keyEquivalent:@""];
    naturalItem.target = self;
    naturalItem.representedObject = @{
        @"trackpad": @(isTrackpad), @"natural": @YES
    };
    naturalItem.state = natural ? NSControlStateValueOn : NSControlStateValueOff;
    [directionMenu addItem:naturalItem];

    NSMenuItem *standardItem = [[NSMenuItem alloc]
        initWithTitle:@"Standard (wheel down scrolls down)"
        action:@selector(selectScrollDirection:) keyEquivalent:@""];
    standardItem.target = self;
    standardItem.representedObject = @{
        @"trackpad": @(isTrackpad), @"natural": @NO
    };
    standardItem.state = natural ? NSControlStateValueOff : NSControlStateValueOn;
    [directionMenu addItem:standardItem];

    return directionMenu;
}

- (void)scheduleTimer {
    [self.timer invalidate];
    self.timer = nil;
    if (!self.enabled) return;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.interval
        target:self selector:@selector(nudgeCursor:) userInfo:nil repeats:YES];
    self.timer.tolerance = MIN(0.2, self.interval * 0.1);
}

- (void)toggleActive:(id)sender {
    (void)sender;
    self.enabled = !self.enabled;
    [self saveSettings];
    [self scheduleTimer];
    [self rebuildMenu];
}

- (void)selectInterval:(NSMenuItem *)sender {
    [self setIntervalAndRefresh:[sender.representedObject doubleValue]];
}

- (void)toggleIndependentScrolling:(id)sender {
    (void)sender;
    self.independentScrollingEnabled = !self.independentScrollingEnabled;
    [self saveSettings];
    [self rebuildMenu];
}

- (void)selectScrollDirection:(NSMenuItem *)sender {
    NSDictionary *selection = sender.representedObject;
    BOOL natural = [selection[@"natural"] boolValue];
    if ([selection[@"trackpad"] boolValue]) {
        self.trackpadNatural = natural;
    } else {
        self.mouseNatural = natural;
    }
    self.independentScrollingEnabled = YES;
    [self saveSettings];
    [self rebuildMenu];
}

- (void)setIntervalAndRefresh:(NSTimeInterval)seconds {
    self.interval = seconds;
    [self saveSettings];
    [self scheduleTimer];
    [self rebuildMenu];
}

- (void)chooseCustomInterval:(id)sender {
    (void)sender;
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Custom movement interval";
    alert.informativeText = @"Enter a value from 0.2 to 3600 seconds.";
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
    field.stringValue = self.formattedInterval;
    alert.accessoryView = field;
    [alert.window setInitialFirstResponder:field];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        double value = field.doubleValue;
        if (value >= 0.2 && value <= 3600) {
            [self setIntervalAndRefresh:value];
        } else {
            NSBeep();
            NSAlert *warning = [[NSAlert alloc] init];
            warning.alertStyle = NSAlertStyleWarning;
            warning.messageText = @"Invalid interval";
            warning.informativeText = @"Please choose a number from 0.2 to 3600 seconds.";
            [warning addButtonWithTitle:@"OK"];
            [warning runModal];
        }
    }
}

- (void)setupScrollEventTap {
    if (self.scrollEventTap != NULL) return;

    CGEventMask mask = CGEventMaskBit(kCGEventScrollWheel);
    self.scrollEventTap = CGEventTapCreate(
        kCGSessionEventTap,
        kCGHeadInsertEventTap,
        kCGEventTapOptionDefault,
        mask,
        scrollEventCallback,
        (__bridge void *)self
    );

    if (self.scrollEventTap == NULL) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2000000000LL),
                       dispatch_get_main_queue(), ^{
            [self setupScrollEventTap];
        });
        return;
    }

    self.scrollRunLoopSource = CFMachPortCreateRunLoopSource(
        kCFAllocatorDefault, self.scrollEventTap, 0
    );
    CFRunLoopAddSource(CFRunLoopGetMain(), self.scrollRunLoopSource,
                       kCFRunLoopCommonModes);
    CGEventTapEnable(self.scrollEventTap, true);
}

- (BOOL)systemUsesNaturalScrolling {
    id value = [NSUserDefaults.standardUserDefaults
        objectForKey:@"com.apple.swipescrolldirection"];
    return value == nil ? YES : [value boolValue];
}

- (void)negateScrollField:(CGEventField)field inEvent:(CGEventRef)event {
    int64_t value = CGEventGetIntegerValueField(event, field);
    CGEventSetIntegerValueField(event, field, -value);
}

- (CGEventRef)processScrollEvent:(CGEventRef)event {
    if (!self.independentScrollingEnabled) return event;

    BOOL isTrackpad = CGEventGetIntegerValueField(
        event, kCGScrollWheelEventIsContinuous
    ) != 0;
    BOOL desiredNatural = isTrackpad ? self.trackpadNatural : self.mouseNatural;
    if (desiredNatural == [self systemUsesNaturalScrolling]) return event;

    CGEventField fields[] = {
        kCGScrollWheelEventDeltaAxis1,
        kCGScrollWheelEventDeltaAxis2,
        kCGScrollWheelEventDeltaAxis3,
        kCGScrollWheelEventFixedPtDeltaAxis1,
        kCGScrollWheelEventFixedPtDeltaAxis2,
        kCGScrollWheelEventFixedPtDeltaAxis3,
        kCGScrollWheelEventPointDeltaAxis1,
        kCGScrollWheelEventPointDeltaAxis2,
        kCGScrollWheelEventPointDeltaAxis3,
    };
    size_t count = sizeof(fields) / sizeof(fields[0]);
    for (size_t index = 0; index < count; index++) {
        [self negateScrollField:fields[index] inEvent:event];
    }
    return event;
}

- (CGFloat)horizontalOffsetForPoint:(CGPoint)point {
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

- (void)postMouseMove:(CGPoint)point {
    CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point,
                                               kCGMouseButtonLeft);
    if (event != NULL) {
        CGEventPost(kCGHIDEventTap, event);
        CFRelease(event);
    }
}

- (void)nudgeCursor:(NSTimer *)timer {
    (void)timer;
    CGEventRef currentEvent = CGEventCreate(NULL);
    if (currentEvent == NULL) return;
    CGPoint original = CGEventGetLocation(currentEvent);
    CFRelease(currentEvent);

    CGPoint nudged = original;
    nudged.x += [self horizontalOffsetForPoint:original];
    [self postMouseMove:nudged];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 80000000LL),
                   dispatch_get_main_queue(), ^{
        CGEventRef latestEvent = CGEventCreate(NULL);
        if (latestEvent == NULL) return;
        CGPoint latest = CGEventGetLocation(latestEvent);
        CFRelease(latestEvent);
        if (fabs(latest.x - nudged.x) < 0.1 && fabs(latest.y - nudged.y) < 0.1) {
            [self postMouseMove:original];
        }
    });
}

- (void)showAbout:(id)sender {
    (void)sender;
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"MouseDance";
    alert.informativeText = [NSString stringWithFormat:
        @"MouseDance gently moves the pointer to keep your Mac active and "
         "allows separate mouse and trackpad scroll directions.\n\n"
         "Current interval: %@ seconds\n\n"
         "macOS may require permission in System Settings → "
         "Privacy & Security → Accessibility.", self.formattedInterval];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    if (self.scrollRunLoopSource != NULL) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), self.scrollRunLoopSource,
                              kCFRunLoopCommonModes);
        CFRelease(self.scrollRunLoopSource);
        self.scrollRunLoopSource = NULL;
    }
    if (self.scrollEventTap != NULL) {
        CFRelease(self.scrollEventTap);
        self.scrollEventTap = NULL;
    }
}

- (void)quit:(id)sender {
    (void)sender;
    [NSApp terminate:nil];
}

@end

static CGEventRef scrollEventCallback(CGEventTapProxy proxy, CGEventType type,
                                      CGEventRef event, void *userInfo) {
    (void)proxy;
    MouseDanceAppDelegate *delegate = (__bridge MouseDanceAppDelegate *)userInfo;

    if (type == kCGEventTapDisabledByTimeout ||
        type == kCGEventTapDisabledByUserInput) {
        if (delegate.scrollEventTap != NULL) {
            CGEventTapEnable(delegate.scrollEventTap, true);
        }
        return event;
    }

    if (type == kCGEventScrollWheel) {
        return [delegate processScrollEvent:event];
    }
    return event;
}

int main(int argc, const char *argv[]) {
    (void)argc;
    (void)argv;
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        MouseDanceAppDelegate *delegate = [[MouseDanceAppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
