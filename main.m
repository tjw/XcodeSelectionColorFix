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

static Class XCLayoutManager = Nil;
static Class XCTextView = Nil;

#define REQUIRE_CLASS(x) \
do { \
    x = NSClassFromString((id)CFSTR(#x)); \
    if (!x) { \
        NSLog(@"%s: Unable to find class '%s'!", __PRETTY_FUNCTION__, #x); \
        return; \
    } \
} while (0)

#define REQUIRE_METHOD(object, name) \
do { \
    if (![object respondsToSelector:@selector(name)]) { \
        NSLog(@"%s: '%s' doesn't respond to '%s'.", __PRETTY_FUNCTION__, #object, #name); \
        return; \
    } \
} while (0)

    
+ (void)load;
{
    // xcodebuild will load Xcode plugins too, but doesn't have the text related classes.  Don't emit warnings if running xcodebuild.
    char **progname = _NSGetProgname();
    if (progname && strstr(*progname, "xcodebuild") != NULL)
        return;
    
    // Could also check the superclasses of these, but that seems like overkill
    REQUIRE_CLASS(XCLayoutManager);
    
    REQUIRE_CLASS(XCTextView);
    REQUIRE_METHOD(XCTextView, textEditorBackgroundColor);
    REQUIRE_METHOD(XCTextView, textEditorSelectionBackgroundColor);
    
    original_secondarySelectedControlColor = (typeof(original_secondarySelectedControlColor))OBReplaceMethodImplementationWithSelectorOnClass(object_getClass([NSColor class]), @selector(secondarySelectedControlColor), self, @selector(replacement_secondarySelectedControlColor));
    if (!original_secondarySelectedControlColor) {
        NSLog(@"Unable to replace method.");
        return;
    }

    original_drawBackgroundForGlyphRange = (typeof(original_drawBackgroundForGlyphRange))OBReplaceMethodImplementationWithSelectorOnClass(XCLayoutManager, @selector(drawBackgroundForGlyphRange:atPoint:), self, @selector(replacement_drawBackgroundForGlyphRange:atPoint:));
    if (!original_drawBackgroundForGlyphRange) {
        NSLog(@"Unable to replace method.");
        return;
    }
}

- (NSColor *)replacement_secondarySelectedControlColor;
{
    if (drawBackgroundForGlyphRangeNesting == 0)
        return original_secondarySelectedControlColor(self, _cmd);
    
    // Return a color interpolated between the user's background color and selection color.
    NSColor *color0 = [[XCTextView performSelector:@selector(textEditorBackgroundColor)] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor *color1 = [[XCTextView performSelector:@selector(textEditorSelectionBackgroundColor)] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

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

@end
