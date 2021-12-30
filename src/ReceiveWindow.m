/*============================================================================*
 * (C) 2001-2010 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: ReceiveWindow.m
 *	Module		: メッセージ受信ウィンドウ		
 *============================================================================*/

#import "ReceiveWindow.h"
#import "ReceiveControl.h"
#import "DebugLog.h"

@implementation ReceiveWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag {
//	styleMask |= NSTexturedBackgroundWindowMask;
	return [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
}

- (void)keyDown:(NSEvent*)theEvent {
	// Enterキー入力時、返信処理を行う
	if ([theEvent keyCode] == 52) {
		id obj = [self delegate];
		if ([obj respondsToSelector:@selector(replyMessage:)]) {
//			DBG0(@"reply!(byEnter)");
			[obj replyMessage:self];
		}
	} else {
		[super keyDown:theEvent];
	}
//	DBG(@"keycode=%d", [theEvent keyCode]);
}

@end
