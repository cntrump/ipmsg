/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: NoticeControl.h
 *	Module		: 通知ダイアログコントローラ
 *============================================================================*/

#import <Cocoa/Cocoa.h>

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface NoticeControl : NSObject <NSWindowDelegate>

@property(retain)	IBOutlet NSWindow*		window;			// ダイアログ
@property(weak)		IBOutlet NSTextField*	titleLabel;		// タイトルラベル
@property(weak)		IBOutlet NSTextField*	messageLabel;	// メッセージラベル
@property(weak)		IBOutlet NSTextField*	dateLabel;		// 日付ラベル

// 初期化
- (instancetype)initWithTitle:(NSString*)title
					  message:(NSString*)msg
						 date:(NSDate*)date;

@end
