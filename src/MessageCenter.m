/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: MessageCenter.m
 *	Module		: メッセージ送受信管理クラス
 *============================================================================*/

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "MessageCenter.h"
#import "AppControl.h"
#import "Config.h"
#import "PortChangeControl.h"
#import "UserManager.h"
#import "UserInfo.h"
#import "RecvMessage.h"
#import "SendMessage.h"
#import "RetryInfo.h"
#import "NoticeControl.h"
#import "RecvAttachment.h"
#import "RecvFile.h"
#import "RecvClipboard.h"
#import "SendAttachment.h"
#import "CryptoCapability.h"
#import "CryptoManager.h"
#import "RSAPublicKey.h"
#import "NSString+IPMessenger.h"
#import "NSData+IPMessenger.h"
#import	"DebugLog.h"

// UNIXソケット関連
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define _MESSAGE_DEBUG  (1)
#define _MESSAGE_TRACE  (0)

/*============================================================================*
 * IPMessengerプロトコル定数定義
 *============================================================================*/

/* This block is quoted from the Windows version created by H.Shirouzu. */
/* { QUOTE START */

/*	@(#)Copyright (C) H.Shirouzu 1996-2017   ipmsg.h	Ver4.50 */

/*  IP Messenger Communication Protocol version 3.0 define  */
/*  macro  */
#define GET_MODE(command)	(command & 0x000000ffUL)
#define GET_OPT(command)	(command & 0xffffff00UL)

/*  header  */
#define IPMSG_VERSION			0x0001
#define IPMSG_NEW_VERSION		0x0003
#define IPMSG_DEFAULT_PORT		0x0979


/*  command  */
#define IPMSG_NOOPERATION		0x00000000UL

#define IPMSG_BR_ENTRY			0x00000001UL
#define IPMSG_BR_EXIT			0x00000002UL
#define IPMSG_ANSENTRY			0x00000003UL
#define IPMSG_BR_ABSENCE		0x00000004UL
#define IPMSG_BR_NOTIFY			IPMSG_BR_ABSENCE

#define IPMSG_BR_ISGETLIST		0x00000010UL
#define IPMSG_OKGETLIST			0x00000011UL
#define IPMSG_GETLIST			0x00000012UL
#define IPMSG_ANSLIST			0x00000013UL
#define IPMSG_ANSLIST_DICT		0x00000014UL
#define IPMSG_BR_ISGETLIST2		0x00000018UL

#define IPMSG_SENDMSG			0x00000020UL
#define IPMSG_RECVMSG			0x00000021UL
#define IPMSG_READMSG			0x00000030UL
#define IPMSG_DELMSG			0x00000031UL
#define IPMSG_ANSREADMSG		0x00000032UL

#define IPMSG_GETINFO			0x00000040UL
#define IPMSG_SENDINFO			0x00000041UL

#define IPMSG_GETABSENCEINFO	0x00000050UL
#define IPMSG_SENDABSENCEINFO	0x00000051UL

#define IPMSG_GETFILEDATA		0x00000060UL
#define IPMSG_RELEASEFILES		0x00000061UL
#define IPMSG_GETDIRFILES		0x00000062UL
#define IPMSG_DIRFILES_AUTH		0x00000063UL
#define IPMSG_DIRFILES_AUTHRET	0x00000064UL

#define IPMSG_GETPUBKEY			0x00000072UL
#define IPMSG_ANSPUBKEY			0x00000073UL

#define IPMSG_AGENT_REQ			0x000000a0UL
#define IPMSG_AGENT_ANSREQ		0x000000a1UL
#define IPMSG_AGENT_PACKET		0x000000a2UL
#define IPMSG_AGENT_PROXYREQ	0x000000a3UL

#define IPMSG_DIR_POLL			0x000000b0UL
#define IPMSG_DIR_POLLAGENT		0x000000b1UL
#define IPMSG_DIR_BROADCAST		0x000000b2UL
#define IPMSG_DIR_ANSBROAD		0x000000b3UL
#define IPMSG_DIR_PACKET		0x000000b4UL
#define IPMSG_DIR_REQUEST		0x000000b5UL
#define IPMSG_DIR_AGENTPACKET	0x000000b6UL
#define IPMSG_DIR_EVBROAD		0x000000b7UL
#define IPMSG_DIR_AGENTREJECT	0x000000b8UL


/*  option for all command  */
#define IPMSG_ABSENCEOPT		0x00000100UL
#define IPMSG_SERVEROPT			0x00000200UL
#define IPMSG_DIALUPOPT			0x00010000UL
#define IPMSG_FILEATTACHOPT		0x00200000UL
#define IPMSG_ENCRYPTOPT		0x00400000UL
#define IPMSG_UTF8OPT			0x00800000UL
#define IPMSG_CAPUTF8OPT		0x01000000UL
#define IPMSG_ENCEXTMSGOPT		0x04000000UL
#define IPMSG_CLIPBOARDOPT		0x08000000UL
#define IPMSG_CAPFILEENC_OBSLT	0x00001000UL
#define IPMSG_CAPFILEENCOPT		0x00040000UL
#define IPMSG_CAPIPDICTOPT		0x02000000UL
#define IPMSG_DIR_MASTER		0x10000000UL
#define IPMSG_FLAG_RESV1		0x20000000UL
#define IPMSG_FLAG_RESV2		0x40000000UL
//#define IPMSG_FLAG_RESV3		0x80000000UL

#define IPMSG_ALLSTAT	(IPMSG_ABSENCEOPT|IPMSG_SERVEROPT|IPMSG_DIALUPOPT|IPMSG_FILEATTACHOPT \
|IPMSG_CLIPBOARDOPT|IPMSG_ENCRYPTOPT|IPMSG_CAPUTF8OPT \
|IPMSG_ENCEXTMSGOPT|IPMSG_CAPFILEENCOPT \
|IPMSG_CAPIPDICTOPT|IPMSG_DIR_MASTER)

#define IPMSG_FULLSTAT	(IPMSG_ALLSTAT & ~(IPMSG_ABSENCEOPT|IPMSG_SERVEROPT|IPMSG_DIALUPOPT))
/*  option for SENDMSG command  */
#define IPMSG_SENDCHECKOPT		0x00000100UL
#define IPMSG_SECRETOPT			0x00000200UL
#define IPMSG_BROADCASTOPT		0x00000400UL
#define IPMSG_MULTICASTOPT		0x00000800UL
#define IPMSG_AUTORETOPT		0x00002000UL
#define IPMSG_RETRYOPT			0x00004000UL
#define IPMSG_PASSWORDOPT		0x00008000UL
#define IPMSG_NOLOGOPT			0x00020000UL
#define IPMSG_NOADDLISTOPT		0x00080000UL
#define IPMSG_READCHECKOPT		0x00100000UL
#define IPMSG_SECRETEXOPT		(IPMSG_READCHECKOPT|IPMSG_SECRETOPT)

/*  option for GETDIRFILES/GETFILEDATA command  */
#define IPMSG_ENCFILE_OBSLT		0x00000400UL
#define IPMSG_ENCFILEOPT		0x00000800UL

/*  obsolete option for send command  */
#define IPMSG_NEWMULTI_OBSLT	0x00040000UL

/* encryption/capability flags for encrypt command */
#define IPMSG_RSA_1024			0x00000002UL
#define IPMSG_RSA_2048			0x00000004UL
#define IPMSG_RSA_4096			0x00000008UL
#define IPMSG_BLOWFISH_128		0x00020000UL
#define IPMSG_AES_256			0x00100000UL
#define IPMSG_COMMON_KEYS		(IPMSG_BLOWFISH_128|IPMSG_AES_256)
#define IPMSG_PACKETNO_IV		0x00800000UL
#define IPMSG_IPDICT_CTR		0x00400000UL
#define IPMSG_ENCODE_BASE64		0x01000000UL
#define IPMSG_NOENC_FILEBODY	0x04000000UL	// noencode for file-body
#define IPMSG_SIGN_SHA1			0x20000000UL
#define IPMSG_SIGN_SHA256		0x40000000UL

/* compatibilty for Win beta version */
#define IPMSG_RSA_512OBSOLETE	0x00000001UL
#define IPMSG_RC2_40OLD			0x00000010UL	// for beta1-4 only
#define IPMSG_RC2_128OLD		0x00000040UL	// for beta1-4 only
#define IPMSG_BLOWFISH_128OLD	0x00000400UL	// for beta1-4 only
#define IPMSG_RC2_40OBSOLETE	0x00001000UL
#define IPMSG_RC2_128OBSOLETE	0x00004000UL
#define IPMSG_RC2_256OBSOLETE	0x00008000UL
#define IPMSG_BLOWFISH_256OBSOL	0x00040000UL
#define IPMSG_AES_128OBSOLETE	0x00080000UL
#define IPMSG_SIGN_MD5OBSOLETE	0x10000000UL
#define IPMSG_UNAMEEXTOPT_OBSLT	0x02000000UL

/* file types for fileattach command */
#define IPMSG_FILE_REGULAR		0x00000001UL
#define IPMSG_FILE_DIR			0x00000002UL
#define IPMSG_FILE_RETPARENT	0x00000003UL	// return parent directory
#define IPMSG_FILE_SYMLINK		0x00000004UL
#define IPMSG_FILE_CDEV			0x00000005UL	// for UNIX
#define IPMSG_FILE_BDEV			0x00000006UL	// for UNIX
#define IPMSG_FILE_FIFO			0x00000007UL	// for UNIX
#define IPMSG_FILE_RESFORK		0x00000010UL	// for Mac
#define IPMSG_FILE_CLIPBOARD	0x00000020UL	// for Windows Clipboard

/* file attribute options for fileattach command */
#define IPMSG_FILE_RONLYOPT		0x00000100UL
#define IPMSG_FILE_HIDDENOPT	0x00001000UL
#define IPMSG_FILE_EXHIDDENOPT	0x00002000UL	// for MacOS X
#define IPMSG_FILE_ARCHIVEOPT	0x00004000UL
#define IPMSG_FILE_SYSTEMOPT	0x00008000UL

/* extend attribute types for fileattach command */
#define IPMSG_FILE_UID			0x00000001UL
#define IPMSG_FILE_USERNAME		0x00000002UL	// uid by string
#define IPMSG_FILE_GID			0x00000003UL
#define IPMSG_FILE_GROUPNAME	0x00000004UL	// gid by string
#define IPMSG_FILE_CLIPBOARDPOS	0x00000008UL	//
#define IPMSG_FILE_PERM			0x00000010UL	// for UNIX
#define IPMSG_FILE_MAJORNO		0x00000011UL	// for UNIX devfile
#define IPMSG_FILE_MINORNO		0x00000012UL	// for UNIX devfile
#define IPMSG_FILE_CTIME		0x00000013UL	// for UNIX
#define IPMSG_FILE_MTIME		0x00000014UL
#define IPMSG_FILE_ATIME		0x00000015UL
#define IPMSG_FILE_CREATETIME	0x00000016UL
#define IPMSG_FILE_CREATOR		0x00000020UL	// for Mac
#define IPMSG_FILE_FILETYPE		0x00000021UL	// for Mac
#define IPMSG_FILE_FINDERINFO	0x00000022UL	// for Mac
#define IPMSG_FILE_ACL			0x00000030UL
#define IPMSG_FILE_ALIASFNAME	0x00000040UL	// alias fname

#define FILELIST_SEPARATOR		'\a'
#define HOSTLIST_SEPARATOR		'\a'
#define HOSTLIST_SEPARATORS		"\a"
#define HOSTLIST_NEW_SEPARATOR	'\f'
#define HOSTLIST_DUMMY			"\b"

#define IPMSG_DEFAULT_MULTICAST_ADDR6	"ff15::979"
#define LINK_MULTICAST_ADDR6			"ff02::1"
#define IPMSG_LIMITED_BROADCAST			"255.255.255.255"

//#define IPMSG_MULTICAST_ADDR4	"224.9.7.9"

#ifdef _WIN64
#define IPMSG_VER_WIN_TYPE		IPMSG_VER_WIN64_TYPE
#else
#define IPMSG_VER_WIN_TYPE		IPMSG_VER_WIN32_TYPE
#endif

#define IPMSG_VER_WIN32_TYPE	0x00010001
#define IPMSG_VER_WIN64_TYPE	0x00010002
#define IPMSG_VER_MAC_TYPE		0x00020000
#define IPMSG_VER_IOS_TYPE		0x00030000
#define IPMSG_VER_ANDROID_TYPE	0x00040000

/* New Protocol Key */
#define IPMSG_VER_KEY		"VER"
#define IPMSG_PKTNO_KEY		"PKT"
#define IPMSG_DATE_KEY		"DATE"
#define IPMSG_UID_KEY		"UID"
#define IPMSG_HOST_KEY		"HID"
#define IPMSG_NICK_KEY		"NCK"
#define IPMSG_NICKORG_KEY	"NCKO"
#define IPMSG_GROUP_KEY		"GRP"
#define IPMSG_STAT_KEY		"STAT"
#define IPMSG_EXSTAT_KEY	"EXST"
#define IPMSG_CMD_KEY		"CMD"
#define IPMSG_FLAGS_KEY		"FLG"
#define IPMSG_CLIVER_KEY	"CVER"
#define IPMSG_BODY_KEY		"BODY"
#define IPMSG_REPLYPKT_KEY	"RPN"
#define IPMSG_TOLIST_KEY	"TLST"
#define IPMSG_FROM_KEY		"FROM"
#define IPMSG_HOSTLIST_KEY	"HLST"
#define IPMSG_IPADDR_KEY	"IPAD"
#define IPMSG_PORT_KEY		"PORT"
#define IPMSG_POLL_KEY		"POLL"
#define IPMSG_MASTER_KEY	"MST"
#define IPMSG_ENCFLAG_KEY	"EF"
#define IPMSG_ENCIV_KEY		"EI"
#define IPMSG_ENCKEY_KEY	"EK"
#define IPMSG_ENCBODY_KEY	"EB"
#define IPMSG_PUB_E_KEY		"PUBE"
#define IPMSG_PUB_N_KEY		"PUBN"
#define IPMSG_ENCCAPA_KEY	"EC"
#define IPMSG_SIGN_KEY		"SIGN"

#define IPMSG_FILE_KEY		"FILE"
#define IPMSG_FID_KEY		"FI"
#define IPMSG_FNAME_KEY		"FN"
#define IPMSG_FSIZE_KEY		"FS"
#define IPMSG_MTIME_KEY		"MT"
#define IPMSG_FATTR_KEY		"FA"
#define IPMSG_CLIPPOS_KEY	"CP"

#define IPMSG_START_KEY		"START"
#define IPMSG_TOTAL_KEY		"TOTAL"
#define IPMSG_NUM_KEY		"NUM"
#define IPMSG_DIRBROAD_KEY	"DRB"
#define IPMSG_TARGADDR_KEY	"TADR"	// 192.168.0.1
#define IPMSG_NADDR_KEY		"NADR"	// 192.168.0.1/24
#define IPMSG_NADDRS_KEY	"NADRS"
#define IPMSG_ADDR_KEY		"ADR"
#define IPMSG_MASK_KEY		"MASK"
#define IPMSG_WRAPPED_KEY	"WAPD"
#define IPMSG_UPTIME_KEY	"UPT"
#define IPMSG_AGENTSEC_KEY	"AGS"
#define IPMSG_ACTIVE_KEY	"ACT"
#define IPMSG_SVRADDR_KEY	"SVADR"
#define IPMSG_AGENT_KEY		"AGNT"
#define IPMSG_DIRECT_KEY	"DRCT"

#define IPMSG_ABSTITLE_KEY	"ABST"
#define IPMSG_ABSMODE_KEY	"ABSMD"
#define IPMSG_FILELIST_KEY	"FLS"
#define IPMSG_ERRINFO_KEY	"EINF"


/*  end of IP Messenger Communication Protocol version 3.0 define  */

/* QUOTE END } */

/*============================================================================*
 * Notification 通知キー
 *============================================================================*/

// 添付ファイル一覧変更
NSString* const kIPMsgAttachmentListChangedNotification = @"IPMsgAttachmentListChanged";

/*============================================================================*
 * 定数定義
 *============================================================================*/

static const NSTimeInterval RETRY_INTERVAL	= 2.0;
static const NSInteger		RETRY_MAX		= 3;
static const NSTimeInterval _ATTACH_TIMEOUT = (24 * 60 * 60);
static const NSInteger		_ANY_PACKET_NO	= NSNotFound;
static const NSInteger		_ANY_FILE_ID	= NSNotFound;

#define MESSAGE_SEPARATOR	":"
#define MAX_UDPBUF			32768

/*============================================================================*
 * 内部クラス
 *============================================================================*/

@interface AttachDLContextImpl : NSObject <DownloaderContext>

@property(retain)	NSArray<RecvAttachment*>*	attachments;
@property(assign)	NSInteger					packetNo;
@property(retain)	UserInfo*					fromUser;
@property(copy)		NSString*					savePath;
@property(weak)		id<DownloaderDelegate>		delegate;
@property(assign)	int							tcpSocket;
@property(assign)	BOOL						stop;

@end

@interface AttachDLContextImpl()

@property(assign)	NSInteger	totalCount;
@property(assign)	NSInteger	downloadedCount;
@property(assign)	NSInteger	downloadedFiles;
@property(assign)	NSInteger	downloadedDirs;
@property(assign)	size_t		totalSize;
@property(assign)	size_t		downloadedSize;
@property(copy)		NSString*	currentFileName;

@end

@implementation AttachDLContextImpl

- (void)dealloc
{
	[_attachments release];
	[_fromUser release];
	[_savePath release];
	if (_tcpSocket != -1) {
		close(_tcpSocket);
	}
	[super dealloc];
}

