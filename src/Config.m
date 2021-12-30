/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: Config.m
 *	Module		: 初期設定情報管理クラス
 *============================================================================*/

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import <objc/runtime.h>

// #define IPMSG_LOG_TRC	0

#import "Config.h"
#import "RefuseInfo.h"
#import "DebugLog.h"

/*============================================================================*
 * 定数定義
 *============================================================================*/

// 基本
static NSString* GEN_VERSION			= @"Version";
static NSString* GEN_VERSION_STR		= @"VersionString";
static NSString* GEN_USER_NAME			= @"UserName";
static NSString* GEN_GROUP_NAME			= @"GroupName";
static NSString* GEN_PASSWORD			= @"UserPassword";
static NSString* GEN_RSA1024EXP			= @"RSA1024PublicKeyExponent";
static NSString* GEN_RSA1024MOD			= @"RSA1024PublicKeyModulus";
static NSString* GEN_RSA2048EXP			= @"RSA2048PublicKeyExponent";
static NSString* GEN_RSA2048MOD			= @"RSA2048PublicKeyModulus";
static NSString* GEN_USE_STATUS_BAR		= @"UseStatusBarMenu";

// ネットワーク
static NSString* NET_PORT_NO			= @"PortNo";
static NSString* NET_BROADCAST			= @"Broadcast";
static NSString* NET_DIALUP				= @"Dialup";

// 送信
static NSString* SEND_QUOT_STR			= @"QuotationString";
static NSString* SEND_DOCK_SEND			= @"OpenSendWindowWhenDockClick";
static NSString* SEND_SEAL_CHECK		= @"SealCheckDefaultOn";
static NSString* SEND_HIDE_REPLY		= @"HideRecieveWindowWhenSendReply";
static NSString* SEND_OPENSEAL_CHECK	= @"CheckSealOpened";
static NSString* SEND_MULTI_USER_CHECK	= @"AllowSendingToMutipleUser";
static NSString* SEND_MSG_FONT_NAME		= @"SendMessageFontName";
static NSString* SEND_MSG_FONT_SIZE		= @"SendMessageFontSize";

// 受信
static NSString* RECV_SOUND				= @"ReceiveSound";
static NSString* RECV_QUOT_CHECK		= @"QuotCheckDefaultOn";
static NSString* RECV_NON_POPUP			= @"NonPopupReceive";
static NSString* RECV_ABSENCE_NONPOPUP	= @"NonPopupReceiveWhenAbsenceMode";
static NSString* RECV_BOUND_IN_NONPOPUP	= @"DockIconBoundInNonPopupReceive";
static NSString* RECV_CLICKABLE_URL		= @"UseClickableURL";
static NSString* RECV_MSG_FONT_NAME		= @"ReceiveMessageFontName";
static NSString* RECV_MSG_FONT_SIZE		= @"ReceiveMessageFontSize";

// 不在
static NSString* ABSENCE				= @"Absence";

// 通知拒否
static NSString* REFUSE					= @"RefuseCondition";

// ログ
static NSString* LOG_STD_ON				= @"StandardLogEnabled";
static NSString* LOG_STD_CHAIN			= @"StandardLogWhenLockedMessageOpened";
static NSString* LOG_STD_FILE			= @"StandardLogFile";
static NSString* LOG_ALT_ON				= @"AlternateLogEnabled";
static NSString* LOG_ALT_SELECTION		= @"AlternateLogWithSelectedRange";
static NSString* LOG_ALT_FILE			= @"AlternateLogFile";

// ウィンドウ位置／サイズ／設定
static NSString* RCVWIN_SIZE_W			= @"ReceiveWindowWidth";
static NSString* RCVWIN_SIZE_H			= @"ReceiveWindowHeight";
static NSString* SNDWIN_SIZE_W			= @"SendWindowWidth";
static NSString* SNDWIN_SIZE_H			= @"SendWindowHeight";
static NSString* SNDWIN_SIZE_SPLIT		= @"SendWindowSplitPoint";
static NSString* SNDWIN_USERLIST_COL	= @"SendWindowUserListColumnDisplay";
static NSString* SNDSEARCH_USER			= @"SendWindowSearchByUserName";
static NSString* SNDSEARCH_GROUP		= @"SendWindowSearchByGroupName";
static NSString* SNDSEARCH_HOST			= @"SendWindowSearchByHostName";
static NSString* SNDSEARCH_LOGON		= @"SendWindowSearchByLogOnName";

@interface Config() {
	NSMutableDictionary*	sendUserListColDisp;
	NSFont*					sendWindowMessageFont;
	NSFont*					recvWindowMessageFont;
}

