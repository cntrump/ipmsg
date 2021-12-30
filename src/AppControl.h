/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: AppControl.h
 *	Module		: アプリケーションコントローラ
 *============================================================================*/

#import <Cocoa/Cocoa.h>

@class RecvMessage;
@class SendControl;

/*============================================================================*
 * Notification 通知キー
 *============================================================================*/

/// ホスト名変更
extern NSString* const kIPMsgHostNameChangedNotification;
/// ネットワーク検出
extern NSString* const kIPMsgNetworkGainedNotification;
/// ネットワーク喪失通知
extern NSString* const kIPMsgNetworkLostNotification;

/*============================================================================*
 * 関数定義
 *============================================================================*/

// ホスト名取得
extern NSString* AppControlGetHostName(void);

// IPアドレス取得
extern UInt32 AppControlGetIPAddress(void);

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface AppControl : NSObject <NSApplicationDelegate>
{
	IBOutlet NSMenu*		absenceMenu;					// 不在メニュー
	IBOutlet NSMenuItem*	absenceOffMenuItem;				// 不在解除メニュー項目
	IBOutlet NSMenu*		absenceMenuForDock;				// Dock用不在メニュー
	IBOutlet NSMenuItem*	absenceOffMenuItemForDock;		// Dock用不在解除メニュー項目
	IBOutlet NSMenu*		absenceMenuForStatusBar;		// ステータスバー用不在メニュー
	IBOutlet NSMenuItem*	absenceOffMenuItemForStatusBar;	// ステータスバー用不在解除メニュー項目

	IBOutlet NSMenuItem*	showNonPopupMenuItem;			// ノンポップアップ表示メニュー項目

	IBOutlet NSMenuItem*	sendWindowListUserMenuItem;		// 送信ウィンドウユーザ一覧ユーザメニュー項目
	IBOutlet NSMenuItem*	sendWindowListGroupMenuItem;	// 送信ウィンドウユーザ一覧グループメニュー項目
	IBOutlet NSMenuItem*	sendWindowListHostMenuItem;		// 送信ウィンドウユーザ一覧ホストメニュー項目
	IBOutlet NSMenuItem*	sendWindowListIPAddressMenuItem;// 送信ウィンドウユーザ一覧IPアドレスメニュー項目
	IBOutlet NSMenuItem*	sendWindowListLogonMenuItem;	// 送信ウィンドウユーザ一覧ログオンメニュー項目
	IBOutlet NSMenuItem*	sendWindowListVersionMenuItem;	// 送信ウィンドウユーザ一覧バージョンメニュー項目

	IBOutlet NSMenu*		statusBarMenu;					// ステータスバー用のメニュー
}

// メッセージ送受信／ウィンドウ関連処理
- (IBAction)newMessage:(id)sender;
- (void)receiveMessage:(RecvMessage*)msg;
- (IBAction)closeAllWindows:(id)sender;
- (IBAction)closeAllDialogs:(id)sender;
- (IBAction)showNonPopupMessage:(id)sender;

// 不在関連処理
- (IBAction)absenceMenuChanged:(id)sender;
- (void)buildAbsenceMenu;
- (void)setAbsenceOff;

// ステータスバー関連
- (IBAction)clickStatusBar:(id)sender;
- (void)initStatusBar;
- (void)removeStatusBar;

// その他
- (IBAction)gotoHomePage:(id)sender;
- (IBAction)showAcknowledgement:(id)sender;
- (IBAction)openLog:(id)sender;

@end
