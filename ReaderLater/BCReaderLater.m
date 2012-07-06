//
//  BCReaderLater.m
//  ReaderLater
//
//  Created by Ben Cochran on 7/5/12.
//  Copyright (c) 2012 Ben Cochran. All rights reserved.
//

#import "BCReaderLater.h"
#import "JRSwizzle.h"

#define BCLocalizedString(key, comment) [[NSBundle bundleForClass:[BCReaderLater class]] localizedStringForKey:(key) value:@"" table:nil]


@interface BCReaderLater()
+ (NSString *)pluginVersion;
@end

@implementation BCReaderLater

- (id)init
{
    self = [super init];
    if (self) {
        NSError *error = nil;
        
        Class class_BrowserWindowControllerMac = NSClassFromString(@"BrowserWindowControllerMac");
        Class class_ReaderButton = NSClassFromString(@"ReaderButton");
        [class_BrowserWindowControllerMac jr_swizzleMethod:@selector(toggleReader:) withMethod:@selector(BCReaderLater_toggleReader:) error:&error];
        if (error) {
            NSLog(@"Could not swizzle -[BrowserWindowControllerMac toggleReader:]: %@", error);
        } else {
            error = nil;
            [class_BrowserWindowControllerMac jr_swizzleMethod:@selector(updateReaderButton) withMethod:@selector(BCReaderLater_updateReaderButton) error:&error];
            if (error) {
                NSLog(@"Could not swizzle -[BrowserWindowControllerMac updateReaderButton]: %@", error);
            }
            
            error = nil;
            [class_ReaderButton jr_swizzleMethod:@selector(_toolTipForReaderButtonState:) withMethod:@selector(BCReaderLater__toolTipForReaderButtonState:) error:&error];
            if (error) {
                NSLog(@"Could not swizzle -[ReaderButton _toolTipForReaderButtonState:]: %@", error);
            }
        }
    }
    return self;
}

+ (NSString *)pluginVersion
{
    return [[[NSBundle bundleForClass:self] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (BCReaderLater *)sharedInstance
{
    static BCReaderLater *sharedInstance = nil;
    
    if (sharedInstance == nil) {
        sharedInstance = [[BCReaderLater alloc] init];
    }
    
    return sharedInstance;
}

+ (void)load
{
    [self sharedInstance];
    NSLog(@"ReaderLater %@ Loaded", [self pluginVersion]);
}

@end


#pragma mark - ReaderButton

@interface NSButton(BCReaderLater)
- (id)BCReaderLater__toolTipForReaderButtonState:(int)arg1;
@end

@implementation NSButton(BCReaderLater)

- (id)BCReaderLater__toolTipForReaderButtonState:(int)arg1
{
    return BCLocalizedString(@"Save to Instapaper", @"Later button tooltip.");
}

@end


#pragma mark - BrowserWindowControllerMac

@interface NSWindowController(BCReaderLater)
- (void)BCReaderLater_toggleReader:(id)arg1;
- (void)BCReaderLater_updateReaderButton;
@end

@implementation NSWindowController(BCReaderLater)

- (void)BCReaderLater_toggleReader:(id)arg1
{
    NSString *instapaperBookmarkletString = @"function iprl5(){var d=document,z=d.createElement('scr'+'ipt'),b=d.body,l=d.location;try{if(!b)throw(0);d.title='(Saving...) '+d.title;z.setAttribute('src',l.protocol+'//www.instapaper.com/j/ZkKUqxBKbJMs?u='+encodeURIComponent(l.href)+'&t='+(new Date().getTime()));b.appendChild(z);}catch(e){alert('Please wait until the page has loaded.');}}iprl5();void(0)";
    
    id browserDocument = [self valueForKey:@"_document"];
    if ([browserDocument respondsToSelector:@selector(evaluateJavaScript:)]) {
        [browserDocument performSelector:@selector(evaluateJavaScript:) withObject:instapaperBookmarkletString];
    } else {
        [self BCReaderLater_toggleReader:arg1];
    }
}

- (void)BCReaderLater_updateReaderButton
{
    [self BCReaderLater_updateReaderButton];
    
    id readerButton = [[self valueForKey:@"_toolbarController"] performSelector:@selector(readerButton)];
    
    SEL stateSelector = @selector(setReaderButtonState:animate:);
    if ([readerButton respondsToSelector:stateSelector]) {
        // Always make the button active (state "2" apparently)
        // In the future, this should check to make sure the page is loaded
        // and set the state accordingly, but always active will do for now.
        NSMethodSignature *methodSignature = [[readerButton class] instanceMethodSignatureForSelector:stateSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        
        [invocation setSelector:stateSelector];
        [invocation setTarget:readerButton];
        NSInteger state = 2;
        BOOL animate = NO;
        [invocation setArgument:&state atIndex:2];
        [invocation setArgument:&animate atIndex:3];
        [invocation invoke];
    }
    
    if ([readerButton respondsToSelector:@selector(setTitle:)]) {
        [readerButton setTitle:BCLocalizedString(@"Later", @"The replacement button title.")];
    }
}

@end