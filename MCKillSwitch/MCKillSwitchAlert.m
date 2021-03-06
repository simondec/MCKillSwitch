//
// Copyright (c) 2016, Mirego
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// - Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// - Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// - Neither the name of the Mirego nor the names of its contributors may
//   be used to endorse or promote products derived from this software without
//   specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "MCKillSwitchAlert.h"

#define STORE_PREFIX @"store:"

typedef void(^MCKillSwitchAlertBlock)(void);

//------------------------------------------------------------------------------
#pragma mark - Private interface
//------------------------------------------------------------------------------

@interface MCKillSwitchAlert ()

@property (nonatomic, readonly) id<MCKillSwitchInfo> killSwitchInfo;
@property (nonatomic, readonly) UIAlertController *alertView;
@end

//------------------------------------------------------------------------------
#pragma mark - Implementation
//------------------------------------------------------------------------------

@implementation MCKillSwitchAlert

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    
    return self;
}

//------------------------------------------------------------------------------
#pragma mark - Public methods
//------------------------------------------------------------------------------

- (void)showAlertForKillSwitchInfo:(id<MCKillSwitchInfo>)info
{
    _killSwitchInfo = info;
    
    NSArray *orderedButtons = [MCKillSwitchAlert orderedButtonsForButtons:self.killSwitchInfo.buttons];
    
    [self hideAlertWithCompletion:^{
        _alertView = [UIAlertController alertControllerWithTitle:@""
                                                         message:self.killSwitchInfo.message
                                                  preferredStyle:UIAlertControllerStyleAlert];

        [orderedButtons enumerateObjectsUsingBlock:^(id<MCKillSwitchInfoButton> button, NSUInteger idx, BOOL *stop) {
            [self.alertView addAction:[UIAlertAction actionWithTitle:button.title style:[self styleForButton:button] handler:^(UIAlertAction * _Nonnull action) {
                [self performActionForButtonAtIndex:idx];
                [self determineAlertDisplayState];
            }]];
        }];

        [[self topMostViewController] presentViewController:self.alertView animated:YES completion:nil];

        _showing = YES;

        [self.delegate killSwitchAlertDidShow:self];
    }];
}

- (UIViewController *)topMostViewController {
    UIViewController *topMostViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topMostViewController.presentedViewController) {
        topMostViewController = topMostViewController.presentedViewController;
    }
    
    return topMostViewController;
}

- (UIAlertActionStyle)styleForButton:(id<MCKillSwitchInfoButton>)button {
    switch(button.type) {
        case MCKillSwitchInfoButtonTypeURL:
            return UIAlertActionStyleDefault;
        case MCKillSwitchInfoButtonTypeCancel:
            return UIAlertActionStyleCancel;
    }
}

- (void)hideAlert {
    [self hideAlertWithCompletion:nil];
}

- (void)hideAlertWithCompletion:(MCKillSwitchAlertBlock)completion {
    if (self.showing) {
        [self.alertView dismissViewControllerAnimated:YES completion:^{
            if (completion) {
                completion();
            }
        }];
        _alertView = nil;
        _showing = NO;

        if ([self shouldHideAlertAfterButtonAction]) {
            // Call the delegate if the alert will be hidden completely, not when the alert is hidden to be shown right afterwards
            [self.delegate killSwitchAlertDidHide:self];
        }
    } else if (completion) {
        completion();
    }
}

- (void)destroyAlertView {
    _alertView = nil;
    _showing = NO;

    if ([self shouldHideAlertAfterButtonAction]) {
        // Call the delegate if the alert will be hidden completely, not when the alert is hidden to be shown right afterwards
        [self.delegate killSwitchAlertDidHide:self];
    }
}

- (BOOL)shouldHideAlertAfterButtonAction
{
    return (self.killSwitchInfo.action != MCKillSwitchActionKill);
}

//------------------------------------------------------------------------------
#pragma mark - Private methods
//------------------------------------------------------------------------------

+ (id<MCKillSwitchInfoButton>)cancelButtonForButtons:(NSArray *)buttons
{
    id<MCKillSwitchInfoButton> cancelButton = nil;
    
    for (id<MCKillSwitchInfoButton> button in buttons) {
        if (button.type == MCKillSwitchInfoButtonTypeCancel) {
            cancelButton = button;
            break;
        }
    }
    
    return cancelButton;
}