@end

/*============================================================================*
 * プライベートメソッド
 *============================================================================*/

typedef NSDictionary<NSFileAttributeKey, id>		_FileAttrDic;
typedef NSMutableDictionary<NSString*,RetryInfo*>	_SendList;
typedef NSMutableArray<SendAttachment*>				_AttachList;

@interface MessageCenter()

// 共通
@property(assign)	UInt16			portNo;				// ポート番号

// メッセージ送受信関連
@property(assign)	int				udpSocket;			// UDPソケットディスクリプタ
@property(retain)	NSLock*			udpServerLock;		// UDPサーバ待ち合わせ用ロック
@property(assign)	BOOL			udpServerStop;		// UDPサーバ停止フラグ
@property(retain)	_SendList*		sendList;			// 応答待ちメッセージ一覧（再送用）

// 添付ファイル送受信関連
@property(retain)	_AttachList*	attachList;			// 送信添付ファイル一覧
@property			int				tcpSocket;			// TCPソケットディスクリプタ
@property(retain)	NSLock*			tcpServerLock;		// サーバスレッド終了同期用ロック
@property			BOOL			tcpServerStop;		// 終了フラグ

// その他
@property(copy)		NSString*		selfLogOnName;		// 自分のログオン名
@property(assign)	UInt32			selfSpec;			// 自分の対応機能
@property(copy)		NSString*		selfVersion;		// 自分のバージョン情報

// 送信添付ファイル情報追加/削除
- (void)addAttachment:(SendAttachment*)attach;

// 添付ファイル送信ユーザ削除
- (void)removeAttachmentUser:(UserInfo*)user packetNo:(NSInteger)pNo fileID:(NSInteger)fid;

// その他
- (void)fireAttachListChangeNotice;

@end

/*============================================================================*
 * ローカルデバッグマクロ
 *============================================================================*/

#if defined(IPMSG_DEBUG) && _MESSAGE_DEBUG
#ifndef IPMSG_LOG_DBG_ENABLED
#error _MSG_DBG is ON but DBG Level Log not enabled
#endif
#define _MSG_DBG(...)		DBG(__VA_ARGS__)
#else
#define _MSG_DBG(...)
#endif

#if defined(IPMSG_DEBUG) && _MESSAGE_TRACE
#ifndef IPMSG_LOG_TRC_ENABLED
#error _MSG_TRC is ON but TRC Level Log not enabled
#endif
#define _MSG_TRC(...)		TRC(__VA_ARGS__)
#else
#define _MSG_TRC(...)
#endif

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation MessageCenter

/*----------------------------------------------------------------------------*/
 #pragma mark - クラスメソッド
/*----------------------------------------------------------------------------*/

// 共有インスタンスを返す
+ (instancetype)sharedCenter
{
	static MessageCenter*	sharedCenter = nil;
	static dispatch_once_t	once;
	dispatch_once(&once, ^{
		sharedCenter = [[MessageCenter alloc] init];
	});
	return sharedCenter;
}

// 次のパケット番号を返す
+ (NSInteger)nextPacketNo
{
	static NSInteger packetNo = 0;
	@synchronized (MessageCenter.sharedCenter) {
		NSInteger now = (UInt32)[[NSDate date] timeIntervalSinceReferenceDate];
		if (now > packetNo) {
			packetNo = now;
		}
		return packetNo++;
	}
}

