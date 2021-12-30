/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: MessageCenter.h
 *	Module		: メッセージ送受信管理クラス
 *============================================================================*/

#import <Foundation/Foundation.h>

@class RecvMessage;
@class SendMessage;
@class RecvFile;
@class UserInfo;
@class SendAttachment;

/*============================================================================*
 * Notification 通知キー
 *============================================================================*/

// 添付ファイル一覧変更
extern NSString* const kIPMsgAttachmentListChangedNotification;

/*============================================================================*
 * 定数定義
 *============================================================================*/

// ダウンロード結果コード
typedef NS_ENUM(NSInteger, DownloaderResult)
{
	DL_SUCCESS,					// 成功
	DL_STOP,					// 停止（ユーザからの）
	DL_TIMEOUT,					// 通信タイムアウト
	DL_SOCKET_ERROR,			// ソケットエラー
	DL_CONNECT_ERROR,			// 接続エラー
	DL_DISCONNECTED,			// 切断
	DL_COMMUNICATION_ERROR,		// 送受信エラー
	DL_FILE_OPEN_ERROR,			// ファイルオープンエラー
	DL_INVALID_DATA,			// 異常データ受信
	DL_INTERNAL_ERROR,			// 内部エラー
	DL_SIZE_NOT_ENOUGH,			// ファイルサイズ異常
	DL_OTHER_ERROR				// その他エラー（未使用）
};

/*============================================================================*
 * プロトコル定義
 *============================================================================*/

// ダウンロード状況通知デリゲート
@protocol DownloaderDelegate

- (void)downloadWillStart;								// ダウンロード開始
- (void)downloadDidFinished:(DownloaderResult)result;	// ダウンロード終了
- (void)downloadIndexOfTargetChanged;					// 対象添付ファイル変化（ディレクトリ配下は無関係）
- (void)downloadFileChanged;							// ダウンロード対象ファイル変化（ディレクトリ配下ファイルでも通知）
- (void)downloadNumberOfFileChanged;					// ファイル数変化
- (void)downloadNumberOfDirectoryChanged;				// フォルダ数変化
- (void)downloadTotalSizeChanged;						// 全体データサイズ変更（ディレクトリ配下のサイズ加算時）
- (void)downloadDownloadedSizeChanged;					// ダウンロード済みデータサイズ変化（データ受信時）

@end

// ダウンロード情報
@protocol DownloaderContext <NSObject>

@property(readonly)	NSInteger	totalCount;			// 総ダウンロード数
@property(readonly)	NSInteger	downloadedCount;	// ダウンロード済数
@property(readonly)	NSInteger	downloadedFiles;	// ダウンロード済ファイル数
@property(readonly)	NSInteger	downloadedDirs;		// ダウンロード済フォルダ数
@property(readonly)	size_t		totalSize;			// 総ダウンロードサイズ
@property(readonly)	size_t		downloadedSize;		// ダウンロード済サイズ
@property(readonly)	NSString*	currentFileName;	// 現在ダウンロード中ファイル名

@end

/*============================================================================*
 * クラス定義
 *============================================================================*/

// メッセージ管理クラス
@interface MessageCenter : NSObject

// ファクトリ/クラスメソッド
+ (instancetype)sharedCenter;
+ (NSInteger)nextPacketNo;
+ (BOOL)isAttachmentAvailable;

// サーバ起動/停止
- (BOOL)startupServer;
- (BOOL)shutdownServer;


// メッセージ送信（ブロードキャスト）
- (void)broadcastEntry;
- (void)broadcastAbsence;
- (void)broadcastExit;

// メッセージ送信（通常）
- (void)sendMessage:(SendMessage*)msg to:(NSArray<UserInfo*>*)to;
- (void)sendOpenSealMessage:(RecvMessage*)info;
- (void)sendReleaseAttachmentMessage:(RecvMessage*)info;

// 添付ファイル管理
- (NSArray<SendAttachment*>*)sentAttachments;
- (void)removeAttachment:(SendAttachment*)attach;

// 添付ファイルダウンロード
- (id<DownloaderContext>)startDownload:(NSArray<RecvFile*>*)attachments
									of:(NSInteger)packetNo
								  from:(UserInfo*)fromUser
									to:(NSString*)savePath
							  delegate:(id<DownloaderDelegate>)listener;
- (void)stopDownload:(id<DownloaderContext>)downloader;

@end
