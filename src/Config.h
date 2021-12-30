/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: Config.h
 *	Module		: 初期設定情報管理クラス
 *============================================================================*/

#import <Cocoa/Cocoa.h>

@class UserInfo;
@class RefuseInfo;

/*============================================================================*
 * 定数定義
 *============================================================================*/

// ノンポップアップ受信アイコンバウンド種別
typedef NS_ENUM(NSInteger, IPMsgIconBoundType)
{
	IPMSG_BOUND_ONECE	= 0,
	IPMSG_BOUND_REPEAT	= 1,
	IPMSG_BOUND_NONE	= 2
};

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface Config : NSObject

// 全般
@property(copy)		NSString*			userName;					// ユーザ名
@property(copy)		NSString*			groupName;					// グループ名
@property(copy)		NSString*			password;					// パスワード
@property(assign)	UInt32 				rsa1024PublicKeyExponent;	// RSA1024公開鍵：指数
@property(copy)		NSData*				rsa1024PublicKeyModulus;	// RSA1024公開鍵：法
@property(assign)	UInt32 				rsa2048PublicKeyExponent;	// RSA2048公開鍵：指数
@property(copy)		NSData*				rsa2048PublicKeyModulus;	// RSA2048公開鍵：法
@property(assign)	BOOL				useStatusBar;				// メニューバーの右端にアイコンを追加するか
// ネットワーク
@property(assign)	NSInteger			portNo;						// ポート番号
@property(assign)	BOOL				dialup;						// ダイアルアップ接続
@property(readonly)	NSArray<NSString*>*	broadcastAddresses;			// ブロードキャストアドレス一覧
@property(readonly) NSUInteger			numberOfBroadcasts;			// ブロードキャストアドレス数
// アップデート
@property(assign)	BOOL				updateAutomaticCheck;		// 更新自動チェック
@property(assign)	NSTimeInterval		updateCheckInterval;		// 更新チェック間隔
// 不在モード
@property(readonly)	BOOL				inAbsence;					// 不在モード中か
@property(readonly)	NSUInteger			numberOfAbsences;			// 不在モード数
@property(assign)	NSInteger			absenceIndex;				// 不在モード
// 通知拒否
@property(readonly)	NSUInteger			numberOfRefuseInfo;			// 拒否設定数
// 送信
@property(copy)		NSString*			quoteString;				// 引用文字列
@property(assign)	BOOL				openNewOnDockClick;			// Dockクリック時送信ウィンドウオープン
@property(assign)	BOOL				sealCheckDefault;			// 封書チェックをデフォルト
@property(assign)	BOOL				hideReceiveWindowOnReply;	// 送信時受信ウィンドウをクローズ
@property(assign)	BOOL				noticeSealOpened;			// 開封確認を行う
@property(assign)	BOOL				allowSendingToMultiUser;	// 複数ユーザ宛送信を許可
@property(retain)	NSFont*				sendMessageFont;			// 送信ウィンドウメッセージ部フォント
@property(readonly)	NSFont*				defaultSendMessageFont;		// 送信ウィンドウメッセージ標準フォント
// 受信
@property(readonly)	NSSound*			receiveSound;				// 受信音
@property(copy)		NSString*			receiveSoundName;			// 受信音名
@property(assign)	BOOL				quoteCheckDefault;			// 引用チェックをデフォルト
@property(assign)	BOOL				nonPopup;					// ノンポップアップ受信
@property(assign)	BOOL				nonPopupWhenAbsence;		// 不在時ノンポップアップ受信
@property(assign)	IPMsgIconBoundType	iconBoundModeInNonPopup;	// ノンポップアップ受信時アイコンバウンド種別
@property(assign)	BOOL				useClickableURL;			// クリッカブルURLを使用する
@property(retain)	NSFont*				receiveMessageFont;			// 受信ウィンドウメッセージ部フォント
@property(readonly)	NSFont*				defaultReceiveMessageFont;	// 受信ウィンドウメッセージ標準フォント
// ログ
@property(assign)	BOOL				standardLogEnabled;			// 標準ログを使用する
@property(assign)	BOOL				logChainedWhenOpen;			// 錠前付きは開封時にログ
@property(copy)		NSString*			standardLogFile;			// 標準ログファイルパス
@property(assign)	BOOL				alternateLogEnabled;		// 重要ログを使用する
@property(assign)	BOOL				logWithSelectedRange;		// 選択範囲を記録する
@property(copy)		NSString*			alternateLogFile;			// 重要ログファイルパス
// 送受信ウィンドウ
@property(assign)	NSSize				sendWindowSize;				// 送信ウィンドウサイズ
@property(assign)	float				sendWindowSplit;			// 送信ウィンドウ分割位置
@property(assign)	BOOL				sendSearchByUserName;		// 送信ユーザ検索（ユーザ名）
@property(assign)	BOOL				sendSearchByGroupName;		// 送信ユーザ検索（グループ名）
@property(assign)	BOOL				sendSearchByHostName;		// 送信ユーザ検索（ホスト名）
@property(assign)	BOOL				sendSearchByLogOnName;		// 送信ユーザ検索（ログオン名）
@property(assign)	NSSize				receiveWindowSize;			// 受信ウィンドウサイズ

// ファクトリ
+ (Config*)sharedConfig;

// 永続化
- (void)save;

// ----- getter / setter ------
// ネットワーク
- (NSString*)broadcastAtIndex:(NSUInteger)index;
- (BOOL)containsBroadcastWithAddress:(NSString*)address;
- (BOOL)containsBroadcastWithHost:(NSString*)host;
- (void)addBroadcastWithAddress:(NSString*)address;
- (void)addBroadcastWithHost:(NSString*)host;
- (void)removeBroadcastAtIndex:(NSUInteger)index;

// 不在
- (NSString*)absenceTitleAtIndex:(NSUInteger)index;
- (NSString*)absenceMessageAtIndex:(NSUInteger)index;
- (BOOL)containsAbsenceTitle:(NSString*)title;
- (void)addAbsenceTitle:(NSString*)title message:(NSString*)msg;
- (void)insertAbsenceTitle:(NSString*)title message:(NSString*)msg atIndex:(NSUInteger)index;
- (void)setAbsenceTitle:(NSString*)title message:(NSString*)msg atIndex:(NSInteger)index;
- (void)upAbsenceAtIndex:(NSUInteger)index;
- (void)downAbsenceAtIndex:(NSUInteger)index;
- (void)removeAbsenceAtIndex:(NSUInteger)index;
- (void)resetAllAbsences;

// 通知拒否
- (RefuseInfo*)refuseInfoAtIndex:(NSUInteger)index;
- (void)addRefuseInfo:(RefuseInfo*)info;
- (void)insertRefuseInfo:(RefuseInfo*)info atIndex:(NSUInteger)index;
- (void)setRefuseInfo:(RefuseInfo*)info atIndex:(NSUInteger)index;
- (void)upRefuseInfoAtIndex:(NSUInteger)index;
- (void)downRefuseInfoAtIndex:(NSUInteger)index;
- (void)removeRefuseInfoAtIndex:(NSUInteger)index;
- (BOOL)matchRefuseCondition:(UserInfo*)user;

// 送信ウィンドウ設定
- (BOOL)sendWindowUserListColumnHidden:(NSString*)identifier;
- (void)setSendWindowUserListColumn:(NSString*)identifier hidden:(BOOL)hidden;

@end
