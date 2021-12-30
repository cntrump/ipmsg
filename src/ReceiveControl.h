/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: ReceiveControl.h
 *	Module		: 受信メッセージウィンドウコントローラ
 *============================================================================*/

#import <Cocoa/Cocoa.h>

@class RecvMessage;

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface ReceiveControl : NSObject <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property(retain)	IBOutlet NSWindow*				window;						// ウィンドウ
@property(weak)		IBOutlet NSBox*					infoBox;					// ヘッダ部BOX
@property(weak)		IBOutlet NSTextField*			userNameLabel;				// 送信元ユーザ名ラベル
@property(weak)		IBOutlet NSTextField*			dateLabel;					// 受信日時ラベル
@property(weak)		IBOutlet NSButton*				altLogButton;				// 重要ログボタン
@property(weak)		IBOutlet NSButton*				quotCheck;					// 引用チェックボックス
@property(weak)		IBOutlet NSButton*				replyButton;				// 返信ボタン
@property(weak)		IBOutlet NSButton*				sealButton;					// 封書ボタン（メッセージ部のカバー）
@property(weak)		IBOutlet NSTextView*			messageArea;				// メッセージ部
@property(weak)		IBOutlet NSButton*				attachButton;				// 添付ボタン
@property(weak)		IBOutlet NSDrawer*				attachDrawer;				// 添付ファイルDrawer
@property(weak)		IBOutlet NSTableView*			attachTable;				// 添付ファイル一覧
@property(weak)		IBOutlet NSButton*				attachSaveButton;			// 添付保存ボタン
@property(retain)	IBOutlet NSPanel*				pwdSheet;					// パスワード入力パネル（シート）
@property(weak)		IBOutlet NSTextField*			pwdSheetErrorLabel;			// パスワード入力パネルエラーラベル
@property(weak)		IBOutlet NSSecureTextField*		pwdSheetField;				// パスワード入力パネルテキストフィールド
@property(retain)	IBOutlet NSPanel*				attachSheet;				// ダウンロードシート
@property(weak)		IBOutlet NSTextField*			attachSheetTitleLabel;		// ダウンロードシートタイトルラベル
@property(weak)		IBOutlet NSTextField*			attachSheetSpeedLabel;		// ダウンロードシート転送速度ラベル
@property(weak)		IBOutlet NSTextField*			attachSheetFileNameLabel;	// ダウンロードシートファイル名ラベル
@property(weak)		IBOutlet NSTextField*			attachSheetPercentageLabel;	// ダウンロードシート％ラベル
@property(weak)		IBOutlet NSTextField*			attachSheetFileNumLabel;	// ダウンロードシートファイル数ラベル
@property(weak)		IBOutlet NSTextField*			attachSheetDirNumLabel;		// ダウンロードシートフォルダ数ラベル
@property(weak)		IBOutlet NSTextField*			attachSheetSizeLabel;		// ダウンロードシートサイズラベル
@property(weak)		IBOutlet NSProgressIndicator*	attachSheetProgress;		// ダウンロードシートプログレスバー
@property(weak)		IBOutlet NSButton*				attachSheetCancelButton;	// ダウンロードシートキャンセルボタン

/// 受信メッセージ
@property(readonly)	RecvMessage*					recvMsg;					// 受信メッセージ

// 初期化（ウィンドウは表示しない）
- (instancetype)initWithRecvMessage:(RecvMessage*)msg;
// ウィンドウの表示
- (void)showWindow;
// ハンドラ
- (IBAction)buttonPressed:(id)sender;
- (IBAction)openSeal:(id)sender;
- (IBAction)replyMessage:(id)sender;
- (IBAction)writeAlternateLog:(id)sender;
- (IBAction)okPwdSheet:(id)sender;
- (IBAction)cancelPwdSheet:(id)sender;
- (IBAction)showReceiveMessageFontPanel:(id)sender;
- (IBAction)saveReceiveMessageFont:(id)sender;
- (IBAction)resetReceiveMessageFont:(id)sender;
// その他
- (IBAction)backWindowToFront:(id)sender;

@end
