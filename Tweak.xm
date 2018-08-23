#import "Common.h"
#import "EPCRingView.h"
#import "EPCPreferences.h"
#import "EPCPasscodeChangedAlertHandler.h"
#import <notify.h>

static BOOL screenIsLocked;

@interface EPCRingView (Private)
-(void)_setCachedPassword:(NSString*)password;
-(void)standardSetup;
-(BOOL)_needsSetup;
-(void)_setNeedsSetup:(BOOL)needed;
@end

@interface SBUIPasscodeLockViewSimpleFixedDigitKeypad : UIView
@end
@interface SBUISimpleFixedDigitPasscodeEntryField : UIView
@end

static void passcodeReceived(NSString* plainTextPassword)
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		if(!screenIsLocked) {
			if ([[EPCRingView sharedRingView] _needsSetup]) {
				//set passcode length
				NSLog(@"Writing passcode info to disk");
				NSDictionary *permission_prefs = [NSDictionary dictionaryWithObjectsAndKeys:
				@"mobile", NSFileOwnerAccountName,
				@"mobile", NSFileGroupOwnerAccountName,
				[NSNumber numberWithUnsignedLong:0777], NSFilePosixPermissions, nil];
				[[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Library/Preferences/Epicentre/" withIntermediateDirectories:YES attributes:permission_prefs error:nil];
				
				[[NSFileManager defaultManager] createFileAtPath:kPasscodeLengthPath contents:[[NSString stringWithFormat:@"%i", (int)plainTextPassword.length] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
				
				NSString* hashedStr = [plainTextPassword MD5String];
				[[NSFileManager defaultManager] createFileAtPath:kPasscodePath contents:[hashedStr dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
				[[EPCRingView sharedRingView] _setCachedPassword:hashedStr];
				[[EPCRingView sharedRingView] _setNeedsSetup:NO];
			}
		}
	});
}

%group Main


static SBUIPasscodeLockNumberPad* numberPad;
static UIView* _characterIndicatorsContainerView;
//remove the passcode dots
%hook SBUISimpleFixedDigitPasscodeEntryField
- (void)layoutSubviews
{
	%orig;
	_characterIndicatorsContainerView = MSHookIvar<UIView *>(self, "_characterIndicatorsContainerView");
	if (![EPCRingView sharedRingViewExist]) { return; }
	if ([[EPCRingView sharedRingView] _needsSetup]) { return; }
	
	
	_characterIndicatorsContainerView.alpha = 0;
}
%end


%hook SBDashBoardPasscodeViewController
- (void)loadView
{
	%orig;
	if (![EPCRingView sharedRingViewExist]) { return; }
	if ([[EPCRingView sharedRingView] _needsSetup]) { return; }
	
	[[EPCRingView sharedRingView] collapseAnimated:NO];
}
- (void)viewWillAppear:(BOOL)arg1
{
	%orig;
	if (![EPCRingView sharedRingViewExist]) { return; }
	if ([[EPCRingView sharedRingView] _needsSetup]) { return; }
	
	[[EPCRingView sharedRingView] collapseAnimated:NO];
	[[EPCRingView sharedRingView] expandAnimated:YES];
}
- (void)viewWillDisappear:(BOOL)arg1
{
	%orig;
	if (![EPCRingView sharedRingViewExist]) { return; }
	if ([[EPCRingView sharedRingView] _needsSetup]) { return; }
	
	[[EPCRingView sharedRingView] collapseAnimated:YES];
}
%end

%hook SBUIPasscodeLockViewSimpleFixedDigitKeypad
- (void)layoutSubviews
{
	%orig;
	if (![EPCRingView sharedRingViewExist]) { return; }
	((EPCRingView*)[EPCRingView sharedRingView]).center = self.center;
	[EPCRingView sharedRingView].tag = 45455;
	if(UIView* tabVi = [self viewWithTag:[EPCRingView sharedRingView].tag]) {
		[tabVi removeFromSuperview];
	}
	
	if ([[EPCRingView sharedRingView] _needsSetup]) {
		if(numberPad) {numberPad.alpha = 1;}
		if(_characterIndicatorsContainerView) {_characterIndicatorsContainerView.alpha = 1;}
		
		return;
	}
	if(numberPad) {numberPad.alpha = 0;}
	if(_characterIndicatorsContainerView) {_characterIndicatorsContainerView.alpha = 0;}
	[self addSubview:[EPCRingView sharedRingView]];
}
%end


//provide our own implementation for the number pad
%hook SBUIPasscodeLockNumberPad
- (void)setDelegate:(id)arg1
{
	%orig;
	numberPad = self;
}
%end

%hook SBLockScreenManager
-(void)attemptUnlockWithPasscode:(id)arg1 completion:(/*^block*/id)arg2
{
	%orig;
	passcodeReceived([arg1 copy]);
}
- (BOOL)attemptUnlockWithPasscode:(id)arg1
{
	BOOL r = %orig;
	passcodeReceived([arg1 copy]);
	return r;
}
- (BOOL)_attemptUnlockWithPasscode:(id)arg1 mesa:(BOOL)arg2 finishUIUnlock:(BOOL)arg3 completion:(id)arg4
{
	BOOL r = %orig;
	passcodeReceived([arg1 copy]);
	return r;
}
%end

%end

@interface SpringBoard : UIApplication
@end
@interface SpringBoard (Private)
-(void)_relaunchSpringBoardNow;
@end

static void respring()
{
	system("killall backboardd SpringBoard");//[(SpringBoard*)[UIApplication sharedApplication] _relaunchSpringBoardNow];
}

static void screenLockStatus(CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo)
{
    uint64_t state;
    int token;
    notify_register_check("com.apple.springboard.lockstate", &token);
    notify_get_state(token, &state);
    notify_cancel(token);
    if (state) {
        screenIsLocked = YES;
    } else {
		NSLog(@"device was unlocked");
        screenIsLocked = NO;
    }
}

%ctor {
	//if the tweak is disabled, quit
	if (![[EPCPreferences sharedInstance] isEnabled]) { return; }
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"com.apple.managedconfiguration.passcodechanged" object:nil queue:nil usingBlock:^(NSNotification* notification){
		[[NSFileManager defaultManager] removeItemAtPath:kPasscodePath error:nil];
		[[EPCRingView sharedRingView] _setNeedsSetup:YES];
		[[EPCRingView sharedRingView] _setCachedPassword:nil];
		
		//someone please find a better way to handle this besides killing SB
		EPCPasscodeChangedAlertHandler* alertHandler = [[EPCPasscodeChangedAlertHandler alloc] init];
		[alertHandler displayRespringAlert];
	}];
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)respring, CFSTR("com.phillipt.epicentre.respring"), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, screenLockStatus, CFSTR("com.apple.springboard.lockstate"), NULL, 0);
	//if (![[%c(SBDeviceLockController) sharedController] deviceHasPasscodeSet]) { return; }
	
	%init(Main);
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[[EPCRingView sharedRingView] standardSetup];
		if (![[EPCRingView sharedRingView] _needsSetup]) {
			[[EPCRingView sharedRingView] collapseAnimated:NO];
			[[EPCRingView sharedRingView] expandAnimated:YES];
		}
	}];
}