+ (NSArray *)urlButtonsForButtons:(NSArray *)buttons
{
    NSMutableArray *urlButtons = [NSMutableArray new];
    
    for (id<MCKillSwitchInfoButton> button in buttons) {
        if (button.type == MCKillSwitchInfoButtonTypeURL) {
            [urlButtons addObject:button];
        }
    }
    
    return urlButtons.count > 0 ? [[NSArray alloc] initWithArray:urlButtons] : nil;
}

+ (NSArray *)orderedButtonsForButtons:(NSArray *)buttons
{
    NSMutableArray *orderedButtons = [NSMutableArray new];
    
    id<MCKillSwitchInfoButton> cancelButton = [self cancelButtonForButtons:buttons];
    if (cancelButton) {
        [orderedButtons addObject:cancelButton];
    }
    
    NSArray *urlButtons = [self urlButtonsForButtons:buttons];
    if (urlButtons) {
        [orderedButtons addObjectsFromArray:urlButtons];
    }
    
    return orderedButtons.count > 0 ? [[NSArray alloc] initWithArray:orderedButtons] : nil;
}

- (BOOL)openURLForButton:(id<MCKillSwitchInfoButton>)button
{
    BOOL didOpenURL = NO;
    BOOL pathExists = button.urlPath && button.urlPath.length > 0;
    
    if (pathExists) {
        
        // If the URL begins with "store:", this is an ID to open the store. NOT Supported on tvOS
        #if !TARGET_OS_TV
        if ([button.urlPath hasPrefix:STORE_PREFIX]) {
            [self showStoreViewForUrl:button.urlPath];
            return YES;
        }
        #endif
        
        NSURL *url = [NSURL URLWithString:button.urlPath];
        didOpenURL = [[UIApplication sharedApplication] openURL:url];
    }
    
    return didOpenURL;
}

#if !TARGET_OS_TV
- (void)showStoreViewForUrl:(NSString*)url
{
    NSString *storeNumber = [url substringFromIndex:STORE_PREFIX.length];
    SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
    
    storeViewController.delegate = self;
    
    NSDictionary *parameters = @{SKStoreProductParameterITunesItemIdentifier:@([storeNumber integerValue])};
    
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    if (rootViewController) {
        [rootViewController presentViewController:storeViewController animated:YES completion:nil];
        
        [storeViewController loadProductWithParameters:parameters completionBlock:^(BOOL result, NSError * _Nullable error) {
            if (result) {
                [self hideAlert];
            }
        }];
    } else {
        [self determineAlertDisplayState];
    }
}
#endif

- (void)performActionForButtonAtIndex:(NSInteger)index
{
    NSArray *orderedButtons = [MCKillSwitchAlert orderedButtonsForButtons:self.killSwitchInfo.buttons];
    
    if (index >= 0 && index < orderedButtons.count) {
        id<MCKillSwitchInfoButton> button = orderedButtons[index];
        
        switch (button.type) {
            case MCKillSwitchInfoButtonTypeURL:
                [self openURLForButton:button];
                break;
                
            case MCKillSwitchInfoButtonTypeCancel:
                // NOP
                break;
        }
    }
}

- (void)determineAlertDisplayState
{
    if ([self shouldHideAlertAfterButtonAction]) {
        [self hideAlert];
        
    } else {
        [self showAlertForKillSwitchInfo:self.killSwitchInfo];
    }
}

//------------------------------------------------------------------------------
#pragma mark - SKStoreProductViewControllerDelegate (NOT available on tvOS
//------------------------------------------------------------------------------
#if !TARGET_OS_TV
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController dismissViewControllerAnimated:YES completion:nil];
    
    [self determineAlertDisplayState];
}
#endif

//------------------------------------------------------------------------------
#pragma mark - MCKillSwitchDelegate
//------------------------------------------------------------------------------

- (void)killSwitch:(MCKillSwitch *)killSwitch shouldShowKillSwitchInfo:(id<MCKillSwitchInfo>)info
{
    [self showAlertForKillSwitchInfo:info];
}

- (void)killSwitch:(MCKillSwitch *)killSwitch didNotNeedToShowKillSwitchInfo:(id<MCKillSwitchInfo>)info
{
    [self hideAlert];
}

@end