// 有効チェック
+ (BOOL)isAttachmentAvailable
{
	MessageCenter* mc = MessageCenter.sharedCenter;
	if ([mc.tcpServerLock tryLock]) {
		// ロックが取れたということはサーバがいない
		[mc.tcpServerLock unlock];
		return NO;
	} else {
		// ロックが取れなければサーバがいる
		return YES;
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - 初期化／解放
/*----------------------------------------------------------------------------*/

// 初期化
- (instancetype)init
{
	self = [super init];
	if (self) {
		// バージョン情報
		NSBundle* mb		= NSBundle.mainBundle;
		NSString* ver1		= [mb objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		NSString* ver2		= [mb objectForInfoDictionaryKey:@"CFBundleVersion"];
		NSString* verStr	= [NSString stringWithFormat:@"%@(%@)", ver1, ver2];

		_udpSocket		= -1;
		_udpServerLock	= [[NSLock alloc] init];
		_udpServerStop	= FALSE;
		_sendList		= [[_SendList alloc] init];
		_tcpSocket		= -1;
		_tcpServerLock	= [[NSLock alloc] init];
		_tcpServerStop	= FALSE;
		_attachList		= [[_AttachList alloc] init];
		_selfLogOnName	= [NSUserName() copy];
		_selfSpec		= IPMSG_CAPUTF8OPT;
		_selfVersion	= [[NSString alloc] initWithFormat:NSLocalizedString(@"Version.Msg.string", nil), verStr];
	}

	return self;
}

// 解放
-(void)dealloc
{
	if (_tcpSocket != -1) {
		close(_tcpSocket);
	}

	if (_udpSocket != -1) {
		close(_udpSocket);
	}

	[_udpServerLock release];
	[_tcpServerLock release];
	[_attachList release];
	[_sendList release];
	[_selfLogOnName release];
	[_selfVersion release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*/
#pragma mark - サーバ処理
/*----------------------------------------------------------------------------*/

// サーバ起動
- (BOOL)startupServer
{
	// ポート番号
	self.portNo = Config.sharedConfig.portNo;
	if (self.portNo <= 0) {
		self.portNo = IPMSG_DEFAULT_PORT;
	}

	// 暗号化
	if (![CryptoManager.sharedManager startup]) {
		ERR(@"Startup:CryptManager startup error");
		//TODO:エラーダイアログ表示してアプリ終了？
	} else {
		DBG(@"Startup:CryptMangaer startup finished.");
		CryptoManager* cm = CryptoManager.sharedManager;
		if (cm.selfCapability.supportEncryption) {
			self.selfSpec |= IPMSG_ENCRYPTOPT;
			if (cm.selfCapability.supportFingerPrint) {
				// 公開鍵指紋設定
				NSData* fingerPrint = [cm publicKeyFingerPrintForRSA2048Modulus:cm.publicKey2048.modulus];
				self.selfLogOnName = [NSString stringWithFormat:@"%@-<%@>", NSUserName(), fingerPrint.hexEncodedString];
			}
			self.selfSpec |= IPMSG_ENCEXTMSGOPT;
		}
	}

	// メッセージ受信サーバ
	if ([self.udpServerLock tryLock]) {
		[self.udpServerLock unlock];

		// ソケットオープン
		if (self.udpSocket != -1) {
			close(self.udpSocket);
		}
		if ((self.udpSocket = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
			ERR(@"Startup:Message:UDP socket create error(errno=%d)", errno);
			// Dockアイコンバウンド
			[NSApp requestUserAttention:NSCriticalRequest];
			// エラーダイアログ表示
			NSAlert* alert = [[[NSAlert alloc] init] autorelease];
			alert.alertStyle = NSAlertStyleCritical;
			alert.messageText = NSLocalizedString(@"Err.UDPSocketOpen.title", nil);
			alert.informativeText = NSLocalizedString(@"Err.UDPSocketOpen.msg", nil);
			[alert runModal];
			// プログラム終了
			[NSApp terminate:self];
			return NO;
		}
		DBG(@"Startup:Message:UDP socket create OK.(%d)", self.udpSocket);

		// ソケットバインドアドレスの用意
		struct sockaddr_in	addr;
		memset(&addr, 0, sizeof(addr));
		addr.sin_family			= AF_INET;
		addr.sin_addr.s_addr	= htonl(INADDR_ANY);
		addr.sin_port			= htons(self.portNo);

		// ソケットバインド
		while (bind(_udpSocket, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
			ERR(@"Startup:Message:bind error(errno=%d)", errno);
			// Dockアイコンバウンド
			[NSApp requestUserAttention:NSCriticalRequest];
			// エラーダイアログ表示
			NSAlert* alert = [[[NSAlert alloc] init] autorelease];
			alert.alertStyle = NSAlertStyleCritical;
			alert.messageText = NSLocalizedString(@"Err.UDPSocketBind.title", nil);
			alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Err.UDPSocketBind.msg", nil), self.portNo];
			[alert addButtonWithTitle:NSLocalizedString(@"Err.UDPSocketBind.ok", nil)];
			[alert addButtonWithTitle:NSLocalizedString(@"Err.UDPSocketBind.alt", nil)];
			NSModalResponse ret = [alert runModal];
			if (ret == NSAlertFirstButtonReturn) {
				// プログラム終了
				[NSApp terminate:self];
				return NO;
			}
			[[[PortChangeControl alloc] init] autorelease];
			self.portNo	= Config.sharedConfig.portNo;
			addr.sin_port = htons(self.portNo);
		}
		DBG(@"Startup:Message:UDP socket bind OK.(ANY:%d)", self.portNo);

		// ブロードキャスト許可設定
		int sockopt = 1;
		setsockopt(_udpSocket, SOL_SOCKET, SO_BROADCAST, &sockopt, sizeof(sockopt));
		// バッファサイズ設定
		sockopt = MAX_UDPBUF;
		setsockopt(_udpSocket, SOL_SOCKET, SO_SNDBUF, &sockopt, sizeof(sockopt));
		setsockopt(_udpSocket, SOL_SOCKET, SO_RCVBUF, &sockopt, sizeof(sockopt));

		// 受信スレッド起動
		DBG(@"Startup:Message:invoke ServerThread");
		[self performSelectorInBackground:@selector(udpServerThread:) withObject:nil];
	} else {
		WRN(@"Startup:Message:ServerThread already working.");
	}

	// 添付ファイルサーバ
	if ([self.tcpServerLock tryLock]) {
		[self.tcpServerLock unlock];

		// ソケットオープン
		if (self.tcpSocket != -1) {
			close(self.tcpSocket);
		}
		if ((self.tcpSocket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
			ERR(@"Startup:Attachment:TCP socket create error(errno=%d)", errno);
			// Dockアイコンバウンド
			[NSApp requestUserAttention:NSCriticalRequest];
			// エラーダイアログ表示
			NSAlert* alert = [[[NSAlert alloc] init] autorelease];
			alert.alertStyle = NSAlertStyleCritical;
			alert.messageText = NSLocalizedString(@"Err.TCPSocketOpen.title", nil);
			alert.informativeText = NSLocalizedString(@"Err.TCPSocketOpen.msg", nil);
			[alert runModal];
			return NO;
		}
		DBG(@"Startup:Attachment:TCP socket create OK.(%d)", self.tcpSocket);

		// ソケットバインドアドレスの用意
		struct sockaddr_in	addr;
		memset(&addr, 0, sizeof(addr));
		addr.sin_family			= AF_INET;
		addr.sin_addr.s_addr	= htonl(INADDR_ANY);
		addr.sin_port			= htons(self.portNo);

		// ソケットバインド
		if (bind(self.tcpSocket, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
			ERR(@"Startup:Attachment:bind error(errno=%d)", errno);
			// Dockアイコンバウンド
			[NSApp requestUserAttention:NSCriticalRequest];
			// エラーダイアログ表示
			NSAlert* alert = [[[NSAlert alloc] init] autorelease];
			alert.alertStyle = NSAlertStyleCritical;
			alert.messageText = NSLocalizedString(@"Err.TCPSocketBind.title", nil);
			alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Err.TCPSocketBind.msg", nil), self.portNo];
			[alert runModal];
			return NO;
		}
		DBG(@"Startup:Attachment:TCP socket bind OK.(ANY:%d)", self.portNo);

		// REUSE ADDR
		int sockopt = 1;
		setsockopt(self.tcpSocket, SOL_SOCKET, SO_REUSEADDR, &sockopt, sizeof(sockopt));

		// サーバ初期化
		if (listen(self.tcpSocket, 5) != 0) {
			ERR(@"Startup:Attachment:TCP socket listen error(errno=%d)", errno);
			// Dockアイコンバウンド
			[NSApp requestUserAttention:NSCriticalRequest];
			// エラーダイアログ表示
			NSAlert* alert = [[[NSAlert alloc] init] autorelease];
			alert.alertStyle = NSAlertStyleCritical;
			alert.messageText = NSLocalizedString(@"Err.TCPSocketListen.title", nil);
			alert.informativeText = NSLocalizedString(@"Err.TCPSocketListen.msg", nil);
			[alert runModal];
			return NO;
		}
		DBG(@"Startup:Attachment:TCP socket listen OK.");

		// 添付要求受信スレッド
		DBG(@"Startup:Attachment:invoke ServerThread");
		[self performSelectorInBackground:@selector(tcpServerThread:) withObject:nil];

		self.selfSpec |= IPMSG_FILEATTACHOPT;
		self.selfSpec |= IPMSG_CLIPBOARDOPT;
	} else {
		WRN(@"Startup:Attachment:ServerThread already working.");
	}

	return YES;
}

// サーバ停止
- (BOOL)shutdownServer
{
	// 添付ファイルサーバ
	if ([self.tcpServerLock tryLock]) {
		DBG(@"Shutdown:Attachment:Server not exist");
	} else {
		// ロックが取れなければ起動中なので止める
		DBG(@"Shutdown:Attachment:Server stopping...");
		self.tcpServerStop = YES;
		[self.tcpServerLock lock];	// ロックがとれるのはサーバスレッドが終了した時
		DBG(@"Shutdown:Attachment:Server stopped.");
	}
	[self.tcpServerLock unlock];
	if (self.tcpSocket != -1) {
		close(self.tcpSocket);
		self.tcpSocket = -1;
	}

	// メッセージ受信サーバ
	if ([self.udpServerLock tryLock]) {
		DBG(@"Shutdown:Messages:Server not exist");
	} else {
		DBG(@"Shutdown:Message:Server stopping...");
		self.udpServerStop = YES;
		[self.udpServerLock lock];	// ロックがとれるのはサーバスレッドが終了した時
		DBG(@"Shutdown:Message:Server stopped.");
	}
	[self.udpServerLock unlock];
	if (self.udpSocket != -1) {
		close(self.udpSocket);
		self.udpSocket = -1;
	}

	return YES;
}

// メッセージ受信スレッド
- (void)udpServerThread:(id)arg
{
	@autoreleasepool {
		if ([self.udpServerLock tryLock]) {
			DBG(@"Server:MessageRecvThread:start.");
			fd_set				fdSet;
			struct timeval		tv;
			char				buff[MAX_UDPBUF];	// 受信バッファ
			struct sockaddr_in	fromAddr;
			socklen_t			fromAddrLen = sizeof(fromAddr);

			while (!self.udpServerStop) {
				FD_ZERO(&fdSet);
				FD_SET(self.udpSocket, &fdSet);
				tv.tv_sec	= 1;
				tv.tv_usec	= 0;
				int ret = select(self.udpSocket + 1, &fdSet, NULL, NULL, &tv);
				if (ret < 0) {
					ERR(@"Server:MessageRecvThread:select error(%d)", ret);
					continue;
				}
				if (ret == 0) {
					// タイムアウト
					continue;
				}
				// 受信
				ssize_t len = recvfrom(self.udpSocket, buff, MAX_UDPBUF, 0, (struct sockaddr*)&fromAddr, &fromAddrLen);
				if (len == -1) {
					ERR(@"Server:MessageRecvThread:recvfrom error(sock=%d,errno=%d)", self.udpSocket, errno);
					continue;
				}
				// メッセージ処理
				@try {
					[self processReceiveMessageBuffer:buff length:len from:fromAddr];
				} @catch (NSException* exception) {
					ERR(@"Server:MessageRecvThread:%@", exception);
				}
			}
			DBG(@"Server:MessageRecvThread:end.");
			[self.udpServerLock unlock];
		} else {
			ERR(@"Server:MessageRecvThread:already working");
		}
	}
}

// 添付ファイル要求受付スレッド
- (void)tcpServerThread:(id)obj
{
	@autoreleasepool {
		if ([self.tcpServerLock tryLock]) {
			DBG(@"Server:AttachmentServerThread:start.");
			while (!self.tcpServerStop) {
				fd_set fdSet;
				FD_ZERO(&fdSet);
				FD_SET(self.tcpSocket, &fdSet);
				struct timeval tv;
				tv.tv_sec	= 1;
				tv.tv_usec	= 0;
				int ret = select(self.tcpSocket + 1, &fdSet, NULL, NULL, &tv);
				if (ret < 0) {
					ERR(@"Server:AttachmentServerThread:select error(%d)", ret);
					break;
				}
				if (ret == 0) {
					// タイムアウト
					continue;
				}
				if (FD_ISSET(self.tcpSocket, &fdSet)) {
					struct sockaddr_in	clientAddr;
					socklen_t			len = sizeof(clientAddr);
					int newSock = accept(self.tcpSocket, (struct sockaddr*)&clientAddr, &len);
					if (newSock < 0) {
						ERR(@"Server:AttachmentServerThread:accept error(%d)", newSock);
						break;
					} else {
						DBG(@"Server:AttachmentServerThread:FileRequest recv(sock=%d,address=%s)", newSock, inet_ntoa(clientAddr.sin_addr));
						NSArray<NSNumber*>* param = @[@(newSock), @(ntohl(clientAddr.sin_addr.s_addr))];
						[self performSelectorInBackground:@selector(tcpConnectionThread:) withObject:param];
					}
				}
			}
			DBG(@"Server:AttachmentServerThread:end.");
			[self.tcpServerLock unlock];
		} else {
			ERR(@"Server:AttachmentServerThread:already working");
		}
	}
}

// 添付ファイル送信スレッド
- (void)tcpConnectionThread:(NSArray<NSNumber*>*)param
{
	@autoreleasepool {
		int		sock	= param[0].intValue;			// 送信ソケットディスクリプタ
		UInt32	ipAddr	= param[1].unsignedIntValue;	// 相手IPアドレス
		UInt16	ipPort	= self.portNo;					// TCPポート番号

		// パラメタチェック
		if (sock < 0) {
			ERR(@"no socket(%d)", sock);
			return;
		}
		DBG(@"Server:AttachmentConnectionThread:start(sock=%d).", sock);

		struct sockaddr_in	addr;
		addr.sin_addr.s_addr	= htonl(ipAddr);
		addr.sin_port			= htons(ipPort);

		char		buf[256];			// リクエスト読み込みバッファ
		NSInteger	waitTime = 0;		// タイムアウト管理
		for (waitTime = 0; waitTime < 30; waitTime++) {
			// リクエスト受信待ち
			fd_set fdSet;
			FD_ZERO(&fdSet);
			FD_SET(sock, &fdSet);
			struct timeval tv;
			tv.tv_sec	= 1;
			tv.tv_usec	= 0;
			memset(buf, 0, sizeof(buf));
			int ret = select(sock + 1, &fdSet, NULL, NULL, &tv);
			if (ret < 0) {
				ERR(@"Server:AttachmentConnectionThread:select error(%d)", ret);
				break;
			}
			if (ret == 0) {
				continue;
			}
			if (FD_ISSET(sock, &fdSet)) {
				// リクエスト読み込み
				ssize_t len = recv(sock, buf, sizeof(buf) - 1, 0);
				if (len < 0) {
					ERR(@"Server:AttachmentConnectionThread:recvError(%ld)", len);
					break;
				}
				// ファイル送信処理
				@try {
					[self processAttachmentRequestBuffer:buf
												  length:len
													from:addr
												  socket:sock];
				} @catch (NSException* exception) {
					ERR(@"Server:AttachmentConnectionThread:%@", exception);
				}
				break;
			}
		}
		if (waitTime >= 30) {
			ERR(@"Server:AttachmentConnectionThread:recv TimeOut.");
		}

		close(sock);
		DBG(@"Server:AttachmentConnectionThread:finish.(sock=%d)", sock);
	}
}


/*----------------------------------------------------------------------------*/
#pragma mark - メッセージ送信（ブロードキャスト）
/*----------------------------------------------------------------------------*/

// ブロードキャスト送信処理
- (void)sendBroadcast:(UInt32)cmd data:(NSData*)data
{
	// ブロードキャスト（ローカル）アドレスへ送信
	struct sockaddr_in	bcast;
	memset(&bcast, 0, sizeof(bcast));
	bcast.sin_family		= AF_INET;
	bcast.sin_port			= htons(self.portNo);
	bcast.sin_addr.s_addr	= htonl(INADDR_BROADCAST);
	[self sendTo:&bcast packetNo:-1 command:cmd data:data];

	// 個別ブロードキャストへ送信
	Config* cfg = Config.sharedConfig;
	for (NSString* address in cfg.broadcastAddresses) {
		bcast.sin_addr.s_addr = inet_addr(address.UTF8String);
		if (bcast.sin_addr.s_addr != INADDR_NONE) {
			[self sendTo:&bcast packetNo:-1 command:cmd data:data];
		}
	}
	for (UserInfo* user in UserManager.sharedManager.users) {
		if (user.dialupConnect) {
			bcast.sin_addr.s_addr = user.address.sin_addr.s_addr;
			[self sendTo:&bcast packetNo:-1 command:cmd data:data];
		}
	}
}

// BR_ENTRYのブロードキャスト
- (void)broadcastEntry
{
	[self sendBroadcast:IPMSG_NOOPERATION data:nil];
	[self sendBroadcast:IPMSG_BR_ENTRY|self.selfSpec
				   data:[self makeEntryMessageData]];
	DBG(@"broadcast entry");
}

// BR_ABSENCEのブロードキャスト
- (void)broadcastAbsence
{
	[self sendBroadcast:IPMSG_BR_ABSENCE|self.selfSpec
				   data:[self makeEntryMessageData]];
	DBG(@"broadcast absence");
}

// BR_EXITをブロードキャスト
- (void)broadcastExit
{
	[self sendBroadcast:IPMSG_BR_EXIT|self.selfSpec
				   data:[self makeEntryMessageData]];
	DBG(@"broadcast exit");
}

/*----------------------------------------------------------------------------*/
#pragma mark - メッセージ送信（通常）
/*----------------------------------------------------------------------------*/

// 通常メッセージの送信
- (void)sendMessage:(SendMessage*)msg to:(NSArray<UserInfo*>*)toUsers
{
	// コマンドの決定
	UInt32 command = IPMSG_SENDMSG | IPMSG_SENDCHECKOPT;
	if (toUsers.count > 1) {
		command |= IPMSG_MULTICASTOPT;
	}
	if (msg.sealed) {
		command |= IPMSG_SECRETOPT;
		if (msg.locked) {
			command |= IPMSG_PASSWORDOPT;
		}
	}

	// 添付ファイルメッセージ編集
	NSString* option = nil;
	if (msg.attachments.count > 0) {
		NSFileManager*		fm		= NSFileManager.defaultManager;
		NSInteger			count	= 0;
		NSMutableString*	buffer	= [NSMutableString string];
		for (SendAttachment* attach in msg.attachments) {
			if (![fm fileExistsAtPath:attach.path]) {
				ERR(@"AttachFile not exist(Packet:%ld,Path=%@)", msg.packetNo, attach.path);
				continue;
			}
			_FileAttrDic* attrs = [fm attributesOfItemAtPath:attach.path error:nil];
			NSDate* mtime = attrs[NSFileModificationDate];
			unsigned fileAttr = [self makeFileAttributeForPath:attach.path attrs:attrs];
			[buffer appendFormat:@"%ld:%@:%zX:%X:%X:",
								count,
								attach.name,
								[self fileSizeForAttrs:attrs],
								(unsigned)mtime.timeIntervalSince1970,
								fileAttr];
			NSString* ext = [self makeFileExtendAttributeForAttrs:attrs];
			if (ext.length > 0) {
				[buffer appendString:ext];
				[buffer appendString:@":"];
			}
			[buffer appendString:@"\a"];
			TRC(@"Attachment(%@)", buffer);
			attach.packetNo	= msg.packetNo;
			attach.fileID	= count;
			// 破棄タイマの設定
			__weak typeof(self)		weakSelf	= self;
			__weak SendAttachment*	weakAttach	= attach;
			attach.trashTimer = [NSTimer scheduledTimerWithTimeInterval:_ATTACH_TIMEOUT
																  repeats:NO
																	block:^(NSTimer* _Nonnull timer) {
				DBG(@"Attachment Timeout(PacketNo=%ld,FileID=%ld,%.1fs passed.) -> Remove",
													weakAttach.packetNo, weakAttach.fileID, _ATTACH_TIMEOUT);
				@synchronized(weakSelf.attachList) {
					// 添付ファイル削除
					DBG(@"AttachFile remove(PacketNo=%ld,FileID=%ld)", weakAttach.packetNo, weakAttach.fileID);
					[weakSelf.attachList removeObject:weakAttach];
				}
				[weakSelf fireAttachListChangeNotice];
			}];
			[self addAttachment:attach];
			count++;
		}
		if (buffer.length > 0) {
			option	= buffer;
			command |= IPMSG_FILEATTACHOPT;
		}
	}

	// 各ユーザに送信
	for (UserInfo* user in toUsers) {
		NSInteger	pNo 			= -1;
		BOOL		supportsAttach	= (command & IPMSG_FILEATTACHOPT) && (user.supportsAttachment);
		// 送信
		if (user.supportsEncrypt && !user.publicKey) {
			// 暗号化対応で公開鍵を未受信なのでまずは鍵要求
			_MSG_DBG(@"Send GETPUBKEY to %@(no key)", user);
			[self sendGetPubKeyTo:user];
			// リトライ待ちのタイムアウトまでに鍵を受信してメッセージ送信する目論見
			pNo = msg.packetNo;
		} else {
			// 暗号化非対応または鍵受信済みなので送信
			pNo = [self sendTo:user
					  packetNo:msg.packetNo
					   command:command
					   message:msg.message
						option:supportsAttach ? option : nil];
		}
		if (pNo >= 0) {
			if (supportsAttach) {
				// 添付付きで送った場合には送り先に追加
				@synchronized (self.attachList) {
					for (SendAttachment* attach in self.attachList) {
						if (attach.packetNo == pNo) {
							[attach addUser:user];
						}
					}
				}
				[self fireAttachListChangeNotice];
			}
			// 応答待ちメッセージ一覧に追加
			RetryInfo* retry = [RetryInfo infoWithPacketNo:pNo
												   command:command
														to:user
												   message:msg.message
													option:option];
			self.sendList[retry.identifyKey] = retry;
			// リトライタイマ発行
			[NSTimer scheduledTimerWithTimeInterval:RETRY_INTERVAL
											 target:self
										   selector:@selector(retryMessage:)
										   userInfo:retry.identifyKey
											repeats:YES];
		}
	}
}

// 応答タイムアウト時処理
- (void)retryMessage:(NSTimer*)timer
{
	NSString*	retryKey	= timer.userInfo;
	RetryInfo*	retryInfo	= self.sendList[retryKey];
	if (retryInfo) {
		if (retryInfo.retryCount >= RETRY_MAX) {
			// いったんタイマ解除
			[timer invalidate];
			// 再送確認
			NSAlert* alert = [[[NSAlert alloc] init] autorelease];
			alert.alertStyle		= NSAlertStyleCritical;
			alert.messageText		= NSLocalizedString(@"Send.Retry.Title", nil);
			alert.informativeText	= [NSString stringWithFormat:NSLocalizedString(@"Send.Retry.Msg", nil), retryInfo.toUser.userName];
			[alert addButtonWithTitle:NSLocalizedString(@"Send.Retry.OK", nil)];
			[alert addButtonWithTitle:NSLocalizedString(@"Send.Retry.Cancel", nil)];
			NSModalResponse ret = [alert runModal];
			if (ret == NSAlertSecondButtonReturn) {
				// 再送キャンセル
				// 添付情報破棄
				[self removeAttachmentUser:retryInfo.toUser
								  packetNo:retryInfo.packetNo
									fileID:_ANY_FILE_ID];
				// 応答待ちメッセージ一覧からメッセージのエントリを削除
				[self.sendList removeObjectForKey:retryKey];
				return;
			}
			// リトライ階数をリセットして再試行
			retryInfo.retryCount = 0;
			// タイマ再発行
			[NSTimer scheduledTimerWithTimeInterval:RETRY_INTERVAL
											 target:self
										   selector:@selector(retryMessage:)
										   userInfo:retryInfo.identifyKey
											repeats:YES];
		}
		// 再送信
		if (retryInfo.toUser.supportsEncrypt && !retryInfo.toUser.publicKey) {
			// 暗号化対応で公開鍵を未受信は鍵要求（次回リトライまでに鍵受信を期待）
			[self sendGetPubKeyTo:retryInfo.toUser];
		} else {
			// メッセージ送信
			[self sendTo:retryInfo.toUser
				packetNo:retryInfo.packetNo
				 command:retryInfo.command
				 message:retryInfo.message
				  option:retryInfo.option];
		}
		// リトライ回数インクリメント
		retryInfo.retryCount++;
	} else {
		// タイマ解除
		[timer invalidate];
	}
}

// 封書開封通知を送信
- (void)sendOpenSealMessage:(RecvMessage*)info
{
	if (info) {
		[self sendTo:info.fromUser
			packetNo:-1
			 command:IPMSG_READMSG
			  number:info.packetNo];
	}
}

// 添付破棄通知を送信
- (void)sendReleaseAttachmentMessage:(RecvMessage*)info
{
	if (info) {
		[self sendTo:info.fromUser
			packetNo:-1
			 command:IPMSG_RELEASEFILES
			  number:info.packetNo];
	}
}

// 公開鍵要求を送信
- (void)sendGetPubKeyTo:(UserInfo*)user
{
	CryptoCapability*	selfCap	= CryptoManager.sharedManager.selfCapability;
	UInt32				capMask	= [self encodeCryptoCapability:selfCap];
	[self sendTo:user
		packetNo:-1
		 command:IPMSG_GETPUBKEY
		 message:[NSString stringWithFormat:@"%X", capMask]
		  option:nil];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 添付ファイル管理
/*----------------------------------------------------------------------------*/

// 送信済み添付ファイル一覧
- (NSArray<SendAttachment*>*)sentAttachments
{
	@synchronized (self.attachList) {
		return [NSArray<SendAttachment*> arrayWithArray:self.attachList];
	}
}

// 送信添付ファイル情報追加
- (void)addAttachment:(SendAttachment*)attach
{
	BOOL changed = NO;
	@synchronized (self.attachList) {
		if (![self.attachList containsObject:attach]) {
			[self.attachList addObject:attach];
			changed = YES;
		}
	}
	if (changed) {
		[self fireAttachListChangeNotice];
	}
}

// 送信添付ファイル情報削除
- (void)removeAttachment:(SendAttachment*)attach
{
	BOOL changed = NO;
	@synchronized (self.attachList) {
		if ([self.attachList containsObject:attach]) {
			[self.attachList removeObject:attach];
			changed = YES;
		}
	}
	if (changed) {
		[self fireAttachListChangeNotice];
	}
}

// 添付ファイル送信ユーザ削除
- (void)removeAttachmentUser:(UserInfo*)user packetNo:(NSInteger)pNo fileID:(NSInteger)fid
{
	__block BOOL changed = NO;
	@synchronized (self.attachList) {
		NSMutableIndexSet* trash = [NSMutableIndexSet indexSet];
		[self.attachList enumerateObjectsUsingBlock:^(SendAttachment* _Nonnull attach, NSUInteger idx, BOOL* _Nonnull stop) {
			if (((attach.packetNo == pNo) || (pNo == _ANY_PACKET_NO)) &&
				((attach.fileID == fid) || (fid == _ANY_FILE_ID))) {
				if ([attach.remainUsers containsObject:user]) {
					NSInteger remain = [attach removeUser:user];
					if (remain <= 0) {
						[trash addIndex:idx];
					}
					changed = YES;
				}
				if ((pNo != _ANY_PACKET_NO) && (fid != _ANY_FILE_ID)) {
					*stop = YES;
				}
			}
		}];
		if (trash.count > 0) {
			[self.attachList removeObjectsAtIndexes:trash];
		}
	}
	if (changed) {
		[self fireAttachListChangeNotice];
	}
}

// 添付管理情報変更通知発行
- (void)fireAttachListChangeNotice
{
	NSNotificationCenter* nc = NSNotificationCenter.defaultCenter;
	[nc postNotificationName:kIPMsgAttachmentListChangedNotification object:nil];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 添付ファイルダウンロード
/*----------------------------------------------------------------------------*/

// ダウンロード開始
- (id<DownloaderContext>)startDownload:(NSArray<RecvFile*>*)attachments
									  of:(NSInteger)packetNo
									from:(UserInfo*)fromUser
									  to:(NSString*)savePath
								delegate:(id<DownloaderDelegate>)listener
{
	AttachDLContextImpl* dl = [[AttachDLContextImpl alloc] init];

	dl.attachments	= attachments;
	dl.packetNo		= packetNo;
	dl.fromUser		= fromUser;
	dl.savePath		= savePath;
	dl.delegate		= listener;
	dl.tcpSocket	= -1;
	dl.stop			= NO;

	[self performSelectorInBackground:@selector(downloadThread:) withObject:dl];

	return dl;
}

// ダウンロード終了
- (void)stopDownload:(id<DownloaderContext>)ctx
{
	if ([ctx isKindOfClass:AttachDLContextImpl.class]) {
		AttachDLContextImpl* dl = ctx;
		dl.stop = YES;
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - メッセージ送信処理（内部利用）
/*----------------------------------------------------------------------------*/

// データ送信実処理
- (NSInteger)sendTo:(struct sockaddr_in*)toAddr packetNo:(NSInteger)pNo command:(UInt32)cmd data:(NSData*)data
{
	Config*	config = Config.sharedConfig;

	// 不在モードチェック
	if (config.inAbsence) {
		cmd |= IPMSG_ABSENCEOPT;
	}
	// ダイアルアップチェック
	if (config.dialup) {
		cmd |= IPMSG_DIALUPOPT;
	}

	// パケットNo採番
	if (pNo < 0) {
		pNo = MessageCenter.nextPacketNo;
	}

	// メッセージヘッダ部編集
	NSString*	headerStr	= [NSString stringWithFormat:@"%d:%d:%@:%@:%d:",
								IPMSG_VERSION, (UInt32)pNo, self.selfLogOnName, AppControlGetHostName(), cmd];
	NSData*		headerData	= [headerStr dataUsingUTF8:NO nullTerminate:NO];

	// 送信データ作成
	NSData* sendData = nil;
	if (data.length > 0) {
		NSMutableData*	sendMutableData	= [NSMutableData dataWithCapacity:headerData.length + data.length];
		[sendMutableData appendData:headerData];
		[sendMutableData appendData:data];
		sendData = sendMutableData;
	} else {
		sendData = headerData;
	}

	// パケットサイズあふれ調整
	size_t len = sendData.length;
	if (len > MAX_UDPBUF) {
		len = MAX_UDPBUF;
	}

	// 送信
	sendto(self.udpSocket, sendData.bytes, len, 0, (struct sockaddr*)toAddr, sizeof(struct sockaddr_in));

	return pNo;
}

- (NSInteger)sendTo:(UserInfo*)toUser packetNo:(NSInteger)pNo command:(UInt32)cmd message:(NSString*)msg option:(NSString*)opt
{
	NSData*	sendData = nil;
	if (msg || opt) {
		BOOL useUTF8 = toUser.supportsUTF8;
		if (useUTF8) {
			cmd |= IPMSG_UTF8OPT;
		}
		if ((GET_MODE(cmd) == IPMSG_SENDMSG) && toUser.supportsEncrypt) {
			if (!toUser.publicKey) {
				// 公開鍵がある状態で呼び出されるはず（暗号化対応の相手に原則平文のメッセージを送ることはしない）
				ERR(@"RSA PublicKey not exist(%@,internal error)", toUser);
				return -1;
			}
			CryptoManager*		cm	= CryptoManager.sharedManager;
			CryptoCapability*	cap	= [cm.selfCapability capabilityMatchedWith:toUser.cryptoCapability];
			if (cap.supportEncryption) {
				_MSG_DBG(@"  ---- StartEncrpt ----");
				UInt32	spec		= 0;
				BOOL	encExtMsg	= (toUser.supportsEncExtMsg && ((self.selfSpec & IPMSG_ENCEXTMSGOPT) != 0));
				BOOL	useBase64	= cap.supportEncodeBase64;
				if (useBase64) {
					_MSG_DBG(@"  -> Binary Encode with Base64");
					spec |= IPMSG_ENCODE_BASE64;
				}

				// 暗号化対象生データ作成（末尾NULL文字までデータに含める）
				double	binRatio	= useBase64 ? (4.0/3.0) : 2.0;
				size_t	keySize		= (toUser.publicKey.modulus.length * binRatio + 3);
				size_t	msgMax		= MAX_UDPBUF - 1024 - keySize;
				NSData*	msgData		= nil;
				NSData* optData		= nil;
				NSData* srcData		= nil;
				if (cap.supportSignSHA256 || cap.supportSignSHA1) {
					msgMax -= keySize;
				}
				if (opt) {
					optData = [opt dataUsingUTF8:useUTF8 nullTerminate:YES];
					msgMax -= optData.length * binRatio;
				}
				msgMax /= binRatio;
				msgData = [msg dataUsingUTF8:useUTF8 nullTerminate:YES maxLength:msgMax];
				if (optData && encExtMsg) {
					_MSG_DBG(@"  -> Option Data exist(%zdbytes -> join to msg to encrypt)", optData.length);
					NSMutableData* joinedData = [NSMutableData dataWithCapacity:msgData.length + optData.length];
					[joinedData appendData:msgData];
					[joinedData appendData:optData];
					srcData = joinedData;
					cmd |= IPMSG_ENCEXTMSGOPT;
				} else {
					srcData = msgData;
				}

				// InitialVector作成
				char ivArray[256/8];
				memset(ivArray, 0, sizeof(ivArray));
				if (cap.supportPacketNoIV) {
					snprintf(ivArray, sizeof(ivArray) - 1, "%u", (unsigned)pNo);
					spec |= IPMSG_PACKETNO_IV;
					_MSG_DBG(@"  -> iv(packetNo:%ld)", pNo);
				} else {
					_MSG_DBG(@"  -> iv(all zero)");
				}
				NSData* ivData = [NSData dataWithBytesNoCopy:ivArray length:sizeof(ivArray) freeWhenDone:NO];
				_MSG_DBG(@"  -> InitialVector(%@)", ivData);

				// 本文暗号化
				NSData* sessionKey		= nil;
				NSData* encryptedData	= nil;
				if (cap.supportAES256) {
					sessionKey		= [cm randomData:256/8];
					encryptedData	= [cm encryptAES:srcData key:sessionKey iv:ivData];
					if (!encryptedData) {
						ERR(@"RSA256 encryption error");
						return -1;
					}
					_MSG_DBG(@"  -> Encrypt with AES256 succeeded(%ldbytes->%ldbytes)", srcData.length, encryptedData.length);
					spec |= IPMSG_AES_256;
				} else if (cap.supportBlowfish128) {
					sessionKey		= [cm randomData:128/8];
					encryptedData	= [cm encryptBlowfish:srcData key:sessionKey iv:ivData];
					if (!encryptedData) {
						ERR(@"Blowfish128 encryption error");
						return -1;
					}
					_MSG_DBG(@"  -> Encrypt with Blowfish128 succeeded(%ldbytes->%ldbytes)", srcData.length, encryptedData.length);
					spec |= IPMSG_BLOWFISH_128;
				}

				// セッションキー暗号化
				NSData* encryptedKey = nil;
				if (cap.supportRSA2048 && (toUser.publicKey.keySizeInBits == 2048)) {
					encryptedKey = [cm encryptRSA:sessionKey key:toUser.publicKey];
					if (!encryptedKey) {
						ERR(@"SessionKey ecnrtyption error(RSA2048)");
						return -1;
					}
					_MSG_DBG(@"  -> SessionKey Encrypt with RSA2048 succeeded(%ldbytes->%ldbytes)", sessionKey.length, encryptedKey.length);
					spec |= IPMSG_RSA_2048;
				} else if (cap.supportRSA1024 && (toUser.publicKey.keySizeInBits == 1024)) {
					encryptedKey = [cm encryptRSA:sessionKey key:toUser.publicKey];
					if (!encryptedKey) {
						ERR(@"SessionKey ecnrtyption error(RSA1024)");
						return -1;
					}
					_MSG_DBG(@"  -> SessionKey Encrypt with RSA1024 succeeded(%ldbytes->%ldbytes)", sessionKey.length, encryptedKey.length);
					spec |= IPMSG_RSA_1024;
				}

				// 署名作成
				NSData* signData = nil;
				if (cap.supportSignSHA256) {
					signData = [cm signSHA256:msgData privateKeyBitSize:toUser.publicKey.keySizeInBits];
					if (!signData) {
						ERR(@"Message signing error(SHA256)");
						return -1;
					}
					_MSG_DBG(@"  -> Signature(SHA256,length:%ld)", signData.length);
					spec |= IPMSG_SIGN_SHA256;
				} else if (cap.supportSignSHA1) {
					signData = [cm signSHA1:msgData privateKeyBitSize:toUser.publicKey.keySizeInBits];
					if (!signData) {
						ERR(@"Message signing error(SHA1)");
						return -1;
					}
					_MSG_DBG(@"  -> Signature(SHA1,length:%ld)", signData.length);
					spec |= IPMSG_SIGN_SHA1;
				}

				// 送信メッセージ編集
				NSMutableString* encStr = [NSMutableString string];
				[encStr appendFormat:@"%X:", spec];
				[encStr appendString:[encryptedKey binaryEncodedStringUsingBase64:useBase64]];
				[encStr appendString:@":"];
				[encStr appendString:[encryptedData binaryEncodedStringUsingBase64:useBase64]];
				if (signData) {
					[encStr appendString:@":"];
					[encStr appendString:[signData binaryEncodedStringUsingBase64:useBase64]];
				}
				cmd |= IPMSG_ENCRYPTOPT;
				_MSG_DBG(@"  -> Message Text encrypted(%zdcharcters)", encStr.length);

				NSData* encData = [encStr dataUsingUTF8:useUTF8 nullTerminate:YES];
				if (optData && !encExtMsg) {
					_MSG_DBG(@"  -> Option Data exist(%zdbytes) -> append plain text to tail", optData.length);
					NSMutableData* sendMutableData = [NSMutableData dataWithCapacity:encData.length + optData.length];
					[sendMutableData appendData:encData];
					[sendMutableData appendData:optData];
					sendData = sendMutableData;
				} else {
					_MSG_DBG(@"  -> No Option Data");
					sendData = encData;
				}
				_MSG_DBG(@"  -> Message Data edited(%zdbytes)", sendData.length);
				_MSG_DBG(@"  ---- FinishEncrpt ----");
			}
		} else {
			NSData* msgData = [msg dataUsingUTF8:useUTF8 nullTerminate:YES];
			if (opt) {
				NSData*			optData			= [opt dataUsingUTF8:useUTF8 nullTerminate:YES];
				NSMutableData*	sendMutableData	= [NSMutableData dataWithCapacity:msgData.length + optData.length];
				[sendMutableData appendData:msgData];
				[sendMutableData appendData:optData];
				sendData = sendMutableData;
			} else {
				sendData = msgData;
			}
		}
	}

	struct sockaddr_in addr = toUser.address;
	return [self sendTo:&addr
			   packetNo:pNo
				command:cmd
				   data:sendData];
}

- (NSInteger)sendTo:(UserInfo*)toUser packetNo:(NSInteger)pNo command:(UInt32)cmd number:(NSInteger)num
{
	return [self sendTo:toUser
			   packetNo:pNo
				command:cmd
				message:[NSString stringWithFormat:@"%ld", num]
				 option:nil];
}

- (NSData*)makeEntryMessageData
{
	Config*			config	= Config.sharedConfig;
	NSMutableData*	data	= [NSMutableData dataWithCapacity:256];

	// ユーザ名
	NSString* user = config.userName;
	if (user.length <= 0) {
		user = self.selfLogOnName;
	}

	// 不在情報
	NSString* absence = @"";
	if (config.inAbsence) {
		absence = [NSString stringWithFormat:@"[%@]", [config absenceTitleAtIndex:config.absenceIndex]];
	}

	// ニックネーム
	[data appendData:[user dataUsingUTF8:NO nullTerminate:NO]];
	if (absence.length > 0) {
		[data appendData:[absence dataUsingUTF8:NO nullTerminate:NO]];
	}

	// グループ化拡張セパレータ
	[data appendBytes:"\0" length:1];

	// グループ名
	NSString* group = config.groupName;
	if (group.length > 0) {
		[data appendData:[group dataUsingUTF8:NO nullTerminate:NO]];
	}

	// UTF-8拡張セパレータ
	[data appendBytes:"\0\n" length:2];

	// UTF-8文字列
	NSMutableString* utf8Str = [NSMutableString stringWithCapacity:256];
	[utf8Str appendFormat:@"UN:%@\n", self.selfLogOnName];
	[utf8Str appendFormat:@"HN:%@\n", AppControlGetHostName()];
	[utf8Str appendFormat:@"NN:%@%@\n", user, absence];
	if (group.length > 0) {
		[utf8Str appendFormat:@"GN:%@\n", group];
	}
	[data appendData:[utf8Str dataUsingUTF8:YES nullTerminate:NO]];
	[data appendBytes:"\0" length:1];

	return data;
}

/*----------------------------------------------------------------------------*/
#pragma mark - メッセージ受信処理（内部利用）
/*----------------------------------------------------------------------------*/

// 受信後実処理
- (void)processReceiveMessageBuffer:(char*)buff
							 length:(ssize_t)len
							   from:(struct sockaddr_in)fromAddr
{
	// 末尾余白削除
	buff[len] = '\0';
	while ((len > 0) && (buff[len-1] == '\0')) {
		len--;
	}
	_MSG_TRC(@"real data is %ld bytes", len);

	// 追加部オプション文字列分解
	char* option1	= NULL;		// 追加部オプションC文字列
	char* option2	= NULL;		// 追加部オプションUTF-8文字列（ENTRY系コマンド用）
	if ((len + 1) - (strlen(buff) + 1) > 0) {
		option1 = &buff[strlen(buff) + 1];
		TRC(@"\toption1       =\"%s\"(len=%ld[%lu,%ld])", option1, (len + 1) - (strlen(buff) + 1), len, strlen(buff));
		if ((len + 1) - (strlen(buff) + 1) - (strlen(option1) + 1) > 0) {
			option2 = &option1[strlen(option1) + 2];
			TRC(@"\toption2       =\"%s\"(len=%ld[%lu,%ld,%ld])", option2, (len + 1) - (strlen(buff) + 1) - (strlen(option1) + 1), len, strlen(buff), strlen(option2));
		}
	}

	// 共通フォーマット解析
	NSInteger	packetNo	= 0;	// パケット番号
	NSString*	logOnUser	= nil;	// ログイン名
	NSString*	hostName	= nil;	// ホスト名
	UInt32		command		= 0;	// コマンド番号
	NSString*	appendix	= nil;	// 追加部
	char*		ptr;				// ワーク
	char*		tok;				// ワーク

	// バージョン番号チェック
	if (!(tok = strtok_r(buff, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(version get error,\"%s\")", buff);
		return;
	}
	if (strtol(tok, NULL, 10) != IPMSG_VERSION) {
		ERR(@"msg:version invalid(%ld)", strtol(tok, NULL, 10));
		return;
	}
	TRC(@"\tversion       =%d(OK)", IPMSG_VERSION);

	// パケット番号
	if (!(tok = strtok_r(NULL, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(version get error,\"%s\")", buff);
		return;
	}
	packetNo = strtol(tok, NULL, 10);
	TRC(@"\tpacketNo      =%ld", packetNo);

	// ログイン名退避
	if (!(tok = strtok_r(NULL, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(logOn get error,\"%s\")", buff);
		return;
	}
	char* logOnUserPtr = tok;

	// ホスト名退避
	if (!(tok = strtok_r(NULL, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(host get error,\"%s\")", buff);
		return;
	}
	char* hostNamePtr = tok;

	// コマンド番号
	if (!(tok = strtok_r(NULL, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(command get error,\"%s\")", buff);
		return;
	}
	command = (UInt32)strtoul(tok, NULL, 10);
	TRC(@"\tcommand       =0x%08X", command);

	BOOL useUTF8 = ((command & IPMSG_UTF8OPT) != 0);
	TRC(@"\t (UTF8OPT     =%d)", useUTF8);

	// ログイン名
	logOnUser = [NSString stringWithCString:logOnUserPtr utf8Encoded:useUTF8];
	TRC(@"\tlogOnUser     =%@", logOnUser);

	// ホスト名
	hostName = [NSString stringWithCString:hostNamePtr utf8Encoded:useUTF8];
	TRC(@"\thostName      =%@", hostName);

	// 追加部
	if (ptr) {
		appendix = [NSString stringWithCString:ptr utf8Encoded:useUTF8];
	}
	TRC(@"\tappendix      =%@", appendix);

	// 追加部オプション
	NSString* appendixOption = nil;
	if (option1) {
		appendixOption = [NSString stringWithCString:option1 utf8Encoded:useUTF8];
	}
	TRC(@"\tappendixOption=%@", appendixOption);

	// ENTRY系パケットのUTF-8文字列差し替え
	switch (GET_MODE(command)) {
	case IPMSG_BR_ENTRY:
	case IPMSG_BR_ABSENCE:
		if ((command & IPMSG_CAPUTF8OPT) && option2) {
			// UTF8指定文字列があれば置き換え
			NSString*			utf8 = [NSString stringWithUTF8String:option2];
			NSArray<NSString*>*	strs = [utf8 componentsSeparatedByString:@"\n"];
			for (NSString* str in strs) {
				if (str.length <= 0) {
					continue;
				}
				NSArray<NSString*>*	kv	= [str componentsSeparatedByString:@":"];
				NSString*			key	= kv[0];
				NSString*			val	= kv[1];
				if ([key isEqualToString:@"UN"]) {
					logOnUser = val;
					TRC(@"\tUTF8-UN  =%@", logOnUser);
				} else if ([key isEqualToString:@"HN"]) {
					hostName = val;
					TRC(@"\tUTF8-HN  =%@", hostName);
				} else if ([key isEqualToString:@"NN"]) {
					appendix = val;
					TRC(@"\tUTF8-NN  =%@", appendix);
				} else if ([key isEqualToString:@"GN"]) {
					appendixOption = val;
					TRC(@"\tUTF8-GN  =%@", appendixOption);
				} else {
					WRN(@"unknown UTF8 entry kv(%@:%@)", key, val);
				}
			}
		}
		break;
	}

	// 送信元ユーザ特定
	BOOL isUnknownUser = NO;
	UserInfo* fromUser = [UserManager.sharedManager userForLogOnUser:logOnUser
															 address:&fromAddr];
	if (!fromUser) {
		// 未知のユーザ
		isUnknownUser = YES;
		fromUser = [UserInfo userWithHostName:hostName logOnName:logOnUser address:&fromAddr];
	}

	Config* config = Config.sharedConfig;

	// 受信メッセージに応じた処理
	switch (GET_MODE(command)) {
	/*-------- 無処理メッセージ ---------*/
	case IPMSG_NOOPERATION:
		// NOP
		_MSG_DBG(@"command=IPMSG_NOOPERATION");
		_MSG_DBG(@"        > nop");
		break;
	/*-------- ユーザエントリ系メッセージ ---------*/
	case IPMSG_BR_ENTRY:
	case IPMSG_ANSENTRY:
	case IPMSG_BR_ABSENCE:
		_MSG_DBG(@"command=IPMSG_BR_ENTRY|IPMSG_ANSENTRY|IPMSG_BR_ABSENCE");
		if (fromUser.fingerPrint && ((command & IPMSG_ENCRYPTOPT) == 0)) {
			// 公開鍵指紋つきでENCRYPTOPTが立っていないメッセージは破棄
			ERR(@"        > Cancel (has FingerPrint although enryption not support)");
			break;
		}
		if (!isUnknownUser) {
			// 既知のユーザからのENTRY系パケット受信時はユーザ情報を更新
			fromUser = [UserInfo userWithHostName:hostName
										logOnName:logOnUser
										  address:&fromAddr];
		}
		fromUser.userName			= appendix;
		fromUser.groupName			= appendixOption;
		fromUser.inAbsence			= (BOOL)((command & IPMSG_ABSENCEOPT) != 0);
		fromUser.dialupConnect		= (BOOL)((command & IPMSG_DIALUPOPT) != 0);
		fromUser.supportsAttachment	= (BOOL)((command & IPMSG_FILEATTACHOPT) != 0);
		fromUser.supportsEncrypt	= (BOOL)((command & IPMSG_ENCRYPTOPT) != 0);
		fromUser.supportsEncExtMsg	= (BOOL)((command & IPMSG_ENCEXTMSGOPT) != 0);
		fromUser.supportsUTF8		= (BOOL)((command & IPMSG_CAPUTF8OPT) != 0);
		if ([config matchRefuseCondition:fromUser]) {
			_MSG_DBG(@"        > Refuse (Condition matched[%@])", fromUser.summaryString);
			// 通知拒否ユーザにはBR_EXITを送って相手からみえなくする
			[self sendTo:&fromAddr
				packetNo:-1
				 command:IPMSG_BR_EXIT|self.selfSpec
					data:[self makeEntryMessageData]];
		} else {
			if (GET_MODE(command) == IPMSG_BR_ENTRY) {
				_MSG_DBG(@"        > IPMSG_BR_ENTRY");
				UInt32 ipAddress = AppControlGetIPAddress();
				if (ntohl(fromAddr.sin_addr.s_addr) != ipAddress) {
					// 応答を送信（自分自身以外）
					int64_t		delta	= 500 * NSEC_PER_MSEC;
					NSUInteger	userNum	= UserManager.sharedManager.users.count;
					if ((userNum < 50) || ((ipAddress ^ htonl(fromAddr.sin_addr.s_addr) << 8) == 0)) {
						// ユーザ数50人以下またはアドレス上位24bitが同じ場合 0 〜 1023 ms
						delta = (1023 & arc4random_uniform(INT32_MAX)) * NSEC_PER_MSEC;
					} else if (userNum < 300) {
						// ユーザ数が300人以下なら 0 〜 2047 ms
						delta = (2047 & arc4random_uniform(INT32_MAX)) * NSEC_PER_MSEC;
					} else {
						// それ以上は 0 〜 4095 ms
						delta = (4095 & arc4random_uniform(INT32_MAX)) * NSEC_PER_MSEC;
					}
					_MSG_DBG(@"        > Send ANS_ENTRY(after %lldms)", (delta / NSEC_PER_MSEC));
					dispatch_time_t		when 	= dispatch_time(DISPATCH_TIME_NOW, delta);
					dispatch_queue_t	queue	= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
					dispatch_after(when, queue, ^{
						Config*		cfg			= Config.sharedConfig;
						NSString*	userName	= cfg.userName;
						NSString*	groupName	= cfg.groupName;
						if (userName.length <= 0) {
							userName = NSUserName();
						}
						if (groupName.length <= 0) {
							groupName = nil;
						}
						[self sendTo:fromUser
							packetNo:-1
							 command:IPMSG_ANSENTRY|self.selfSpec
							 message:userName
							  option:groupName];
					});
				}
			}
			// ユーザ一覧に追加
			_MSG_DBG(@"        > Append User(%@)", fromUser);
			[UserManager.sharedManager appendUser:fromUser];
			// バージョン情報問い合わせ
			_MSG_DBG(@"        > Send IPMSG_GETINFO");
			[self sendTo:&fromAddr packetNo:-1 command:IPMSG_GETINFO data:nil];
		}
		break;
	case IPMSG_BR_EXIT:
		_MSG_DBG(@"command=IPMSG_BR_EXIT");
		_MSG_DBG(@"        > Remove User(%@)", fromUser.summaryString);
		// ユーザ一覧から削除
		[UserManager.sharedManager removeUser:fromUser];
		// 送信添付ファイル管理から削除
		[self removeAttachmentUser:fromUser
						  packetNo:_ANY_PACKET_NO
							fileID:_ANY_FILE_ID];
		break;
	/*-------- メッセージ関連 ---------*/
	case IPMSG_SENDMSG:		// メッセージ送信パケット
		_MSG_DBG(@"command=IPMSG_SENDMSG");
		if ((fromUser.fingerPrint && ((command & IPMSG_ENCRYPTOPT) == 0)) &&
			(!(command & IPMSG_AUTORETOPT) ||
			 (command & (IPMSG_PASSWORDOPT|IPMSG_SENDCHECKOPT|IPMSG_SECRETEXOPT|IPMSG_FILEATTACHOPT)))) {
			// 公開鍵指紋つきでENCRYPTOPTが立っていないメッセージは破棄
			_MSG_DBG(@"        > Cancel (has FingerPrint although enryption not support)");
			break;
		}
		if ((command & IPMSG_SENDCHECKOPT) &&
			!(command & IPMSG_AUTORETOPT) &&
			!(command & IPMSG_BROADCASTOPT)) {
			_MSG_DBG(@"        > Send IPMSG_RECVMSG");
			// RCVMSGを返す
			[self sendTo:fromUser
				packetNo:-1
				 command:IPMSG_RECVMSG
				  number:packetNo];
		}
		if (config.inAbsence &&
			!(command & IPMSG_AUTORETOPT) &&
			!(command & IPMSG_BROADCASTOPT)) {
			_MSG_DBG(@"        > Send IPMSG_SENDMSG(Absence)");
			// 不在応答を返す
			[self sendTo:fromUser
				packetNo:-1
				 command:IPMSG_SENDMSG|IPMSG_AUTORETOPT
				 message:[config absenceMessageAtIndex:config.absenceIndex]
				  option:nil];
		}
		if (isUnknownUser) {
			_MSG_DBG(@"        > Unknown user");
			// ユーザエントリ系メッセージをやりとりしていないユーザからの受信
			if ((command & IPMSG_NOADDLISTOPT) == 0) {
				_MSG_DBG(@"        > Send IPMSG_BR_ENTRY");
				// リストに追加するためにENTRYパケット送信
				[self sendTo:&fromAddr
					packetNo:-1
					 command:IPMSG_BR_ENTRY|self.selfSpec
						data:[self makeEntryMessageData]];
			}
		}
		// 暗号化メッセージの場合
		BOOL 		doubt 		= NO;
		NSInteger	secureLevel	= 0;
		if (command & IPMSG_ENCRYPTOPT) {
			// メッセージ復号
			_MSG_DBG(@"  ---- StartDecrpt ----");
			CryptoManager* cm = CryptoManager.sharedManager;
			NSArray<NSString*>* components = [appendix componentsSeparatedByString:@":"];

			// 暗号化スペック情報
			NSScanner* scanner = [NSScanner scannerWithString:components[0]];
			unsigned int val;
			if (![scanner scanHexInt:&val]) {
				ERR(@"security spec parse error(%@)", components[0]);
				break;
			}
			_MSG_DBG(@"  -> EncyrptSpec=0x%X", val);
			UInt32	capa		= (UInt32)val;
			BOOL	useBase64	= NO;
			if (capa & IPMSG_ENCODE_BASE64) {
				useBase64 = YES;
			}
			_MSG_DBG(@"  -> Base64     =%s", BOOLSTR(useBase64));

			// セッションキー復号
			_MSG_DBG(@"  -> BinaryDecodedKey:%ldbytes", components[1].length);
			NSData* encKey = [NSData dataWithBinaryEncodedString:components[1] base64Encoded:useBase64];
			if (!encKey) {
				ERR(@"sessionKey DecryptError(BinaryDecode,Base64=%s,src=%@)", BOOLSTR(useBase64), components[1]);
				break;
			}
			_MSG_DBG(@"    -> EncryptedKey  :%ldbytes", encKey.length);
			NSData* sessionKey = nil;
			if (capa & IPMSG_RSA_2048) {
				_MSG_DBG(@"      -> Decrypt RSA2048");
				sessionKey = [cm decryptRSA:encKey privateKeyBitSize:2048];
			} else if (capa & IPMSG_RSA_1024) {
				_MSG_DBG(@"      -> Decrypt RSA1024");
				sessionKey = [cm decryptRSA:encKey privateKeyBitSize:1024];
			}
			if (!sessionKey) {
				ERR(@"sessionKey DecryptError(RSADecryption,src=%@)", encKey);
				break;
			}
			_MSG_DBG(@"      -> SessionKey  :%ldbytes", sessionKey.length);

			// InitialVector作成
			char ivArray[256/8];
			memset(ivArray, 0, sizeof(ivArray));
			if (capa & IPMSG_PACKETNO_IV) {
				snprintf(ivArray, sizeof(ivArray) - 1, "%u", (unsigned)packetNo);
				_MSG_DBG(@"  -> iv(packetNo:%ld)", packetNo);
			} else {
				_MSG_DBG(@"  -> iv(all zero)");
			}
			NSData* ivData = [NSData dataWithBytesNoCopy:ivArray length:sizeof(ivArray) freeWhenDone:NO];
			_MSG_DBG(@"    -> %@", ivData);

			// メッセージ本文復号
			_MSG_DBG(@"  -> BinaryDecodedMsg:%ldbytes", components[2].length);
			NSData* encMsg = [NSData dataWithBinaryEncodedString:components[2] base64Encoded:useBase64];
			if (!encMsg) {
				ERR(@"message DecryptError(BinaryDecode,Base64=%s,src=%@)", BOOLSTR(useBase64), components[2]);
				break;
			}
			_MSG_DBG(@"    -> EncryptedMsg  :%ldbytes", encMsg.length);
			NSData* messageData = NULL;
			if (capa & IPMSG_AES_256) {
				messageData = [cm decryptAES:encMsg key:sessionKey iv:ivData];
			} else if (capa & IPMSG_BLOWFISH_128) {
				messageData = [cm decryptBlowfish:encMsg key:sessionKey iv:ivData];
			}
			if (!messageData) {
				ERR(@"message DecryptError(src=%@)", encMsg);
				break;
			}
			_MSG_DBG(@"      -> MsgData     :%ldbytes", messageData.length);

			if ((components.count >= 4) && (capa & (IPMSG_SIGN_SHA1|IPMSG_SIGN_SHA256))) {
				// 署名検証
				_MSG_DBG(@"  -> BinaryEncodedSign:%ldbytes", components[3].length);
				NSData* signature = [NSData dataWithBinaryEncodedString:components[3] base64Encoded:useBase64];
				if (!signature) {
					ERR(@"Sign VerifyError(BinaryDecode,Base64=%s,src=%@", BOOLSTR(useBase64), components[3]);
					break;
				}
				_MSG_DBG(@"    -> SingData       :%ldbytes", signature.length);
				if (fromUser.publicKey) {
					if (capa & IPMSG_SIGN_SHA256) {
						if (![cm verifySHA256:signature data:messageData key:fromUser.publicKey]) {
							WRN(@"Message not verified (doubt,SHA256)");
							doubt = YES;
						} else {
							_MSG_DBG(@"    -> Verified(SHA256 Signature OK).");
						}
					} else {
						if (![cm verifySHA1:signature data:messageData key:fromUser.publicKey]) {
							WRN(@"Message not verified (doubt,SHA1)");
							doubt = YES;
						} else {
							_MSG_DBG(@"    -> Verified(SHA1 Signature OK).");
						}
					}
				} else {
					WRN(@"No PublicKey of %@(can't verify)", fromUser);
				}
			}

			appendix = [NSString stringWithCString:(char*)messageData.bytes utf8Encoded:useUTF8];
			_MSG_DBG(@"      -> PlainText :%ldchars", appendix.length);
			if (command & IPMSG_ENCEXTMSGOPT) {
				unsigned long len = strlen((char*)messageData.bytes);
				if (len < messageData.length - 1) {
					option1 = (char*)&messageData.bytes[len + 1];
					_MSG_DBG(@"      -> attachments(encrypted option1) exist.");
				}
			}

			// 暗号化レベル判定
			if ((capa & IPMSG_RSA_2048) && (capa & IPMSG_AES_256)) {
				if (capa & IPMSG_SIGN_SHA256) {
					secureLevel = 4;
				} else if (capa & IPMSG_SIGN_SHA1) {
					secureLevel = 3;
				} else {
					secureLevel = 2;
				}
			} else if ((capa & IPMSG_RSA_1024) && (capa & IPMSG_BLOWFISH_128)) {
				secureLevel = 1;
			}

			_MSG_DBG(@"  ---- FinishDecrpt ----");
		}
		// 受信メッセージ情報構築
		RecvMessage* recvMsg = [[[RecvMessage alloc] init] autorelease];
		recvMsg.packetNo	= packetNo;
		recvMsg.receiveDate	= [NSDate date];
		recvMsg.fromUser	= fromUser;
		recvMsg.message		= appendix;
		recvMsg.secureLevel	= secureLevel;
		recvMsg.doubt		= doubt;
		recvMsg.sealed		= ((command & IPMSG_SECRETOPT) != 0);
		recvMsg.locked		= ((command & IPMSG_PASSWORDOPT) != 0);
		recvMsg.multicast	= ((command & IPMSG_MULTICASTOPT) != 0);
		recvMsg.broadcast	= ((command & IPMSG_BROADCASTOPT) != 0);
		recvMsg.absence		= ((command & IPMSG_AUTORETOPT) != 0);
		recvMsg.needLog		= config.standardLogEnabled;
		if ((command & IPMSG_FILEATTACHOPT) && option1) {
			NSString* attachMessage = [NSString stringWithCString:option1 utf8Encoded:useUTF8];
			[self parseReceivedAttachments:attachMessage to:recvMsg];
		}
		// 受信メッセージ処理（非同期）
		[self performSelectorInBackground:@selector(processReceivedMessage:) withObject:recvMsg];
		break;
	case IPMSG_RECVMSG:		// メッセージ受信確認パケット
		_MSG_DBG(@"command=IPMSG_RECVMSG");
		_MSG_DBG(@"        > Response waiting done(%@)", appendix);
		// 応答待ちメッセージ一覧から受信したメッセージのエントリを削除
		NSString* key = [RetryInfo identifyKeyForPacketNo:appendix.integerValue to:fromUser];
		[self.sendList removeObjectForKey:key];
		break;
	case IPMSG_READMSG:		// 封書開封通知パケット
		_MSG_DBG(@"command=IPMSG_READMSG");
		if (command & IPMSG_READCHECKOPT) {
			_MSG_DBG(@"        > Send IPMSG_ANSREADMSG");
			// READMSG受信確認通知をとばす
			[self sendTo:fromUser
				packetNo:-1
				 command:IPMSG_ANSREADMSG
				  number:packetNo];
		}
		if (config.noticeSealOpened) {
			// 封書が開封されたダイアログを表示
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NoticeControl alloc] initWithTitle:NSLocalizedString(@"SealOpenDlg.title", nil)
											 message:fromUser.summaryString
												date:nil];
			});
		}
		break;
	case IPMSG_DELMSG:		// 封書破棄通知パケット
		_MSG_DBG(@"command=IPMSG_DELMSG");
		_MSG_DBG(@"        > nop");
		// 無処理
		break;
	case IPMSG_ANSREADMSG:
		_MSG_DBG(@"command=IPMSG_ANSREADMSG");
		_MSG_DBG(@"        > nop");
		// READMSGの確認通知。やるべきことは特になし
		break;
	/*-------- 情報取得関連 ---------*/
	case IPMSG_GETINFO:		// 情報取得要求
		_MSG_DBG(@"command=IPMSG_GETINFO");
		// バージョン情報のパケットを返す
		_MSG_DBG(@"        > Response VersionInfo(%@)", self.selfVersion);
		[self sendTo:fromUser
			packetNo:-1
			 command:IPMSG_SENDINFO
			 message:self.selfVersion
			  option:nil];
		break;
	case IPMSG_SENDINFO:	// バージョン情報
		_MSG_DBG(@"command=IPMSG_SENDINFO");
		_MSG_DBG(@"        > Version Info(%@=%@)", fromUser.summaryString, appendix);
		// バージョン情報をユーザ情報に設定
		fromUser.version = appendix;
		[UserManager.sharedManager appendUser:fromUser];
		break;
	/*-------- 不在関連 ---------*/
	case IPMSG_GETABSENCEINFO:
		_MSG_DBG(@"command=IPMSG_GETABSENCEINFO");
		// 不在文のパケットを返す
		if (config.inAbsence) {
			_MSG_DBG(@"        > Response I'm absence(%@)", [config absenceMessageAtIndex:config.absenceIndex]);
			[self sendTo:fromUser
			   packetNo:-1
				 command:IPMSG_SENDABSENCEINFO
				 message:[config absenceMessageAtIndex:config.absenceIndex]
				  option:nil];
		} else {
			_MSG_DBG(@"        > Response I'm not absence");
			[self sendTo:fromUser
				packetNo:-1
				 command:IPMSG_SENDABSENCEINFO
				 message:@"Not Absence Mode."
				  option:nil];
		}
		break;
	case IPMSG_SENDABSENCEINFO:
		_MSG_DBG(@"command=IPMSG_SENDABSENCEINFO");
		_MSG_DBG(@"        > show AbasenceInfo(%@[%@])", fromUser.summaryString, appendix);
		// 不在情報をダイアログに出す
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NoticeControl alloc] initWithTitle:fromUser.summaryString
										 message:appendix
											date:nil];
		});
		break;
	/*-------- 添付関連 ---------*/
	case IPMSG_RELEASEFILES:	// 添付破棄通知
		_MSG_DBG(@"command=IPMSG_RELEASEFILES");
		_MSG_DBG(@"        > remove from AttachmentServer(user=%@,message=%@)", fromUser.summaryString, appendix);
		[self removeAttachmentUser:fromUser
						  packetNo:appendix.integerValue
							fileID:_ANY_FILE_ID];
		break;
	/*-------- 暗号化関連 ---------*/
	case IPMSG_GETPUBKEY:		// 公開鍵要求
		_MSG_DBG(@"command=IPMSG_GETPUBKEY:%@", appendix);
		CryptoManager* cm = CryptoManager.sharedManager;
		if (cm.selfCapability.supportEncryption) {
			_MSG_DBG(@"        > send IPMSG_ANSPUBKEY");
			UInt32 userCapa	= (UInt32)appendix.integerValue;
			UInt32 selfCapa = [self encodeCryptoCapability:cm.selfCapability];
			UInt32 capa		= userCapa & selfCapa;
			RSAPublicKey* key = cm.publicKey1024;
			if (capa & IPMSG_RSA_2048) {
				key = cm.publicKey2048;
			}
			NSString* msg = [NSString stringWithFormat:@"%X:%X-%@",
							 selfCapa, key.exponent, key.modulus.hexEncodedString];
			_MSG_DBG(@"        > Capa:%X,PublicKey=RSA%ld", selfCapa, key.keySizeInBits);
			[self sendTo:fromUser
				packetNo:-1
				 command:IPMSG_ANSPUBKEY
				 message:msg
				  option:nil];
		} else {
			_MSG_DBG(@"        > nop (encryption not support)");
		}
		break;
	case IPMSG_ANSPUBKEY:
		_MSG_DBG(@"command=IPMSG_ANSPUBKEY");
		_MSG_DBG(@"        > parse CryptoCapability and PublicKey");
		[self parseAnsPubkey:appendix from:fromUser];
		if (fromUser.publicKey) {
			// 公開鍵が受信できたので、対象ユーザへのメッセージを即送信
			for (RetryInfo* retryInfo in self.sendList.allValues) {
				if ([retryInfo.toUser isEqual:fromUser]) {
					_MSG_DBG(@"        > send Pendding message(%ld) to %@", retryInfo.packetNo, fromUser);
					// メッセージ送信
					[self sendTo:retryInfo.toUser
						packetNo:retryInfo.packetNo
						 command:retryInfo.command
						 message:retryInfo.message
						  option:retryInfo.option];
				}
			}
		}
		break;
	/*-------- ホストリスト関連 ---------*/
	case IPMSG_BR_ISGETLIST:
		// NOP
		_MSG_DBG(@"command=IPMSG_BR_ISGETLIST");
		_MSG_DBG(@"        > nop");
		break;
	case IPMSG_OKGETLIST:
		// NOP
		_MSG_DBG(@"command=IPMSG_OKGETLIST");
		_MSG_DBG(@"        > nop");
		break;
	case IPMSG_GETLIST:
		// NOP
		_MSG_DBG(@"command=IPMSG_GETLIST");
		_MSG_DBG(@"        > nop");
		break;
	case IPMSG_BR_ISGETLIST2:
		// NOP
		_MSG_DBG(@"command=IPMSG_BR_ISGETLIST2");
		_MSG_DBG(@"        > nop");
		break;
	case IPMSG_ANSLIST:
		_MSG_DBG(@"command=IPMSG_ANSLIST");
		NSInteger hostListContinueCount = [self processReceivedHostList:appendix];
		if (hostListContinueCount > 0) {
			_MSG_DBG(@"        > Send IPMSG_GETLIST(%ld)", hostListContinueCount);
			// 継続のGETLIST送信
			[self sendTo:fromUser
				packetNo:-1
				 command:IPMSG_GETLIST
				  number:hostListContinueCount];
		} else {
			_MSG_DBG(@"        > Send IPMSG_BR_ENTRY");
			// BR_ENTRY送信（受信したホストに教えるため）
			[self broadcastEntry];
		}
		break;
	/*-------- その他パケット／未知パケット（を受信） ---------*/
	default:
		ERR(@"Unknown command Received(0x%08X,0x%08lX)", command, GET_MODE(command));
		break;
	}
}

// 受信添付ファイル解析処理
- (void)parseReceivedAttachments:(NSString*)attachMessage to:(RecvMessage*)recvMsg
{
	NSMutableArray<RecvFile*>*		files = [NSMutableArray<RecvFile*> array];
	NSMutableArray<RecvClipboard*>* clips = [NSMutableArray<RecvClipboard*> array];

	// 区切りが":\a:"の場合と、":\a"の場合とありえる
	NSArray<NSString*>* attachList = [attachMessage componentsSeparatedByString:@":\a"];
	if (attachList.count > 0) {
		for (NSString* attachStr in attachList) {
			TRC(@"attach string(%@)", attachStr);
			if (attachStr.length <= 0) {
				TRC(@"attach empty1 -> continue");
				continue;
			}
			if ([attachStr characterAtIndex:0] == ':') {
				// 区切りが":\a:"だった場合、先頭の:を削る
				attachStr = [attachStr substringFromIndex:1];
				TRC(@"attach striped(%@)", attachStr);
				if (attachStr.length <= 0) {
					TRC(@"attach empty2 -> continue");
					continue;
				}
			}
			NSRange		range		= [attachStr rangeOfString:@":"];
			NSString*	fileIDStr	= [attachStr substringToIndex:range.location];
			NSString*	infoStr		= [attachStr substringFromIndex:range.location + 1];
			RecvAttachment* attach = [self parseAttachmentBuffer:infoStr needReadModTime:YES];
			if (attach) {
				attach.fileID = fileIDStr.integerValue;
				if ([attach isKindOfClass:RecvFile.class]) {
					[files addObject:(RecvFile*)attach];
				} else if ([attach isKindOfClass:RecvClipboard.class]) {
					[clips addObject:(RecvClipboard*)attach];
				} else {
					// err
				}
			}
		}
	}

	if (files.count > 0) {
		recvMsg.attachments = [NSArray<RecvFile*> arrayWithArray:files];
	}
	if (clips.count > 0) {
		recvMsg.clipboards = [NSArray<RecvClipboard*> arrayWithArray:clips];
		DBG(@"%ld clipboard image exists(pNo=%ld)", recvMsg.clipboards.count, recvMsg.packetNo);
	}
}

- (void)processReceivedMessage:(RecvMessage*)recvMsg
{
	@autoreleasepool {
		if (recvMsg.clipboards.count > 0) {
			// 埋め込みクリップボードをダウンロード
			AttachDLContextImpl* dl = [[AttachDLContextImpl alloc] init];

			dl.attachments	= recvMsg.clipboards;
			dl.packetNo		= recvMsg.packetNo;
			dl.fromUser		= recvMsg.fromUser;
			dl.tcpSocket	= -1;
			dl.stop			= NO;

			// あえて同期で呼び出し（ダウンロードしきってメッセージ表示するため）
			[self performSelector:@selector(downloadThread:) withObject:dl];
		}
		// 受信処理（非同期）
		dispatch_async(dispatch_get_main_queue(), ^{
			[(AppControl*)NSApp.delegate receiveMessage:recvMsg];
		});
	}
}

// 受信ホストリスト解析処理
- (NSInteger)processReceivedHostList:(NSString*)hostListMessage
{
	NSInteger continueCount = 0;
	if (hostListMessage.length > 0) {
		NSArray<NSString*>*	lists = [hostListMessage componentsSeparatedByString:@"\a"];
		if (lists.count > 2) {
			NSInteger totalCount = lists[1].integerValue;
			if (totalCount > 0) {
				continueCount = lists[0].integerValue;
				if (lists.count < (totalCount * 7 + 2)) {
					WRN(@"hostlist:invalid data(items=%ld,totalCount=%ld,%@)", lists.count, totalCount, self);
					totalCount = (lists.count - 2) / 7;
				}
				Config* config = Config.sharedConfig;
				for (NSInteger i = 0; i < totalCount; i++) {
					NSArray<NSString*>*	itemArray		= [lists subarrayWithRange:NSMakeRange(i * 7 + 2, 7)];
					NSString*			itemLogOnName	= itemArray[0];
					NSString*			itemHostName	= itemArray[1];
					UInt32				itemCommand		= (UInt32)[itemArray[2] integerValue];
					NSString*			itemAddrStr		= itemArray[3];
					UInt32				itemAddrNum		= (UInt32)inet_addr([itemAddrStr UTF8String]);
					UInt16				itemPort		= (UInt16)[itemArray[4] integerValue];
					NSString*			itemUserName	= itemArray[5];
					NSString*			itemGroupName	= itemArray[6];

					struct sockaddr_in itemAddr;
					itemAddr.sin_family			= AF_INET;
					itemAddr.sin_addr.s_addr	= itemAddrNum;
					itemAddr.sin_port			= itemPort;

					if ([itemUserName isEqualToString:@"\b"]) {
						itemUserName = nil;
					}
					if ([itemGroupName isEqualToString:@"\b"]) {
						itemGroupName = nil;
					}

					UserInfo* newUser = [UserInfo userWithHostName:itemHostName
														 logOnName:itemLogOnName
														   address:&itemAddr];
					if (newUser) {
						newUser.userName			= itemUserName;
						newUser.groupName			= itemGroupName;
						newUser.inAbsence			= (BOOL)((itemCommand & IPMSG_ABSENCEOPT) != 0);
						newUser.dialupConnect		= (BOOL)((itemCommand & IPMSG_DIALUPOPT) != 0);
						newUser.supportsAttachment	= (BOOL)((itemCommand & IPMSG_FILEATTACHOPT) != 0);
						newUser.supportsEncrypt		= (BOOL)((itemCommand & IPMSG_ENCRYPTOPT) != 0);
						newUser.supportsEncExtMsg	= (BOOL)((itemCommand & IPMSG_ENCEXTMSGOPT) != 0);
						newUser.supportsUTF8		= (BOOL)((itemCommand & IPMSG_CAPUTF8OPT) != 0);
						if (![config matchRefuseCondition:newUser]) {
							_MSG_DBG(@"        > Append User([%ld/%ld] %@)", i + 1, totalCount, newUser.summaryString);
							[UserManager.sharedManager appendUser:newUser];
						}
					}
				}
			}
		}
	}
	return continueCount;
}

/*----------------------------------------------------------------------------*/
#pragma mark - 添付ファイル送信処理（内部利用）
/*----------------------------------------------------------------------------*/

// リクエスト受信後実処理
- (void)processAttachmentRequestBuffer:(char*)buff
								length:(ssize_t)len
								  from:(struct sockaddr_in)fromAddr
								socket:(int)sock
{
	// リクエスト解析
	buff[len] = '\0';
	DBG(@"recvRequest(%s)", buff);

	// 共通フォーマット解析
	NSInteger	packetNo		= 0;	// パケット番号
	const char*	logOnUserCStr	= NULL;	// ログイン名（C文字列）
	NSString*	logOnUser		= nil;	// ログイン名
	const char* hostNameCStr	= NULL;	// ホスト名（C文字列）
	NSString*	hostName		= nil;	// ホスト名
	UInt32		command			= 0;	// コマンド番号
	NSString*	appendix		= nil;	// 追加部
	char*		ptr;					// ワーク
	char*		tok;					// ワーク

	// バージョン番号チェック
	if (!(tok = strtok_r(buff, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(version get error,\"%s\")", buff);
		return;
	}
	if (strtol(tok, NULL, 10) != IPMSG_VERSION) {
		ERR(@"msg:version invalid(%ld)", strtol(tok, NULL, 10));
		return;
	}
	TRC(@"\tversion       =%d(OK)", IPMSG_VERSION);

	// パケット番号
	if (!(tok = strtok_r(NULL, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(version get error,\"%s\")", buff);
		return;
	}
	packetNo = strtol(tok, NULL, 10);
	TRC(@"\tpacketNo      =%ld", packetNo);

	// ログイン名
	if (!(tok = strtok_r(NULL, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(logOn get error,\"%s\")", buff);
		return;
	}
	logOnUserCStr = tok;

	// ホスト名
	if (!(tok = strtok_r(NULL, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(host get error,\"%s\")", buff);
		return;
	}
	hostNameCStr = tok;

	// コマンド番号
	if (!(tok = strtok_r(NULL, MESSAGE_SEPARATOR, &ptr))) {
		ERR(@"msg:illegal format(command get error,\"%s\")", buff);
		return;
	}
	command = (UInt32)strtoul(tok, NULL, 10);

	BOOL useUTF8 = (BOOL)((command & IPMSG_UTF8OPT) != 0);
	logOnUser	= [NSString stringWithCString:logOnUserCStr utf8Encoded:useUTF8];
	hostName	= [NSString stringWithCString:hostNameCStr utf8Encoded:useUTF8];
	if (ptr) {
		appendix = [NSString stringWithCString:ptr utf8Encoded:useUTF8];
	}
	TRC(@"\tlogOnUser     =%@", logOnUser);
	TRC(@"\thostName      =%@", hostName);
	TRC(@"\tcommand       =0x%08X", command);
	TRC(@"\tappendix      =%@", appendix);

	// ユーザ特定
	UserInfo* user = [UserManager.sharedManager userForLogOnUser:logOnUser
														 address:&fromAddr];
	if (!user) {
		ERR(@"User not found(%@/%s:%d)", logOnUser, inet_ntoa(fromAddr.sin_addr), ntohs(fromAddr.sin_port));
		return;
	}

	// 要求添付ファイル特定
	NSArray<NSString*>* requestParts = [appendix componentsSeparatedByString:@":"];
	if (requestParts.count < 3) {
		ERR(@"atach request format error(%@)", appendix);
		return;
	}

	// パケット番号
	unsigned attachPacketNo;
	NSScanner* scanner = [NSScanner scannerWithString:requestParts[0]];
	if (![scanner scanHexInt:&attachPacketNo]) {
		ERR(@"packetNo parse error(%@)", requestParts[0]);
		return;
	}

	// ファイルID
	unsigned attachFileID;
	scanner = [NSScanner scannerWithString:requestParts[1]];
	if (![scanner scanHexInt:&attachFileID]) {
		ERR(@"fileID parse error(%@)", requestParts[1]);
		return;
	}

	// オフセット（フォルダの場合は来ない。本当はファイルとフォルダ分けて処理すべき）
	unsigned attachOffset = 0;
	if (GET_MODE(command) == IPMSG_GETFILEDATA) {
		if (requestParts[2].length > 0) {
			scanner = [NSScanner scannerWithString:requestParts[2]];
			if (![scanner scanHexInt:&attachOffset]) {
				ERR(@"offset parse error(%@)", requestParts[2]);
				return;
			}
		}
	}

	// 送信添付ファイル情報検索
	SendAttachment*	attach = nil;
	@synchronized (self.attachList) {
		for (SendAttachment* file in self.attachList) {
			if ((file.packetNo == attachPacketNo) && (file.fileID == attachFileID)) {
				attach = file;
				break;
			}
		}
	}
	if (!attach) {
		ERR(@"attach not found.(%d/%d)", attachPacketNo, attachFileID);
		return;
	}

	// 送信（未ダウンロード）ユーザであるかチェック
	if (![attach.remainUsers containsObject:user]) {
		ERR(@"user(%@) not contained.", user);
		return;
	}

	NSFileManager*	fm		= NSFileManager.defaultManager;
	_FileAttrDic*	attrs	= [fm attributesOfItemAtPath:attach.path error:NULL];
	NSString*		type	= attrs[NSFileType];

	// ファイル送信
	switch (GET_MODE(command)) {
	case IPMSG_GETFILEDATA:	// 通常ファイル
		if (![type isEqualToString:NSFileTypeRegular]) {
			ERR(@"type is not file(%@)", attach.path);
			break;
		}
		if ([self sendFileData:attach.path to:sock]) {
			[self removeAttachmentUser:user
							  packetNo:attachPacketNo
								fileID:attachFileID];
			DBG(@"File Request processing complete.");
		} else {
			ERR(@"sendFile error(%@)", attach.path);
		}
		break;
	case IPMSG_GETDIRFILES:	// ディレクトリ
		if (![type isEqualToString:NSFileTypeDirectory]) {
			ERR(@"type is not directory(%@)", attach.path);
			break;
		}
		if ([self sendDirectory:attach.path attrs:attrs to:sock useUTF8:useUTF8]) {
			[self removeAttachmentUser:user
							  packetNo:attachPacketNo
								fileID:attachFileID];
			DBG(@"Dir Request processing complete.");
		} else {
			ERR(@"sendDir error(%@)", attach.path);
		}
		break;
	default:	// その他
		ERR(@"invalid command([0x%08lX],%@)", GET_MODE(command), attach.path);
		break;
	}

}

// ディレクトリ送信
- (BOOL)sendDirectory:(NSString*)path attrs:(_FileAttrDic*)attrs to:(int)sock useUTF8:(BOOL)utf8
{
	TRC(@"start dir(%@)", path);

	NSFileManager* fm = NSFileManager.defaultManager;
	if (!attrs) {
		attrs = [fm attributesOfItemAtPath:path error:nil];
	}

	// ヘッダ送信
	if (![self sendFileHeader:path attrs:attrs to:sock useUTF8:utf8]) {
		ERR(@"header send error(%@)", path);
		return NO;
	}

	// ディレクトリ直下ファイル送信ループ
	NSArray<NSString*>* files = [fm contentsOfDirectoryAtPath:path error:NULL];
	for (NSString* file in files) {
		NSString* child = [path stringByAppendingPathComponent:file];

		NSDictionary*	childAttrs	= [fm attributesOfItemAtPath:child error:NULL];
		NSString*		type	= childAttrs[NSFileType];
		// 子ファイル
		if ([type isEqualToString:NSFileTypeRegular]) {
			// ヘッダ送信
			if (![self sendFileHeader:child attrs:childAttrs to:sock useUTF8:utf8]) {
				ERR(@"header send error(%@)", child);
				return NO;
			}
			// ファイルデータ送信
			if (![self sendFileData:child to:sock]) {
				ERR(@"file send error(%@)", child);
				return NO;
			}
		}
		// 子ディレクトリ
		else if ([type isEqualToString:NSFileTypeDirectory]) {
			// ディレクトリ送信（再帰呼び出し）
			if (![self sendDirectory:child attrs:childAttrs to:sock useUTF8:utf8]) {
				ERR(@"subdir send error(%@)", child);
				return NO;
			}
		}
		// 非サポート
		else {
			ERR(@"unsupported file type(%@,%@)", type, child);
			continue;
		}
	}

	// 親ディレクトリ復帰ヘッダ送信
	const char* dat = "000B:.:0:3:";	// IPMSG_FILE_RETPARENT = 0x3
	if (send(sock, dat, strlen(dat), 0) < 0) {
		ERR(@"to parent header send error(%s,%@)", dat, path);
		return NO;
	}

	TRC(@"complete dir(%@)", path);

	return YES;
}

// ファイル階層ヘッダ送信処理
- (BOOL)sendFileHeader:(NSString*)path attrs:(_FileAttrDic*)attrs to:(int)sock useUTF8:(BOOL)utf8
{
	if (!attrs) {
		NSFileManager* fm = NSFileManager.defaultManager;
		attrs = [fm attributesOfItemAtPath:path error:nil];
	}

	NSString*	nameOrg		= path.lastPathComponent.precomposedStringWithCanonicalMapping;
	NSString*	fileName	= [nameOrg stringByReplacingOccurrencesOfString:@":" withString:@"::"];
	size_t		fileSize	= [self fileSizeForAttrs:attrs];
	unsigned	fileAttr	= [self makeFileAttributeForPath:path attrs:attrs];
	NSString*	extAttr		= [self makeFileExtendAttributeForAttrs:attrs];

	// ヘッダ編集
	NSString*	dh1	= [NSString stringWithFormat:@"%@:%zX:%X:%@:", fileName, fileSize, fileAttr, extAttr];
	NSData*		wk	= [dh1 dataUsingUTF8:utf8 nullTerminate:NO];
	NSString*	dh2	= [NSString stringWithFormat:@"%04lX:%@", wk.length + 5, dh1];
	NSData*		dat	= [dh2 dataUsingUTF8:utf8 nullTerminate:NO];

	// ファイルヘッダ送信
	if (send(sock, dat.bytes, dat.length, 0) < 0) {
		ERR(@"header send error(%@)", dh2);
		return NO;
	}

	return YES;
}

// ファイルデータ送信処理
- (BOOL)sendFileData:(NSString*)path to:(int)sock
{
	// ファイルオープン
	NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	if (!fileHandle) {
		ERR(@"sendFileData:Open Error(%@)", path);
		return NO;
	}

	size_t totalSize = 0;
	// 送信単位サイズ（将来ユーザ調整可能に？)
	size_t size = 8192;

	// 送信ループ
	while (YES) {
		// ファイル読み込み
		NSData*	data = [fileHandle readDataOfLength:size];
		if (!data) {
			ERR(@"sendFileData:Read Error(data is nil,path=%@)", path);
			[fileHandle closeFile];
			return NO;
		}
		// 送信完了チェック
		if (data.length == 0) {
			TRC(@"SendFileComplete1(%@,size=%zu)", path, totalSize);
			break;
		}
		// データ送信
		if (send(sock, data.bytes, data.length, 0) < 0) {
			ERR(@"sendFileData:Send Error(path=%@)", path);
			[fileHandle closeFile];
			return NO;
		}
		totalSize += data.length;
		if (data.length != size) {
			// 送信完了
			TRC(@"SendFileComplete2(%@,size=%zu)", path, totalSize);
			break;
		}
	}

	[fileHandle closeFile];

	return YES;
}

- (size_t)fileSizeForAttrs:(_FileAttrDic*)attrs
{
	size_t size = 0;
	NSString* type = attrs[NSFileType];
	if ([type isEqualToString:NSFileTypeRegular]) {
		NSNumber* fileSize = attrs[NSFileSize];
		size = (size_t)fileSize.unsignedLongLongValue;
	}
	return size;
}

// ファイル属性編集
- (UInt32)makeFileAttributeForPath:(NSString*)path attrs:(_FileAttrDic*)attrs
{
	UInt32 fileAttr = 0;

	// ファイル種別
	NSString* type = attrs[NSFileType];
	if ([type isEqualToString:NSFileTypeRegular]) {
		fileAttr = IPMSG_FILE_REGULAR;
	} else if ([type isEqualToString:NSFileTypeDirectory]) {
		fileAttr = IPMSG_FILE_DIR;
	} else {
		WRN(@"filetype unsupported(%@ is %@)", path, type);
		return 0;
	}

	// 拡張子非表示
	if ([attrs[NSFileExtensionHidden] boolValue]) {
		fileAttr |= IPMSG_FILE_EXHIDDENOPT;
	}

	// 読み取り専用
	if ([attrs[NSFileImmutable] boolValue]) {
		fileAttr |= IPMSG_FILE_RONLYOPT;
	}

	// 非表示ファイル
	id value;
	NSURL* fileURL = [NSURL fileURLWithPath:path];
	if ([fileURL getResourceValue:&value forKey:NSURLIsHiddenKey error:nil]) {
		if ([value boolValue]) {
			// 非表示ファイル
			fileAttr |= IPMSG_FILE_HIDDENOPT;
		}
	}

	return fileAttr;
}

// 拡張ファイル属性編集
- (NSString*)makeFileExtendAttributeForAttrs:(_FileAttrDic*)attrs
{
	NSMutableArray<NSString*>* array = [NSMutableArray<NSString*> array];

	// 作成日時
	NSDate* ctime = attrs[NSFileCreationDate];
	if (ctime) {
		UInt64 val = (UInt64)ctime.timeIntervalSince1970;
		[array addObject:[NSString stringWithFormat:@"%lX=%llX", IPMSG_FILE_CREATETIME, val]];
	}

	// 更新日時
	NSDate* mtime = attrs[NSFileModificationDate];
	if (mtime) {
		UInt64 val = (UInt64)mtime.timeIntervalSince1970;
		[array addObject:[NSString stringWithFormat:@"%lX=%llX", IPMSG_FILE_MTIME, val]];
	}

	// アクセス権
	NSNumber* permission = attrs[NSFilePosixPermissions];
	if (permission) {
		UInt16 val = permission.unsignedShortValue;
		[array addObject:[NSString stringWithFormat:@"%lX=%X", IPMSG_FILE_PERM, val]];
	}

	// ファイルタイプ(HFS)
	NSNumber* hfsFileType = attrs[NSFileHFSTypeCode];
	if (hfsFileType) {
		UInt32 val = hfsFileType.unsignedIntValue;
		[array addObject:[NSString stringWithFormat:@"%lX=%X", IPMSG_FILE_FILETYPE, val]];
	}

	// クリエータ(HFS)
	NSNumber* hfsCreator = attrs[NSFileHFSCreatorCode];
	if (hfsCreator) {
		UInt32 val = hfsCreator.unsignedIntValue;
		[array addObject:[NSString stringWithFormat:@"%lX=%X", IPMSG_FILE_CREATOR, val]];
	}

	if (array.count > 0) {
		return [array componentsJoinedByString:@":"];
	}
	return @"";
}

/*----------------------------------------------------------------------------*/
#pragma mark - 添付ファイルダウンロード処理（内部利用）
/*----------------------------------------------------------------------------*/

// 添付ダウンロードスレッド
- (void)downloadThread:(AttachDLContextImpl*)dl
{
	@autoreleasepool {
		[dl autorelease];
		
		DownloaderResult	result	= DL_SUCCESS;

		DBG(@"start download thread.");

		// ステータス管理開始
		dl.totalCount		= dl.attachments.count;
		dl.downloadedFiles	= 0;
		dl.downloadedDirs	= 0;
		dl.currentFileName	= nil;
		dl.totalSize		= 0;
		dl.downloadedSize	= 0;
		for (RecvAttachment* attach in dl.attachments) {
			dl.totalSize += attach.size;
		}
		[dl.delegate downloadWillStart];
		// 添付毎ダウンロードループ
		for (dl.downloadedCount = 0; ((dl.downloadedCount < dl.attachments.count) && !dl.stop); dl.downloadedCount++) {
			RecvAttachment* attach = dl.attachments[dl.downloadedCount];
			if (!attach) {
				ERR(@"internal error(attach is nil,index=%ld)", dl.downloadedCount);
				result = DL_INTERNAL_ERROR;
				break;
			}

			[dl.delegate downloadIndexOfTargetChanged];

			// ソケット準備
			if (dl.tcpSocket != -1) {
				close(dl.tcpSocket);
			}
			dl.tcpSocket = socket(AF_INET, SOCK_STREAM, 0);
			if (dl.tcpSocket == -1) {
				ERR(@"socket open error");
				result = DL_SOCKET_ERROR;
				break;
			}

			// 接続
			struct sockaddr_in addr;
			memset(&addr, 0, sizeof(addr));
			addr.sin_family			= AF_INET;
			addr.sin_port			= htons(self.portNo);
			addr.sin_addr.s_addr	= dl.fromUser.address.sin_addr.s_addr;
			if (connect(dl.tcpSocket, (struct sockaddr*)&addr, sizeof(addr)) != 0) {
				ERR(@"connect error");
				close(dl.tcpSocket);
				dl.tcpSocket = -1;
				result = DL_CONNECT_ERROR;
				break;
			}
			/*
			 if (fcntl(sock, F_SETFL, O_NONBLOCK) == -1) {
			 ERR(@"socket option set error(errorno=%d)", errno);
			 result = DL_SOCKET_ERROR;
			 break;
			 }
			 */

			// リクエスト送信
			UInt32	command = IPMSG_GETFILEDATA;
			if (attach.type == ATTACH_TYPE_DIRECTORY) {
				command = IPMSG_GETDIRFILES;
			}
			if (dl.fromUser.supportsUTF8) {
				command |= IPMSG_UTF8OPT;
			}
			NSString* str = [NSString stringWithFormat:@"%d:%ld:%@:%@:%d:%lx:%lx:%x:",
															IPMSG_VERSION,
															MessageCenter.nextPacketNo,
															self.selfLogOnName,
															AppControlGetHostName(),
															command,
															dl.packetNo,
															attach.fileID,
															0U];
			NSData* data = [str dataUsingUTF8:NO nullTerminate:YES];
			// リクエスト送信
			if (send(dl.tcpSocket, data.bytes, data.length, 0) < 0) {
				ERR(@"file:attach request send error.(%@)", str);
				close(dl.tcpSocket);
				dl.tcpSocket = -1;
				result = DL_COMMUNICATION_ERROR;
				break;
			}
			//	DBG(@"send file/dir request=%s", buf);

			switch (attach.type) {
			case ATTACH_TYPE_REGULAR_FILE:
				result = [self download:dl file:attach];
				if (result != DL_SUCCESS) {
					ERR(@"download file error.(%@)", attach.name);
					close(dl.tcpSocket);
					dl.tcpSocket = -1;
					break;
				}
				((RecvFile*)attach).downloaded = YES;
				dl.downloadedFiles++;
				[dl.delegate downloadNumberOfFileChanged];
				break;
			case ATTACH_TYPE_DIRECTORY:
				result = [self download:dl dir:attach];
				if (result != DL_SUCCESS) {
					ERR(@"download dir error.(%@)", attach.name);
					close(dl.tcpSocket);
					dl.tcpSocket = -1;
					break;
				}
				((RecvFile*)attach).downloaded = YES;
				dl.downloadedDirs++;
				[dl.delegate downloadNumberOfDirectoryChanged];
				break;
			case ATTACH_TYPE_CLIPBOARD:
				result = [self download:dl file:attach];
				if (result != DL_SUCCESS) {
					ERR(@"download clipboard error.(%@)", attach.name);
					close(dl.tcpSocket);
					dl.tcpSocket = -1;
					break;
				}
				dl.downloadedFiles++;
				[dl.delegate downloadNumberOfFileChanged];
				break;
			default:
				ERR(@"unsupported file type(%ld,%@)", attach.type, attach.name);
				break;
			}

			// ソケットクローズ
			close(dl.tcpSocket);
			dl.tcpSocket = -1;
		}
		if (dl.stop) {
			result = DL_STOP;
		}
		[dl.delegate downloadDidFinished:result];
		DBG(@"stop download thread.");
	}
}


/*----------------------------------------------------------------------------*
 * ファイルダウンロード処理
 *----------------------------------------------------------------------------*/
- (DownloaderResult)download:(AttachDLContextImpl*)dl file:(RecvAttachment*)attach
{
	char				buf[8192];	// バッファサイズを変更可能に？
	unsigned long long	remain;
	size_t				size;
	DownloaderResult	ret;
	RecvFile*			file = nil;
	if ([attach isKindOfClass:RecvFile.class]) {
		file = (RecvFile*)attach;
	}

	dl.currentFileName = attach.name;
	[dl.delegate downloadFileChanged];

	if (file) {
		// 保存先ディレクトリ指定
		file.path = [dl.savePath stringByAppendingPathComponent:file.name];
	}
	DBG(@"file:start download file(%@)", attach.name);

	/*------------------------------------------------------------------------*
	 * データ受信
	 *------------------------------------------------------------------------*/

	// ファイルオープン／作成
	if (![attach openHandle]) {
		ERR(@"file:open/create file error(%@)", attach.name);
		return DL_FILE_OPEN_ERROR;
	}
	// ファイル受信
	remain = attach.size;
	while (remain > 0) {
		size = MIN(sizeof(buf), remain);
		ret = [self download:dl toBuffer:buf maxLength:size];
		if (ret != DL_SUCCESS) {
			WRN(@"file:file receive error(%ld,%@)", ret, attach.name);
			// ファイルクローズ
			[attach closeHandle];
			if (file) {
				// 書きかけのファイルを削除
				[[NSFileManager defaultManager] removeItemAtPath:file.path error:NULL];
			}
			return ret;
		}
		dl.downloadedSize += size;
		[dl.delegate downloadDownloadedSizeChanged];
		remain -= size;						// 残りサイズ更新
		[attach writeData:buf length:size];	// ファイル書き込み
	}

	// ファイルクローズ
	[attach closeHandle];

	return DL_SUCCESS;
}

/*----------------------------------------------------------------------------*
 * ディレクトリダウンロード処理
 *----------------------------------------------------------------------------*/
- (DownloaderResult)download:(AttachDLContextImpl*)dl dir:(RecvAttachment*)dir
{
	char				buf[8192];		// バッファサイズを変更可能に？
	long				headerSize;
	NSString*			currentDir	= dl.savePath;
	DownloaderResult	result		= DL_SUCCESS;
	RecvAttachment*		attach;
	RecvFile*			file;
	size_t				remain;
	DBG(@"dir:start download directory(%@)", [dir name]);

	/*------------------------------------------------------------------------*
	 * 各ファイル受信ループ
	 *------------------------------------------------------------------------*/
	while (!dl.stop) {
		// ヘッダサイズ受信
		result = [self download:dl toBuffer:buf maxLength:5];
		if (result != DL_SUCCESS) {
			ERR(@"dir:headerSize receive error(ret=%ld)", (long)result);
			break;
		}
		buf[4] = '\0';
		headerSize = strtol(buf, NULL, 16);
		if (headerSize == 0) {
			DBG(@"dir:download complete1(%@)", dl.savePath);
			break;
		} else if (headerSize < 0) {
			ERR(@"dir:download internal error(headerSize=%ld,buf=%s)", headerSize, buf);
			result = DL_INVALID_DATA;
			break;
		} else if (headerSize >= sizeof(buf)) {
			ERR(@"dir:headerSize overflow(%ld,max=%lu)", headerSize, sizeof(buf));
			result = DL_INTERNAL_ERROR;
			break;
		}
		headerSize -= 5;	// 先頭のヘッダ長サイズ（"0000:"）分減らす
		if (headerSize == 0) {
			WRN(@"dir:headerSize is 0. why?");
			continue;
		}

		// ヘッダ受信
		result = [self download:dl toBuffer:buf maxLength:headerSize];
		if (result != DL_SUCCESS) {
			ERR(@"dir:header receive error(ret=%ld,size=%ld)", (long)result, headerSize);
			break;
		}
		buf[headerSize] = '\0';
		NSString* header = [NSString stringWithCString:buf utf8Encoded:dl.fromUser.supportsUTF8];
		//		DBG(@"dir:recv Header=%s", buf);
		attach = [self parseAttachmentBuffer:header needReadModTime:NO];
		if (!attach) {
			ERR(@"dir:parse dir header error(%s)", buf);
			result = DL_INVALID_DATA;
			break;
		}
		if (![attach isKindOfClass:RecvFile.class]) {
			ERR(@"dir:parse dir header error(%s)", buf);
			result = DL_INVALID_DATA;
			break;
		}
		file = (RecvFile*)attach;
		switch (file.type) {
		case ATTACH_TYPE_RET_PARENT:
			file.path = [currentDir stringByDeletingLastPathComponent];
			break;
		default:
			file.path = [currentDir stringByAppendingPathComponent:file.name];
			break;
		}

		// ファイルオープン／作成
		if (![file openHandle]) {
			ERR(@"dir:open/create file error(%@)", file.path);
			result = DL_FILE_OPEN_ERROR;
			break;
		}
		// ディレクトリ移動
		switch (file.type) {
		case ATTACH_TYPE_REGULAR_FILE:
			dl.currentFileName = file.name;
			[dl.delegate downloadFileChanged];
			break;
		case ATTACH_TYPE_DIRECTORY:
			dl.currentFileName = file.name;
			[dl.delegate downloadFileChanged];
			currentDir = file.path;
			DBG(@"dir:chdir to child (-> \"%@\")", [currentDir substringFromIndex:dl.savePath.length + 1]);
			break;
		case ATTACH_TYPE_RET_PARENT:
			currentDir = file.path;
			DBG(@"dir:chdir to parent(<- \"%@\")",
				([currentDir length] > [dl.savePath length]) ? [currentDir substringFromIndex:dl.savePath.length + 1] : @"");
			break;
		default:
			ERR(@"Attachment type error(%ld,internal error)", file.type);
			result = DL_INTERNAL_ERROR;
			break;
		}
		// ファイル受信
		remain = file.size;
		if (remain > 0) {
			dl.totalSize += remain;
			[dl.delegate downloadTotalSizeChanged];
			while (remain > 0) {
				size_t size = MIN(sizeof(buf), remain);
				result = [self download:dl toBuffer:buf maxLength:size];
				if (result != DL_SUCCESS) {
					ERR(@"dir:file receive error(%ld,remain=%lu)", (long)result, remain);
					break;
				}
				dl.downloadedSize += size;
				[dl.delegate downloadDownloadedSizeChanged];
				remain -= size;						// 残りサイズ更新
				[file writeData:buf length:size];	// ファイル書き込み
			}
		}
		// ファイルクローズ
		[file closeHandle];

		if (result != DL_SUCCESS) {
			// エラー発生
			break;
		}
		if (remain > 0) {
			// 受信しきれていない（エラー）
			ERR(@"dir:file remain data exist(%ld)", remain);
			result = DL_SIZE_NOT_ENOUGH;
			break;
		}

		switch (file.type) {
		case ATTACH_TYPE_REGULAR_FILE:
			dl.downloadedFiles++;
			[dl.delegate downloadNumberOfFileChanged];
			break;
		case ATTACH_TYPE_RET_PARENT:
			dl.downloadedDirs++;
			[dl.delegate downloadNumberOfDirectoryChanged];
			break;
		default:
			//NOP
			break;
		}

		// 終了判定
		if ([currentDir isEqualToString:dl.savePath]) {
			DBG(@"dir:download complete2(%@)", dl.savePath);
			break;
		}
	}

	// エラー判定
	if (dl.stop) {
		// 停止された場合
		result = DL_STOP;
	}
	/* 大量のダウンロード済みファイルを削除するとかなり重くなるので、やめておく
	 if ((result != DL_SUCCESS) && (result != DL_STOP)) {
	 // エラーの場合削除（ユーザの停止は除く）
	 NSString* dir = [savePath stringByAppendingPathComponent:[file name]];
	 DBG(@"dir:rmdir because of stop or error.(%@)", dir);
	 [[NSFileManager defaultManager] removeFileAtPath:dir handler:nil];
	 }
	 */

	return result;
}

// ソケット受信
- (DownloaderResult)download:(AttachDLContextImpl*)dl toBuffer:(void*)ptr maxLength:(size_t)len
{
	int		timeout		= 0;
	size_t	recvSize	= 0;
	for (timeout = 0; (timeout < 40); timeout++) {
		if (dl.stop) {
			WRN(@"user cancel(stop)");
			return DL_STOP;
		}
		fd_set fdSet;
		FD_ZERO(&fdSet);
		FD_SET(dl.tcpSocket, &fdSet);
		struct timeval	tv;
		tv.tv_sec	= 0;
		tv.tv_usec	= 500000;
		// ソケット監視
		int ret = select(dl.tcpSocket + 1, &fdSet, NULL, NULL, &tv);
		if (ret == 0) {
			// 受信なし
			DBG(@"timeout(sock=%d,count=%d)", dl.tcpSocket, timeout);
			continue;
		}
		if (ret < 0) {
			// 受信エラー
			ERR(@"socket error(select).");
			return DL_SOCKET_ERROR;
		}
		// 正常受信
		timeout = -1;
		ssize_t size = recv(dl.tcpSocket, &(((char*)ptr)[recvSize]), len - recvSize, 0);
		if (size < 0) {
			ERR(@"socket error(recv=%ld,maybe disconnected.)", size);
			return DL_DISCONNECTED;
		}
		recvSize += size;
		if (recvSize < len) {
			continue;
		}
		return DL_SUCCESS;
	}

	WRN(@"receive timeout(%dsec,sock=%d)", timeout/2, dl.tcpSocket);

	return DL_TIMEOUT;
}

// 受信バッファ解析初期化共通処理
- (RecvAttachment*)parseAttachmentBuffer:(NSString*)buf needReadModTime:(BOOL)flag
{
	// ファイル名
	NSString* fileName = nil;
	@try {
		NSRange	range = [buf rangeOfString:@":"];
		if (range.location == NSNotFound) {
			ERR(@"file name error(%@)", buf);
			return nil;
		}
		while ([buf characterAtIndex:range.location + 1] == ':') {
			NSRange work = range;
			work.location += 2;
			work.length = buf.length - work.location;
			range = [buf rangeOfString:@":" options:0 range:work];
		}
		// ファイル名部分を切り出す
		NSString* nameEscaped = [[buf substringToIndex:range.location] retain];
		// ファイル名の"::"エスケープを"_"にする（:はファイルパスに使えないので）
		NSString* name = [nameEscaped stringByReplacingOccurrencesOfString:@"::" withString:@"_"];
		// ファイル名の"/"を"_"にする（HFS+ならば"/"は使えるが、HFS+以外の場合や混乱を回避するため）
		fileName = [name stringByReplacingOccurrencesOfString:@"/" withString:@"_"];

		// 解析対象文字列をファイル名の後からにする
		buf	= [buf substringFromIndex:range.location + 1];
		TRC(@"fileName:%@(escaped:%@)", fileName, nameEscaped);
	}
	@catch (NSException* exception) {
		ERR(@"file name error(%@,exp=%@)", buf, exception);
		return nil;
	}

	NSArray<NSString*>*	strs	= [buf componentsSeparatedByString:@":"];
	NSInteger			index	= 0;
	NSScanner*			scanner;
	UInt64				val;

	// ファイルサイズ
	scanner	= [NSScanner scannerWithString:strs[index]];
	if (![scanner scanHexLongLong:&val]) {
		ERR(@"file size error(%@)", strs[index]);
		return nil;
	}
	size_t fileSize = (size_t)val;
	index++;
	TRC(@"fileSize:%zd", fileSize);

	// 更新時刻（MessageAttachmentのみ）
	NSDate* modDate = nil;
	if (flag) {
		scanner = [NSScanner scannerWithString:strs[index]];
		if (![scanner scanHexLongLong:&val]) {
			ERR(@"modDate attr error(%@)", strs[index]);
			return nil;
		}
		modDate = [NSDate dateWithTimeIntervalSince1970:val];
		index++;
		TRC(@"modTime:%@", modDate);
	}

	// ファイル属性
	scanner = [NSScanner scannerWithString:strs[index]];
	if (![scanner scanHexLongLong:&val]) {
		ERR(@"file attr error(%@)", strs[index]);
		return nil;
	}
	UInt32 attribute = (UInt32)val;
	index++;
	TRC(@"attr:0x%08X", attribute);

	RecvAttachment* attach = nil;
	switch (GET_MODE(attribute)) {
	case IPMSG_FILE_REGULAR:
		attach = [[[RecvFile alloc] init] autorelease];
		attach.type = ATTACH_TYPE_REGULAR_FILE;
		break;
	case IPMSG_FILE_DIR:
		attach = [[[RecvFile alloc] init] autorelease];
		attach.type = ATTACH_TYPE_DIRECTORY;
		break;
	case IPMSG_FILE_RETPARENT:
		attach = [[[RecvFile alloc] init] autorelease];
		attach.type = ATTACH_TYPE_RET_PARENT;
		break;
	case IPMSG_FILE_CLIPBOARD:
		attach = [[[RecvClipboard alloc] init] autorelease];
		attach.type = ATTACH_TYPE_CLIPBOARD;
		break;
	default:
		ERR(@"unknown attachment type(%ld,%@)", GET_MODE(attribute), fileName);
		return nil;
	}
	attach.name				= fileName;
	attach.size				= fileSize;
	attach.modifyTime		= modDate;
	attach.readonly			= ((attribute & IPMSG_FILE_RONLYOPT) != 0);
	attach.hidden			= ((attribute & IPMSG_FILE_HIDDENOPT) != 0);
	attach.extensionHidden	= ((attribute & IPMSG_FILE_EXHIDDENOPT) != 0);

	// 拡張ファイル属性
	while (index < strs.count) {
		[self readExtendAttribute:strs[index] to:attach];
		index++;
	}

	return attach;
}

// 拡張ファイル属性解析
- (void)readExtendAttribute:(NSString*)str to:(RecvAttachment*)attach
{
	UInt				key;
	UInt				val;
	NSScanner*			scanner;
	NSArray<NSString*>*	kv	= [str componentsSeparatedByString:@"="];

	TRC(@"extAttr:string='%@'", str);
	if (str.length <= 0) {
		TRC(@"extAttr:skip empty");
		return;
	}

	if (kv.count != 2) {
		ERR(@"extend attribute invalid(%@)", str);
		return;
	}

	scanner	= [NSScanner scannerWithString:kv[0]];
	if (![scanner scanHexInt:&key]) {
		ERR(@"extend attribute invalid(%@)", str);
		return;
	}
	scanner	= [NSScanner scannerWithString:kv[1]];
	if (![scanner scanHexInt:&val]) {
		ERR(@"extend attribute invalid(%@)", str);
		return;
	}

	switch (key) {
	case IPMSG_FILE_UID:
		WRN(@"extAttr:UID          unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_USERNAME:
		WRN(@"extAttr:USERNAME     unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_GID:
		WRN(@"extAttr:GID          unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_GROUPNAME:
		WRN(@"extAttr:GROUPNAME    unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_CLIPBOARDPOS:
		if ([attach isKindOfClass:RecvClipboard.class]) {
			RecvClipboard* clip = (RecvClipboard*)attach;
			clip.clipboardPos = val;
			TRC(@"extAttr:CLIPBOARDPOS = %d[0x%X]", val, val);
		} else {
			WRN(@"extAttr:CLIPBOARDPOS unsupported(%d[0x%X])", val, val);
		}
		break;
	case IPMSG_FILE_PERM:
		attach.permission = val;
		TRC(@"extAttr:PERM         = 0%03o", attach.permission);
		break;
	case IPMSG_FILE_MAJORNO:
		WRN(@"extAttr:MAJORNO      unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_MINORNO:
		WRN(@"extAttr:MINORNO      unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_CTIME:
		WRN(@"extAttr:CTIME        unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_MTIME:
		attach.modifyTime = [NSDate dateWithTimeIntervalSince1970:val];
		TRC(@"extAttr:MTIME        = %d(%@)", val, attach.modifyTime);
		break;
	case IPMSG_FILE_ATIME:
		WRN(@"extAttr:ATIME        unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_CREATETIME:
		attach.createTime = [NSDate dateWithTimeIntervalSince1970:val];
		TRC(@"extAttr:CREATETIME   = %d(%@)", val, attach.createTime);
		break;
	case IPMSG_FILE_CREATOR:
		attach.hfsCreator = val;
		TRC(@"extAttr:CREATOR      = 0x%08X('%c%c%c%c')", attach.hfsCreator,
			((char*)&val)[0], ((char*)&val)[1],
			((char*)&val)[2], ((char*)&val)[3]);
		break;
	case IPMSG_FILE_FILETYPE:
		attach.hfsFileType = val;
		TRC(@"extAttr:FILETYPE     = 0x%08X('%c%c%c%c')", attach.hfsFileType,
			((char*)&val)[0], ((char*)&val)[1],
			((char*)&val)[2], ((char*)&val)[3]);
		break;
	case IPMSG_FILE_FINDERINFO:
		WRN(@"extAttr:FINDERINFO   unsupported(0x%04X['%c%c'])", val,
			((char*)&val)[0], ((char*)&val)[1]);
		break;
	case IPMSG_FILE_ACL:
		WRN(@"extAttr:ACL          unsupported(%d[0x%X])", val, val);
		break;
	case IPMSG_FILE_ALIASFNAME:
		WRN(@"extAttr:ALIASFNAME   unsupported(%d[0x%X])", val, val);
		break;
	default:
		WRN(@"extAttr:unknownType(key=0x%08X,val=%d[0x%X])", key, val, val);
		break;
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - 暗号化関連処理（内部利用）
/*----------------------------------------------------------------------------*/

- (UInt32)encodeCryptoCapability:(CryptoCapability*)cap
{
	NSParameterAssert(cap);

	UInt32	cmd	= 0;
	if (cap.supportBlowfish128) {
		cmd |= IPMSG_BLOWFISH_128;
	}
	if (cap.supportAES256) {
		cmd |= IPMSG_AES_256;
	}
	if (cap.supportRSA1024) {
		cmd |= IPMSG_RSA_1024;
	}
	if (cap.supportRSA2048) {
		cmd |= IPMSG_RSA_2048;
	}
	if (cap.supportPacketNoIV) {
		cmd |= IPMSG_PACKETNO_IV;
	}
	if (cap.supportEncodeBase64) {
		cmd |= IPMSG_ENCODE_BASE64;
	}
	if (cap.supportSignSHA1) {
		cmd |= IPMSG_SIGN_SHA1;
	}
	if (cap.supportSignSHA256) {
		cmd |= IPMSG_SIGN_SHA256;
	}
	return cmd;
}

- (BOOL)parseAnsPubkey:(NSString*)appendix from:(UserInfo*)fromUser
{
	NSArray<NSString*>*	strs;
	NSScanner*			scanner;
	unsigned int		val;

	// ":"までが暗号化能力情報
	strs = [appendix componentsSeparatedByString:@":"];
	if (strs.count != 2) {
		ERR(@"ANSPUBKEY appendix format error(%@)", appendix);
		return NO;
	}
	scanner = [NSScanner scannerWithString:strs[0]];
	if (![scanner scanHexInt:&val]) {
		ERR(@"security spec parse error(%@)", strs[0]);
		return NO;
	}
	CryptoCapability* cap = [[[CryptoCapability alloc] init] autorelease];
	cap.supportBlowfish128	= ((val & IPMSG_BLOWFISH_128) != 0);
	cap.supportAES256		= ((val & IPMSG_AES_256) != 0);
	cap.supportRSA1024		= ((val & IPMSG_RSA_1024) != 0);
	cap.supportRSA2048		= ((val & IPMSG_RSA_2048) != 0);
	cap.supportPacketNoIV	= ((val & IPMSG_PACKETNO_IV) != 0);
	cap.supportEncodeBase64	= ((val & IPMSG_ENCODE_BASE64) != 0);
	cap.supportSignSHA1		= ((val & IPMSG_SIGN_SHA1) != 0);
	cap.supportSignSHA256	= ((val & IPMSG_SIGN_SHA256) != 0);
	_MSG_DBG(@" Encryption =%s", BOOLSTR(cap.supportEncryption));
	_MSG_DBG(@" FingerPrint=%s", BOOLSTR(cap.supportFingerPrint));
	_MSG_DBG(@" Blowfish128=%s", BOOLSTR(cap.supportBlowfish128));
	_MSG_DBG(@" AES256     =%s", BOOLSTR(cap.supportAES256));
	_MSG_DBG(@" RSA1024    =%s", BOOLSTR(cap.supportRSA1024));
	_MSG_DBG(@" RSA2048    =%s", BOOLSTR(cap.supportRSA2048));
	_MSG_DBG(@" PacketNoIV =%s", BOOLSTR(cap.supportPacketNoIV));
	_MSG_DBG(@" EncBase64  =%s", BOOLSTR(cap.supportEncodeBase64));
	_MSG_DBG(@" SignSHA1   =%s", BOOLSTR(cap.supportSignSHA1));
	_MSG_DBG(@" SignSHA256 =%s", BOOLSTR(cap.supportSignSHA256));

	// 続いて公開鍵「EE-NNNNN」
	strs = [strs[1] componentsSeparatedByString:@"-"];
	if (strs.count != 2) {
		ERR(@"ANSPUBKEY PublicKey format error(%@)", strs);
		return NO;
	}
	scanner = [NSScanner scannerWithString:strs[0]];
	if (![scanner scanHexInt:&val]) {
		ERR(@"ANSPUBKEY PublicKey exponent parse error(%@)", strs[0]);
		return NO;
	}

	NSData* mod = [NSData dataWithHexEncodedString:strs[1]];
	if (!mod) {
		ERR(@"ANSPUBKEY PublicKey modulo parse error(%@)", strs[0]);
		return NO;
	}
	RSAPublicKey* key = [RSAPublicKey keyWithExponent:val modulus:mod];
	if (!key) {
		ERR(@"ANSPUBKEY PublicKey Generate Error(mod=%X,mod=%ldbits:%@)", val, mod.length * 8, mod);
		return NO;
	}
	_MSG_DBG(@"ANSPUBKEY publicKey=%@", key);

	// 指紋検証
	if (fromUser.fingerPrint) {
		if (cap.supportFingerPrint) {
			CryptoManager* cm = CryptoManager.sharedManager;
			NSData* fingerPrint = [cm publicKeyFingerPrintForRSA2048Modulus:key.modulus];
			if ([fromUser.fingerPrint isEqualToData:fingerPrint]) {
				_MSG_DBG(@"FingerPrint Verified(OK)");
			} else {
				// 偽装？
				WRN(@"FingerPrint not matched(user:%@,check=%@) -> Doubt", fromUser.fingerPrint, fingerPrint);
				return NO;
			}
		} else {
			// 公開鍵指紋つきユーザがRSA2048/SHA1に対応していない場合はパケット破棄
			ERR(@"Illegal FingerPrint(%@,RSA2048=%s,SingSHA1=%s) -> Reject", fromUser.fingerPrint,
											BOOLSTR(cap.supportRSA2048), BOOLSTR(cap.supportSignSHA1));
			return NO;
		}
	}

	fromUser.cryptoCapability	= cap;
	fromUser.publicKey			= key;

	return YES;
}

@end
