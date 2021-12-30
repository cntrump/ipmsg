/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: SendControl.h
 *	Module		: 送信メッセージウィンドウコントローラ
 *============================================================================*/

#import <Cocoa/Cocoa.h>

@class RecvMessage;

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface SendControl : NSObject <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate>

@property(retain)	IBOutlet NSWindow*		window;				// 送信ウィンドウ
@property(weak)		IBOutlet NSSplitView*	splitView;			// 上下分割View
@property(weak)		IBOutlet NSView*		splitSubview1;		// 上側View
@property(weak)		IBOutlet NSView*		splitSubview2;		// 下側View
@property(weak)		IBOutlet NSSearchField*	searchField;		// ユーザ検索フィールド
@property(weak)		IBOutlet NSMenu*		searchMenu;			// ユーザ検索メニュー
@property(weak)		IBOutlet NSTableView*	userTable;			// ユーザ一覧
@property(weak)		IBOutlet NSTextField*	userNumLabel;		// ユーザ数ラベル
@property(weak)		IBOutlet NSButton*		refreshButton;		// 更新ボタン
@property(weak)		IBOutlet NSButton*		passwordCheck;		// 鍵チェックボックス
@property(weak)		IBOutlet NSButton*		sealCheck;			// 封書チェックボックス
@property(weak)		IBOutlet NSTextView*	messageArea;		// メッセージ入力欄
@property(weak)		IBOutlet NSButton*		sendButton;			// 送信ボタン
@property(weak)		IBOutlet NSButton*		attachButton;		// 添付ファイルDrawerトグルボタン
@property(weak)		IBOutlet NSDrawer*		attachDrawer;		// 添付ファイルDrawer
@property(weak)		IBOutlet NSTableView*	attachTable;		// 添付ファイル一覧
@property(weak)		IBOutlet NSButton*		attachAddButton;	// 添付追加ボタン
@property(weak)		IBOutlet NSButton*		attachDelButton;	// 添付削除ボタン

/// 返信元メッセージ
@property(readonly)	RecvMessage*	recvMsg;

// 初期化
- (instancetype)initWithSendMessage:(NSString*)msg
						recvMessage:(RecvMessage*)recv;

// ハンドラ
- (IBAction)buttonPressed:(id)sender;
- (IBAction)checkboxChanged:(id)sender;

- (IBAction)searchUser:(id)sender;
- (IBAction)updateUserSearch:(id)sender;
- (IBAction)searchMenuItemSelected:(id)sender;

- (IBAction)sendPressed:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)userListUserMenuItemSelected:(id)sender;
- (IBAction)userListGroupMenuItemSelected:(id)sender;
- (IBAction)userListHostMenuItemSelected:(id)sender;
- (IBAction)userListIPAddressMenuItemSelected:(id)sender;
- (IBAction)userListLogonMenuItemSelected:(id)sender;
- (IBAction)userListVersionMenuItemSelected:(id)sender;
- (void)userListChanged:(NSNotification*)aNotification;

// 添付ファイル
- (void)appendAttachmentByPath:(NSString*)path;

// その他
- (IBAction)updateUserList:(id)sender;
- (NSWindow*)window;
- (void)setAttachHeader;

@end
