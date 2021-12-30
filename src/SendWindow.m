/*============================================================================*
 * (C) 2001-2003 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: SendWindow.m
 *	Module		: メッセージ送信ウィンドウ		
 *============================================================================*/
 
#import "SendWindow.h"
#import "SendControl.h"
#import "DebugLog.h"

@implementation SendWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag {
//	styleMask |= NSTexturedBackgroundWindowMask;
	self = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
	return self;
}

- (void)keyDown:(NSEvent*)theEvent {
	// Enterキー入力時、送信処理を行う
	if (([theEvent keyCode] == 52) &&
		([[self delegate] respondsToSelector:@selector(sendMessage:)])) {
//		DBG0(@"send!(byEnter)");
		[[self delegate] sendMessage:self];
	} else {
		[super keyDown:theEvent];
	}
//	DBG1(@"keycode=%d", [theEvent keyCode]);
}

@end
