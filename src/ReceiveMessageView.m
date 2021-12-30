/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: ReceiveMessageView.m
 *	Module		: 受信メッセージ表示View
 *============================================================================*/

#import "ReceiveMessageView.h"
#import "Config.h"

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation ReceiveMessageView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		self.editable			= NO;
		self.backgroundColor	= NSColor.windowBackgroundColor;
		self.font				= Config.sharedConfig.receiveMessageFont;
		self.usesRuler			= YES;
	}
	return self;
}

- (void)changeFont:(id)sender
{
	self.font = [sender convertFont:self.font];
}

@end
