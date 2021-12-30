/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: NoticeControl.m
 *	Module		: 通知ダイアログコントローラ
 *============================================================================*/

#import "NoticeControl.h"

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation NoticeControl

// 初期化
- (instancetype)initWithTitle:(NSString*)title message:(NSString*)msg date:(NSDate*)date
{
	self = [super init];
	if (self) {
		// nibファイルロード
		if (![NSBundle.mainBundle loadNibNamed:@"NoticeDialog"
										 owner:self
							   topLevelObjects:nil]) {
			[self release];
			return nil;
		}

		if (!date) {
			date = [NSDate date];
		}

		// 表示文字列設定
		_titleLabel.stringValue		= title;
		_messageLabel.stringValue	= msg;
		_dateLabel.objectValue		= date;

		// 画面表示位置計算
		NSSize	screenSize = NSScreen.mainScreen.visibleFrame.size;
		NSRect	windowRect = _window.frame;
		NSPoint	centerPoint;
		int		sw, sh, ww, wh;
		sw	= screenSize.width;
		sh	= screenSize.height;
		ww	= windowRect.size.width;
		wh	= windowRect.size.height;
		centerPoint.x = (sw - ww) / 2 + (arc4random_uniform(INT32_MAX) % (sw / 4)) - sw / 8;
		centerPoint.y = (sh - wh) / 2 + (arc4random_uniform(INT32_MAX) % (sh / 4)) - sh / 8;

		_window.frameOrigin	= centerPoint;

		// ウィンドウメニューから除外
		_window.excludedFromWindowsMenu	= YES;

		// ダイアログ表示
		[_window makeKeyAndOrderFront:self];
	}

	return self;
}

// ウィンドウクローズ時処理
- (void)windowWillClose:(NSNotification*)aNotification
{
	[self release];
}

@end
