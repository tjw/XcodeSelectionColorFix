#import <Cocoa/Cocoa.h>

#import "OBMethodReplacement.h"
#import <libkern/OSAtomic.h>
#import <crt_externs.h>

@interface com_omnigroup_XcodeSelectionColorFix : NSObject
@end
@implementation com_omnigroup_XcodeSelectionColorFix

static NSColor *(*original_secondarySelectedControlColor)(id self, SEL _cmd) = NULL;
static void (*original_drawBackgroundForGlyphRange)(id self, SEL _cmd, NSRange glyphsToShow, NSPoint origin) = NULL;
static int32_t drawBackgroundForGlyphRangeNesting = 0;

static void (*original_mouseInside)(id self, SEL _cmd, NSEvent *event) = NULL;

static Class DVTLayoutManager = Nil;
static Class DVTFontAndColorTheme = Nil;
static Class DVTSourceTextView = Nil;

#define REQUIRE_CLASS(x) \
do { \
    x = NSClassFromString((id)CFSTR(#x)); \
    if (!x) { \
        NSLog(@"%s: Unable to find class \"%s\"!", __PRETTY_FUNCTION__, #x); \
        return; \
    } \
} while (0)

#define REQUIRE_CLASS_METHOD(cls, name) \
do { \
    if (![cls respondsToSelector:@selector(name)]) { \
        NSLog(@"%s: \"%s\" doesn't respond to +%s.", __PRETTY_FUNCTION__, #cls, #name); \
        return; \
    } \
} while (0)

#define REQUIRE_INSTANCE_METHOD(cls, name) \
do { \
    if (![cls instancesRespondToSelector:@selector(name)]) { \
        NSLog(@"%s: Instances of \"%s\" don't respond to -%s.", __PRETTY_FUNCTION__, #cls, #name); \
        return; \
    } \
} while (0)

    
+ (void)load;
{
    // xcodebuild will load Xcode plugins too, but doesn't have the text related classes.  Don't emit warnings if running xcodebuild.
    char **progname = _NSGetProgname();
    if (progname && *progname && strstr(*progname, "xcodebuild") != NULL)
        return;
    
    // Could also check the superclasses of these, but that seems like overkill
    REQUIRE_CLASS(DVTLayoutManager);
    
    REQUIRE_CLASS(DVTFontAndColorTheme);
    REQUIRE_CLASS_METHOD(DVTFontAndColorTheme, currentTheme);
    REQUIRE_INSTANCE_METHOD(DVTFontAndColorTheme, sourceTextSelectionColor);
    REQUIRE_INSTANCE_METHOD(DVTFontAndColorTheme, consoleTextSelectionColor);
    
    REQUIRE_CLASS(DVTSourceTextView);
    
    original_secondarySelectedControlColor = (typeof(original_secondarySelectedControlColor))OBReplaceMethodImplementationWithSelectorOnClass(object_getClass([NSColor class]), @selector(secondarySelectedControlColor), self, @selector(replacement_secondarySelectedControlColor));
    if (!original_secondarySelectedControlColor) {
        NSLog(@"Unable to replace method.");
        return;
    }

    original_drawBackgroundForGlyphRange = (typeof(original_drawBackgroundForGlyphRange))OBReplaceMethodImplementationWithSelectorOnClass(DVTLayoutManager, @selector(drawBackgroundForGlyphRange:atPoint:), self, @selector(replacement_drawBackgroundForGlyphRange:atPoint:));
    if (!original_drawBackgroundForGlyphRange) {
        NSLog(@"Unable to replace method.");
        return;
    }

    original_mouseInside = (typeof(original_mouseInside))OBReplaceMethodImplementationWithSelectorOnClass(DVTSourceTextView, @selector(_mouseInside:), self, @selector(_mouseInside:));
    if (!original_mouseInside) {
        NSLog(@"Unable to replace method.");
        return;
    }
}

- (NSColor *)replacement_secondarySelectedControlColor;
{
    if (drawBackgroundForGlyphRangeNesting == 0)
        return original_secondarySelectedControlColor(self, _cmd);
    
    // Return a color interpolated between the user's background color and selection color.
    id theme = [DVTFontAndColorTheme performSelector:@selector(currentTheme)];
    NSColor *color0 = [[theme performSelector:@selector(sourceTextSelectionColor)] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor *color1 = [[theme performSelector:@selector(sourceTextBackgroundColor)] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return [color0 blendedColorWithFraction:0.5 ofColor:color1];
}

- (void)replacement_drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin;
{
    OSAtomicIncrement32(&drawBackgroundForGlyphRangeNesting);
    @try {
        original_drawBackgroundForGlyphRange(self, _cmd, glyphsToShow, origin);
    } @finally {
        OSAtomicDecrement32(&drawBackgroundForGlyphRangeNesting);
    }
}

// Normally the IBeamCursor is set by this hitting a implementation on NSTextView. I'm hooking it on DVTSourceTextView for now, but it might need to be more tightly tuned.
- (void)_mouseInside:(NSEvent *)event;
{
    static NSCursor *cursor = nil;
    
    if (!cursor) {
        NSString *imagePath = [[NSBundle bundleWithIdentifier:@"com.omnigroup.XcodeSelectionColorFix"] pathForImageResource:@"cursor"];
        if (!imagePath) {
            NSLog(@"No cursor image found!");
        } else {
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
            if (!image)
                NSLog(@"Unable to load cursor image");
            else
                cursor = [[NSCursor alloc] initWithImage:image hotSpot:[[NSCursor IBeamCursor] hotSpot]];
        }
        if (!cursor)
            cursor = [[NSCursor IBeamCursor] retain];
    }
    [cursor set];
}

@end