@property(retain)	NSMutableArray<NSString*>*		broadcastHostList;
@property(retain)	NSMutableArray<NSString*>*		broadcastIPList;
@property(retain)	NSFont*							defaultMessageFont;
@property(retain)	NSArray<NSDictionary*>*			defaultAbsences;
@property(retain)	NSMutableArray<NSDictionary*>*	absenceList;
@property(retain)	NSSound*						receiveSound;
@property(retain)	NSMutableArray<RefuseInfo*>*	refuseList;

- (NSMutableArray<RefuseInfo*>*)convertRefuseDefaultsToInfo:(NSArray<NSDictionary*>*)array;
- (NSArray<NSDictionary*>*)convertRefuseInfoToDefaults:(NSArray<RefuseInfo*>*)array;

@end

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation Config

/*----------------------------------------------------------------------------*
 * ファクトリ
 *----------------------------------------------------------------------------*/
#pragma mark -

// 共有インスタンスを返す
+ (Config*)sharedConfig
{
	static Config* sharedConfig = nil;
	static dispatch_once_t	once;
	dispatch_once(&once, ^{
		sharedConfig = [[Config alloc] init];
	});
	return sharedConfig;
}

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/
#pragma mark -

// 初期化
- (id)init
{
	self = [super init];
	if (!self) {
		return nil;
	}

	NSUserDefaults*	defaults = NSUserDefaults.standardUserDefaults;
	NSArray*		array;
	NSMutableArray*	mutableArray;
	NSDictionary*	dic;
	NSString*		str;
	float			fVal;
	NSSize			size;

	DBG(@"======== Init Config start ========");

	// デフォルト値の設定
	NSDictionary* defaultValueDic = @{
		// 全般
		GEN_USER_NAME			: NSFullUserName(),
		GEN_GROUP_NAME			: @"",
		GEN_PASSWORD			: @"",
		GEN_USE_STATUS_BAR		: @NO,
		// ネットワーク
		NET_PORT_NO				: @2425,
		NET_DIALUP				: @NO,
		// 送信
		SEND_QUOT_STR			: @">",
		SEND_DOCK_SEND			: @NO,
		SEND_SEAL_CHECK			: @NO,
		SEND_HIDE_REPLY			: @YES,
		SEND_OPENSEAL_CHECK		: @YES,
		SEND_MULTI_USER_CHECK	: @YES,
		// 受信
		RECV_SOUND				: @"",
		RECV_QUOT_CHECK			: @YES,
		RECV_NON_POPUP			: @NO,
		RECV_BOUND_IN_NONPOPUP	: @(IPMSG_BOUND_ONECE),
		RECV_ABSENCE_NONPOPUP	: @NO,
		RECV_CLICKABLE_URL		: @YES,
		// ログ
		LOG_STD_ON				: @YES,
		LOG_STD_CHAIN			: @YES,
		LOG_STD_FILE			: @"~/Documents/ipmsg_log.txt",
		LOG_ALT_ON				: @YES,
		LOG_ALT_SELECTION		: @NO,
		LOG_ALT_FILE			: @"~/Documents/ipmsg_alt_log.txt",
		// 送信ウィンドウ
		SNDSEARCH_USER			: @YES,
		SNDSEARCH_GROUP			: @YES,
		SNDSEARCH_HOST			: @NO,
		SNDSEARCH_LOGON			: @NO
	};
	[defaults registerDefaults:defaultValueDic];
	#if IPMSG_LOG_TRC
		// デバッグ用ログ出力
		TRC(@"defaultValues[%ld]=(", defaultValueDic.count);
		for (id key in defaultValueDic.keyEnumerator) {
			id val = defaultValueDic[key];
			if ([val isKindOfClass:NSString.class]) {
				TRC(@"\t%@=\"%@\"", key, val);
			} else {
				TRC(@"\t%@=%@", key, val);
			}
		}
		TRC(@")");
	#endif

	// 不在文のデフォルト値
	mutableArray = [NSMutableArray<NSDictionary*> array];
	for (NSInteger i = 0; i < 8; i++) {
		NSString* key1	= [NSString stringWithFormat:@"Pref.Absence.Def%ld.Title", i];
		NSString* key2	= [NSString stringWithFormat:@"Pref.Absence.Def%ld.Message", i];
		[mutableArray addObject:@{
			@"Title"	: NSLocalizedString(key1, nil),
			@"Message"	: NSLocalizedString(key2, nil)
		}];
	}
	_defaultAbsences = [[NSArray<NSDictionary*> alloc] initWithArray:mutableArray];
	#if IPMSG_LOG_TRC
		// デバッグ用ログ出力
		TRC(@"defaultAbsences[%ld]=(", _defaultAbsences.count);
		for (NSDictionary* dic in _defaultAbsences) {
			NSString* t = dic[@"Title"];
			NSString* m = dic[@"Message"];
			NSString* str = [m stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
			TRC(@"\t\"%@\"（\"%@\"）", t, str);
		}
		TRC(@")");
	#endif

	// フォントのデフォルト値
	_defaultMessageFont = [[NSFont systemFontOfSize:[NSFont systemFontSize]] retain];
	TRC(@"defaultMessageFont=%@", _defaultMessageFont);

	// 全般
	_userName					= [[defaults stringForKey:GEN_USER_NAME] copy];
	_groupName					= [[defaults stringForKey:GEN_GROUP_NAME] copy];
	_password					= [[defaults stringForKey:GEN_PASSWORD] copy];
	_rsa1024PublicKeyExponent	= (UInt32)[defaults integerForKey:GEN_RSA1024EXP];
	_rsa1024PublicKeyModulus	= [defaults dataForKey:GEN_RSA1024MOD];
	_rsa2048PublicKeyExponent	= (UInt32)[defaults integerForKey:GEN_RSA2048EXP];
	_rsa2048PublicKeyModulus	= [defaults dataForKey:GEN_RSA2048MOD];
	_useStatusBar				= [defaults boolForKey:GEN_USE_STATUS_BAR];
	// ネットワーク
	_portNo						= [defaults integerForKey:NET_PORT_NO];
	_dialup						= [defaults boolForKey:NET_DIALUP];
	dic							= [defaults dictionaryForKey:NET_BROADCAST];
	_broadcastHostList			= [[NSMutableArray alloc] initWithArray:dic[@"Host"]];
	_broadcastIPList			= [[NSMutableArray alloc] initWithArray:dic[@"IPAddress"]];
	// 送信
	_quoteString				= [[defaults stringForKey:SEND_QUOT_STR] copy];
	_openNewOnDockClick			= [defaults boolForKey:SEND_DOCK_SEND];
	_sealCheckDefault			= [defaults boolForKey:SEND_SEAL_CHECK];
	_hideReceiveWindowOnReply	= [defaults boolForKey:SEND_HIDE_REPLY];
	_noticeSealOpened			= [defaults boolForKey:SEND_OPENSEAL_CHECK];
	_allowSendingToMultiUser	= [defaults boolForKey:SEND_MULTI_USER_CHECK];
	str							= [defaults stringForKey:SEND_MSG_FONT_NAME];
	fVal						= [defaults floatForKey:SEND_MSG_FONT_SIZE];
	if (str && (fVal > 0)) {
		sendWindowMessageFont	= [[NSFont fontWithName:str size:fVal] retain];
	}
	// 受信
	str							= [defaults stringForKey:RECV_SOUND];
	_receiveSound				= [[NSSound soundNamed:str] retain];
	_quoteCheckDefault			= [defaults boolForKey:RECV_QUOT_CHECK];
	_nonPopup					= [defaults boolForKey:RECV_NON_POPUP];
	_nonPopupWhenAbsence		= [defaults boolForKey:RECV_ABSENCE_NONPOPUP];
	_iconBoundModeInNonPopup	= [defaults integerForKey:RECV_BOUND_IN_NONPOPUP];
	_useClickableURL			= [defaults boolForKey:RECV_CLICKABLE_URL];
	str							= [defaults stringForKey:RECV_MSG_FONT_NAME];
	fVal						= [defaults floatForKey:RECV_MSG_FONT_SIZE];
	if (str && (fVal > 0)) {
		recvWindowMessageFont	= [[NSFont fontWithName:str size:fVal] retain];
	}
	// 不在
	array						= [defaults arrayForKey:ABSENCE];
	if (!array) {
		array					= _defaultAbsences;
	}
	_absenceList				= [[NSMutableArray alloc] initWithArray:array];
	_absenceIndex				= -1;
	// 通知拒否
	array						= [defaults arrayForKey:REFUSE];
	_refuseList					= [[self convertRefuseDefaultsToInfo:array] retain];
	// ログ
	_standardLogEnabled			= [defaults boolForKey:LOG_STD_ON];
	_logChainedWhenOpen			= [defaults boolForKey:LOG_STD_CHAIN];
	_standardLogFile			= [defaults stringForKey:LOG_STD_FILE];
	_alternateLogEnabled		= [defaults boolForKey:LOG_ALT_ON];
	_logWithSelectedRange		= [defaults boolForKey:LOG_ALT_SELECTION];
	_alternateLogFile			= [defaults stringForKey:LOG_ALT_FILE];

	// 送受信ウィンドウ
	size.width					= [defaults floatForKey:SNDWIN_SIZE_W];
	size.height					= [defaults floatForKey:SNDWIN_SIZE_H];
	_sendWindowSize				= size;
	_sendWindowSplit			= [defaults floatForKey:SNDWIN_SIZE_SPLIT];
	_sendSearchByUserName		= [defaults boolForKey:SNDSEARCH_USER];
	_sendSearchByGroupName		= [defaults boolForKey:SNDSEARCH_GROUP];
	_sendSearchByHostName		= [defaults boolForKey:SNDSEARCH_HOST];
	_sendSearchByLogOnName		= [defaults boolForKey:SNDSEARCH_LOGON];
	sendUserListColDisp			= [[NSMutableDictionary alloc] init];
	dic							= [defaults dictionaryForKey:SNDWIN_USERLIST_COL];
	if (dic) {
		[sendUserListColDisp setDictionary:dic];
	}
	size.width					= [defaults floatForKey:RCVWIN_SIZE_W];
	size.height					= [defaults floatForKey:RCVWIN_SIZE_H];
	self.receiveWindowSize		= size;

	#ifdef IPMSG_LOG_DBG_ENABLED
		// デバッグ用ログ出力
		unsigned int propCount;
		objc_property_t* props = class_copyPropertyList(self.class, &propCount);
		DBG(@"properties[%u]=(", propCount);
		for (NSInteger i = 0; i < propCount; i++) {
			const char*	name	= property_getName(props[i]);
			id			val		= [self valueForKey:[NSString stringWithUTF8String:name]];
			if ([val isKindOfClass:NSArray.class]) {
				DBG(@"\t%s=(", name);
				for (id obj in (NSArray*)val) {
					if ([obj isKindOfClass:NSString.class]) {
						DBG(@"\t\t\"%@\",", obj);
					} else if ([obj isKindOfClass:NSDictionary.class]) {
						NSDictionary* dic = obj;
						DBG(@"\t\t{");
						for (id dicKey in dic.allKeys) {
							NSString* dicVal = dic[dicKey];
							if ([dicVal isKindOfClass:NSString.class]) {
								NSString* strVal = [(NSString*)dicVal stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
								DBG(@"\t\t\t%@ = \"%@\",", dicKey, strVal);
							} else {
								DBG(@"\t\t\t%@ = %@,", dicKey, dicVal);
							}
						}
						DBG(@"\t\t},");
					} else {
						DBG(@"\t\t%@,", obj);
					}
				}
				DBG(@"\t);");
			} else if ([val isKindOfClass:NSString.class]) {
				DBG(@"\t%s=\"%@\";", name, val);
			} else {
				DBG(@"\t%s=%@;", name, val);
			}
		}
		free(props);
		DBG(@")");
	#endif

	#ifdef IPMSG_LOG_TRC_ENABLED
		unsigned int ivarCount;
		Ivar* ivars = class_copyIvarList(self.class, &ivarCount);
		TRC(@"ivars[%u]=(", ivarCount);
		for (NSInteger i = 0; i < ivarCount; i++) {
			const char*	name	= ivar_getName(ivars[i]);
			id			val		= [self valueForKey:[NSString stringWithUTF8String:name]];
			if ((strcmp(name, "_absenceList") == 0) ||
				(strcmp(name, "_defaultAbsences") == 0)) {
				TRC(@"\t%s=(", name);
				for (dic in val) {
					NSString* t = dic[@"Title"];
					NSString* m = dic[@"Message"];
					str = [m stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
					TRC(@"\t\t\"%@\"（\"%@\"）", t, str);
				}
				TRC(@"\t);");
			} else if (strcmp(name, "_refuseList") == 0) {
				TRC(@"\t%s=(", name);
				for (RefuseInfo* ri in val) {
					TRC(@"\t\t\"%@\"", ri);
				}
				TRC(@"\t);");
			} else {
				array = [[val description] componentsSeparatedByString:@"\n"];
				if (array.count > 1) {
					NSInteger num = 0;
					for (NSString* s in array) {
						num++;
						if (num == 1) {
							TRC(@"\t%s=%@", name, s);
						} else if (num == array.count) {
							TRC(@"\t%@;", s);
						} else {
							TRC(@"\t%@", s);
						}
					}
				} else if ([val isKindOfClass:NSString.class]) {
					TRC(@"\t%s=\"%@\";", name, val);
				} else {
					TRC(@"\t%s=%@;", name, val);
				}
			}
		}
		free(ivars);
		TRC(@")");
	#endif

	DBG(@"======== Init Config complated ========");

	return self;
}

// 解放
- (void)dealloc
{
	[_userName release];
	[_groupName release];
	[_password release];
	[_rsa1024PublicKeyModulus release];
	[_rsa2048PublicKeyModulus release];
	[_broadcastHostList release];
	[_broadcastIPList release];
	[_quoteString release];
	[_absenceList release];
	[_refuseList release];
	[sendWindowMessageFont release];
	[sendUserListColDisp release];
	[_receiveSound release];
	[recvWindowMessageFont release];
	[_standardLogFile release];
	[_alternateLogFile release];
	[_defaultMessageFont release];
	[_defaultAbsences release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*
 * 永続化
 *----------------------------------------------------------------------------*/
- (void)save
{
	NSUserDefaults*	def		= [NSUserDefaults standardUserDefaults];
	NSBundle*		mb		= [NSBundle mainBundle];
	NSString*		ver		= [mb objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString*		verstr	= [mb objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

	// 全般
	[def setObject:ver forKey:GEN_VERSION];
	[def setObject:verstr forKey:GEN_VERSION_STR];
	[def setObject:self.userName forKey:GEN_USER_NAME];
	[def setObject:self.groupName forKey:GEN_GROUP_NAME];
	[def setObject:self.password forKey:GEN_PASSWORD];
	[def setInteger:self.rsa1024PublicKeyExponent forKey:GEN_RSA1024EXP];
	[def setObject:self.rsa1024PublicKeyModulus forKey:GEN_RSA1024MOD];
	[def setInteger:self.rsa2048PublicKeyExponent forKey:GEN_RSA2048EXP];
	[def setObject:self.rsa2048PublicKeyModulus forKey:GEN_RSA2048MOD];
	[def setBool:self.useStatusBar forKey:GEN_USE_STATUS_BAR];

	// ネットワーク
	[def setInteger:self.portNo forKey:NET_PORT_NO];
	[def setBool:self.dialup forKey:NET_DIALUP];
	[def setObject:@{@"Host":self.broadcastHostList,
					 @"IPAddress":self.broadcastIPList}
			forKey:NET_BROADCAST];

	// 送信
	[def setObject:self.quoteString forKey:SEND_QUOT_STR];
	[def setBool:self.openNewOnDockClick forKey:SEND_DOCK_SEND];
	[def setBool:self.sealCheckDefault forKey:SEND_SEAL_CHECK];
	[def setBool:self.hideReceiveWindowOnReply forKey:SEND_HIDE_REPLY];
	[def setBool:self.noticeSealOpened forKey:SEND_OPENSEAL_CHECK];
	[def setBool:self.allowSendingToMultiUser forKey:SEND_MULTI_USER_CHECK];
	if (self.sendMessageFont) {
		[def setObject:self.sendMessageFont.fontName forKey:SEND_MSG_FONT_NAME];
		[def setFloat:self.sendMessageFont.pointSize forKey:SEND_MSG_FONT_SIZE];
	}
	// 受信
	[def setObject:self.receiveSoundName forKey:RECV_SOUND];
	[def setBool:self.quoteCheckDefault forKey:RECV_QUOT_CHECK];
	[def setBool:self.nonPopup forKey:RECV_NON_POPUP];
	[def setBool:self.nonPopupWhenAbsence forKey:RECV_ABSENCE_NONPOPUP];
	[def setInteger:self.iconBoundModeInNonPopup forKey:RECV_BOUND_IN_NONPOPUP];
	[def setBool:self.useClickableURL forKey:RECV_CLICKABLE_URL];
	if (self.receiveMessageFont) {
		[def setObject:self.receiveMessageFont.fontName forKey:RECV_MSG_FONT_NAME];
		[def setFloat:self.receiveMessageFont.pointSize forKey:RECV_MSG_FONT_SIZE];
	}

	// 不在
	@synchronized (self.absenceList) {
		[def setObject:self.absenceList forKey:ABSENCE];
	}
	// 通知拒否
	@synchronized (self.refuseList) {
		NSArray<NSDictionary*>* array = [self convertRefuseInfoToDefaults:self.refuseList];
		[def setObject:array forKey:REFUSE];
	}
	// ログ
	[def setBool:self.standardLogEnabled forKey:LOG_STD_ON];
	[def setBool:self.logChainedWhenOpen forKey:LOG_STD_CHAIN];
	[def setObject:self.standardLogFile forKey:LOG_STD_FILE];
	[def setBool:self.alternateLogEnabled forKey:LOG_ALT_ON];
	[def setBool:self.logWithSelectedRange forKey:LOG_ALT_SELECTION];
	[def setObject:self.alternateLogFile forKey:LOG_ALT_FILE];

	// 送受信ウィンドウ位置／サイズ
	[def setFloat:self.sendWindowSize.width forKey:SNDWIN_SIZE_W];
	[def setFloat:self.sendWindowSize.height forKey:SNDWIN_SIZE_H];
	[def setFloat:self.sendWindowSplit forKey:SNDWIN_SIZE_SPLIT];
	[def setBool:self.sendSearchByUserName forKey:SNDSEARCH_USER];
	[def setBool:self.sendSearchByGroupName forKey:SNDSEARCH_GROUP];
	[def setBool:self.sendSearchByHostName forKey:SNDSEARCH_HOST];
	[def setBool:self.sendSearchByLogOnName forKey:SNDSEARCH_LOGON];
	[def setObject:sendUserListColDisp forKey:SNDWIN_USERLIST_COL];
	[def setFloat:self.receiveWindowSize.width forKey:RCVWIN_SIZE_W];
	[def setFloat:self.receiveWindowSize.height forKey:RCVWIN_SIZE_H];

	// 保存
	[def synchronize];
}

/*----------------------------------------------------------------------------*
 * 「ネットワーク」関連
 *----------------------------------------------------------------------------*/
#pragma mark -
#pragma mark ネットワーク関連

- (NSArray*)broadcastAddresses
{
	NSMutableArray* newList = [NSMutableArray array];
	for (NSString* host in _broadcastHostList) {
		NSString* addr = [[NSHost hostWithName:host] address];
		if (addr) {
			if (![newList containsObject:addr]) {
				[newList addObject:addr];
			}
		}
	}
	for (NSString* addr in _broadcastIPList) {
		if (![newList containsObject:addr]) {
			[newList addObject:addr];
		}
	}
	return newList;
}

// ブロードキャスト
- (NSUInteger)numberOfBroadcasts
{
	@synchronized (self.broadcastHostList) {
		@synchronized (self.broadcastIPList) {
			return self.broadcastHostList.count + self.broadcastIPList.count;
		}
	}
}

- (NSString*)broadcastAtIndex:(NSUInteger)index
{
	@try {
		NSUInteger hostnum;
		@synchronized (self.broadcastHostList) {
			hostnum = self.broadcastHostList.count;
			if (index < hostnum) {
				return self.broadcastHostList[index];
			}
		}
		@synchronized (self.broadcastIPList) {
			return self.broadcastIPList[index - hostnum];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
	return nil;
}

- (BOOL)containsBroadcastWithAddress:(NSString*)address
{
	@synchronized (self.broadcastIPList) {
		return [self.broadcastIPList containsObject:address];
	}
}

- (BOOL)containsBroadcastWithHost:(NSString*)host
{
	@synchronized (self.broadcastHostList) {
		return [self.broadcastHostList containsObject:host];
	}
}

- (void)addBroadcastWithAddress:(NSString*)address
{
	@try {
		@synchronized (self.broadcastIPList) {
			[self.broadcastIPList addObject:address];
			[self.broadcastIPList sortUsingSelector:@selector(compare:)];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%@)", exception, address);
	}
}

- (void)addBroadcastWithHost:(NSString*)host
{
	@try {
		@synchronized (self.broadcastHostList) {
			[self.broadcastHostList addObject:host];
			[self.broadcastHostList sortUsingSelector:@selector(compare:)];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%@)", exception, host);
	}
}

- (void)removeBroadcastAtIndex:(NSUInteger)index
{
	@try {
		NSInteger hostnum;
		@synchronized (self.broadcastHostList) {
			hostnum = self.broadcastHostList.count;
			if (index < hostnum) {
				[self.broadcastHostList removeObjectAtIndex:index];
			} else {
				@synchronized (self.broadcastIPList) {
					[self.broadcastIPList removeObjectAtIndex:index - hostnum];
				}
			}
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
}

/*----------------------------------------------------------------------------*
 * 「アップデート」関連
 *----------------------------------------------------------------------------*/
#pragma mark -
#pragma mark アップデート関連

- (BOOL)updateAutomaticCheck
{
	return SUUpdater.sharedUpdater.automaticallyChecksForUpdates;
}

- (void)setUpdateAutomaticCheck:(BOOL)b
{
	SUUpdater.sharedUpdater.automaticallyChecksForUpdates = b;
}

- (NSTimeInterval)updateCheckInterval
{
	return SUUpdater.sharedUpdater.updateCheckInterval;
}

- (void)setUpdateCheckInterval:(NSTimeInterval)interval
{
	SUUpdater.sharedUpdater.updateCheckInterval = interval;
}

/*----------------------------------------------------------------------------*
 * 「送信」関連
 *----------------------------------------------------------------------------*/
#pragma mark -
#pragma mark 送信関連

// メッセージ部フォント
- (NSFont*)defaultSendMessageFont
{
	return self.defaultMessageFont;
}

- (NSFont*)sendMessageFont
{
	return (sendWindowMessageFont) ? sendWindowMessageFont : self.defaultMessageFont;
}

- (void)setSendMessageFont:(NSFont*)font
{
	[font retain];
	[sendWindowMessageFont release];
	sendWindowMessageFont = font;
}

// ユーザリスト表示項目
- (BOOL)sendWindowUserListColumnHidden:(NSString*)identifier
{
	NSNumber* val = sendUserListColDisp[identifier];
	if (val) {
		return !(val.boolValue);
	}
	return NO;
}

- (void)setSendWindowUserListColumn:(NSString*)identifier hidden:(BOOL)hidden
{
	sendUserListColDisp[identifier] = @(!hidden);
}

/*----------------------------------------------------------------------------*
 * 「受信」関連
 *----------------------------------------------------------------------------*/
#pragma mark -
#pragma mark 受信関連

// 受信音
- (NSString*)receiveSoundName
{
	return self.receiveSound.name;
}

- (void)setReceiveSoundName:(NSString*)soundName
{
	self.receiveSound = [NSSound soundNamed:soundName];
}

// メッセージ部フォント
- (NSFont*)defaultReceiveMessageFont
{
	return self.defaultMessageFont;
}

- (NSFont*)receiveMessageFont
{
	return (recvWindowMessageFont) ? recvWindowMessageFont : self.defaultMessageFont;
}

- (void)setReceiveMessageFont:(NSFont*)font
{
	[font retain];
	[recvWindowMessageFont release];
	recvWindowMessageFont = font;
}

/*----------------------------------------------------------------------------*
 * 「不在」関連
 *----------------------------------------------------------------------------*/
#pragma mark -
#pragma mark 不在関連

- (NSUInteger)numberOfAbsences
{
	@synchronized (self.absenceList) {
		return self.absenceList.count;
	}
}

- (NSString*)absenceTitleAtIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.absenceList) {
			NSDictionary* dic = self.absenceList[index];
			return dic[@"Title"];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
	return nil;
}

- (NSString*)absenceMessageAtIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.absenceList) {
			NSDictionary* dic = self.absenceList[index];
			return dic[@"Message"];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
	return nil;
}

- (BOOL)containsAbsenceTitle:(NSString*)title
{
	@try {
		@synchronized (self.absenceList) {
			for (NSDictionary* dic in self.absenceList) {
				if ([title isEqualToString:dic[@"Title"]]) {
					return YES;
				}
			}
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%@)", exception, title);
	}
	return NO;
}

- (void)addAbsenceTitle:(NSString*)title message:(NSString*)msg
{
	@try {
		NSDictionary* dic = @{ @"Title" : title, @"Message" : msg };
		@synchronized (self.absenceList) {
			[self.absenceList addObject:dic];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(title=%@,msg=%@)", exception, title, msg);
	}
}

- (void)insertAbsenceTitle:(NSString*)title message:(NSString*)msg atIndex:(NSUInteger)index
{
	@try {
		NSDictionary* dic = @{ @"Title" : title, @"Message" : msg };
		@synchronized (self.absenceList) {
			[self.absenceList insertObject:dic atIndex:index];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(title=%@,msg=%@,index=%lu)", exception, title, msg, index);
	}
}

- (void)setAbsenceTitle:(NSString*)title message:(NSString*)msg atIndex:(NSInteger)index
{
	@try {
		NSDictionary* dic = @{ @"Title" : title, @"Message" : msg };
		@synchronized (self.absenceList) {
			[self.absenceList replaceObjectAtIndex:index withObject:dic];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(title=%@,msg=%@,index=%lu)", exception, title, msg, index);
	}
}

- (void)upAbsenceAtIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.absenceList) {
			NSDictionary* obj = [self.absenceList[index] retain];
			[self.absenceList removeObjectAtIndex:index];
			[self.absenceList insertObject:obj atIndex:index - 1];
			[obj release];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
}

- (void)downAbsenceAtIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.absenceList) {
			NSDictionary* obj = [self.absenceList[index] retain];
			[self.absenceList removeObjectAtIndex:index];
			[self.absenceList insertObject:obj atIndex:index + 1];
			[obj release];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
}

- (void)removeAbsenceAtIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.absenceList) {
			[self.absenceList removeObjectAtIndex:index];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
}

- (void)resetAllAbsences
{
	@synchronized (self.absenceList) {
		[self.absenceList removeAllObjects];
		[self.absenceList addObjectsFromArray:self.defaultAbsences];
	}
}

- (BOOL)inAbsence
{
	@synchronized (self.absenceList) {
		return ((self.absenceIndex >= 0) && (self.absenceIndex < self.absenceList.count));
	}
}

/*----------------------------------------------------------------------------*
 * 「通知拒否」関連
 *----------------------------------------------------------------------------*/
#pragma mark -
#pragma mark 通知拒否関連

- (NSUInteger)numberOfRefuseInfo
{
	@synchronized(self.refuseList) {
		return self.refuseList.count;
	}
}

- (RefuseInfo*)refuseInfoAtIndex:(NSUInteger)index
{
	@try {
		@synchronized(self.refuseList) {
			return [[self.refuseList[index] retain] autorelease];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
	return nil;
}

- (void)addRefuseInfo:(RefuseInfo*)info
{
	@try {
		@synchronized (self.refuseList) {
			[self.refuseList addObject:info];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(info=%@)", exception, info);
	}
}

- (void)insertRefuseInfo:(RefuseInfo*)info atIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.refuseList) {
			[self.refuseList insertObject:info atIndex:index];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(info=%@,index=%lu)", exception, info, index);
	}
}

- (void)setRefuseInfo:(RefuseInfo*)info atIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.refuseList) {
			[self.refuseList replaceObjectAtIndex:index withObject:info];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(info=%@,index=%lu)", exception, info, index);
	}
}

- (void)upRefuseInfoAtIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.refuseList) {
			RefuseInfo* obj = [self.refuseList[index] retain];
			[self.refuseList removeObjectAtIndex:index];
			[self.refuseList insertObject:obj atIndex:index - 1];
			[obj release];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
}

- (void)downRefuseInfoAtIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.refuseList) {
			RefuseInfo* obj = [self.refuseList[index] retain];
			[self.refuseList removeObjectAtIndex:index];
			[self.refuseList insertObject:obj atIndex:index + 1];
			[obj release];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
}

- (void)removeRefuseInfoAtIndex:(NSUInteger)index
{
	@try {
		@synchronized (self.refuseList) {
			[self.refuseList removeObjectAtIndex:index];
		}
	} @catch (NSException* exception) {
		ERR(@"%@(index=%lu)", exception, index);
	}
}

- (BOOL)matchRefuseCondition:(UserInfo*)user
{
	@synchronized (self.refuseList) {
		for (RefuseInfo* info in self.refuseList) {
			if ([info match:user]) {
				return YES;
			}
		}
	}
	return NO;
}

/*----------------------------------------------------------------------------*
 * 内部利用
 *----------------------------------------------------------------------------*/
#pragma mark -
#pragma mark 内部利用

// 通知拒否リスト変換
- (NSMutableArray<RefuseInfo*>*)convertRefuseDefaultsToInfo:(NSArray<NSDictionary*>*)array
{
	NSMutableArray<RefuseInfo*>* newArray = [NSMutableArray<RefuseInfo*> array];
	for (NSDictionary* dic in array) {
		NSString* targetStr		= dic[@"Target"];
		NSString* string		= dic[@"String"];
		NSString* conditionStr	= dic[@"Condition"];
		if (!targetStr || !string || !conditionStr) {
			continue;
		}
		if (string.length <= 0) {
			continue;
		}
		IPRefuseTarget target = 0;
		if ([targetStr isEqualToString:@"UserName"]) {			target = IP_REFUSE_USER;	}
		else if ([targetStr isEqualToString:@"GroupName"]) {	target = IP_REFUSE_GROUP;	}
		else if ([targetStr isEqualToString:@"MachineName"]) {	target = IP_REFUSE_MACHINE;	}
		else if ([targetStr isEqualToString:@"LogOnName"]) {	target = IP_REFUSE_LOGON;	}
		else if ([targetStr isEqualToString:@"IPAddress"]) {	target = IP_REFUSE_ADDRESS;	}
		else {
			WRN(@"invalid refuse target(%@)", targetStr);
			continue;
		}
		IPRefuseCondition condition = 0;
		if ([conditionStr isEqualToString:@"Match"]) {			condition = IP_REFUSE_MATCH;	}
		else if ([conditionStr isEqualToString:@"Contain"]) {	condition = IP_REFUSE_CONTAIN;	}
		else if ([conditionStr isEqualToString:@"Start"]) {		condition = IP_REFUSE_START;	}
		else if ([conditionStr isEqualToString:@"End"]) {		condition = IP_REFUSE_END;		}
		else {
			WRN(@"invalid refuse condition(%@)", conditionStr);
			continue;
		}

		[newArray addObject:[RefuseInfo refuseInfoWithTarget:target
													  string:string
												   condition:condition]];
	}
	return newArray;
}

- (NSArray<NSDictionary*>*)convertRefuseInfoToDefaults:(NSArray<RefuseInfo*>*)array
{
	NSMutableArray<NSDictionary*>* newArray = [NSMutableArray<NSDictionary*> array];
	for (RefuseInfo* info in array) {
		NSString* target = nil;
		switch (info.target) {
		case IP_REFUSE_USER:	target = @"UserName";		break;
		case IP_REFUSE_GROUP:	target = @"GroupName";		break;
		case IP_REFUSE_MACHINE:	target = @"MachineName";	break;
		case IP_REFUSE_LOGON:	target = @"LogOnName";		break;
		case IP_REFUSE_ADDRESS:	target = @"IPAddress";		break;
		default:
			WRN(@"invalid refuse target(%ld)", info.target);
			continue;
		}
		NSString* condition = nil;
		switch (info.condition) {
		case IP_REFUSE_MATCH:	condition = @"Match";		break;
		case IP_REFUSE_CONTAIN:	condition = @"Contain";		break;
		case IP_REFUSE_START:	condition = @"Start";		break;
		case IP_REFUSE_END:		condition = @"End";			break;
		default:
			WRN(@"invalid refuse condition(%ld)", info.condition);
			continue;
		}
		[newArray addObject:@{
			@"Target"		: target,
			@"String"		: info.string,
			@"Condition"	: condition
		}];
	}
	return [NSArray<NSDictionary*> arrayWithArray:newArray];
}

@end
