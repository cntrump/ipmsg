/*============================================================================*
 * (C) 2001-2010 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: UserManager.m
 *	Module		: ユーザ一覧管理クラス		
 *============================================================================*/

#import <Foundation/Foundation.h>
#import "UserManager.h"
#import "UserInfo.h"
#import "DebugLog.h"

#import <netinet/in.h>

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation UserManager

/*----------------------------------------------------------------------------*
 * ファクトリ
 *----------------------------------------------------------------------------*/

// 共有インスタンスを返す
+ (UserManager*)sharedManager {
	static UserManager* sharedManager = nil;
	if (!sharedManager) {
		sharedManager = [[UserManager alloc] init];
	}
	return sharedManager;
}

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/
 
// 初期化
- (id)init {
	self		= [super init];
	userList	= [[NSMutableArray alloc] init];
	dialupSet	= [[NSMutableSet alloc] init];
	lock		= [[NSRecursiveLock alloc] init];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	[lock setName:@"UserManagerLock"];
#endif
	return self;
}

// 解放
- (void)dealloc {
	[userList	release];
	[dialupSet	release];
	[lock		release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*
 * ユーザ情報取得
 *----------------------------------------------------------------------------*/
 
// ユーザ数を返す
- (int)numberOfUsers {
	[lock lock];
	int count = [userList count];
	[lock unlock];
	return count;
}

// 指定ユーザのインデックス番号を返す（見つからない場合NSNotFound）
- (int)indexOfUser:(UserInfo*)user {
	[lock lock];
	int index = [userList indexOfObject:user];
	[lock unlock];
	return index;
}

// 指定インデックスのユーザ情報を返す（見つからない場合nil）
- (UserInfo*)userAtIndex:(int)index {
	[lock lock];
	UserInfo* info = [[[userList objectAtIndex:index] retain] autorelease];
	[lock unlock];
	return info;
}

// 指定キーのユーザ情報を返す（見つからない場合nil）
- (UserInfo*)userForLogOnUser:(NSString*)logOn address:(struct sockaddr_in*)addr {
	UserInfo*	info = nil;
	[lock lock];
	for (int i = 0; i < [userList count]; i++) {
		UserInfo* u = [userList objectAtIndex:i];
		if ([[u logOnUser] isEqualToString:logOn] &&
			([u addressNumber] == ntohl(addr->sin_addr.s_addr)) &&
			([u portNo] == ntohs(addr->sin_port))) {
			info = [[u retain] autorelease];
			break;
		}
	}
	[lock unlock];
	return info;
}

/*----------------------------------------------------------------------------*
 * ユーザ情報追加／削除
 *----------------------------------------------------------------------------*/

// ユーザ一覧変更通知発行
- (void)fireUserListChangeNotice {
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE_USER_LIST_CHANGED object:nil];
}

// ユーザ追加
- (void)appendUser:(UserInfo*)info {
	if (info) {
		[lock lock];
		int index = [userList indexOfObject:info];
		if (index == NSNotFound) {
			// なければ追加
			[userList addObject:info];
		} else {
			// あれば置き換え
			[userList replaceObjectAtIndex:index withObject:info];
		}
		// リストのソート
		[userList sortUsingSelector:@selector(compare:)];
		// ダイアルアップユーザであればアドレス一覧を更新
		if ([info dialup]) {
			[dialupSet addObject:[[[info address] copy] autorelease]];
		}
		[lock unlock];
		[self fireUserListChangeNotice];
	}
}

// ユーザ削除
- (void)removeUser:(UserInfo*)info {
	if (info) {
		[lock lock];
		int index = [self indexOfUser:info];
		if (index != NSNotFound) {
			// あれば削除
			[userList removeObjectAtIndex:index];
			if ([dialupSet containsObject:[info address]]) {
				[dialupSet removeObject:[info address]];
			}
			[self fireUserListChangeNotice];
		}
		[lock unlock];
	}
}

// ずべてのユーザを削除
- (void)removeAllUsers {
	[lock lock];
	[userList removeAllObjects];
	[dialupSet removeAllObjects];
	[lock unlock];
	[self fireUserListChangeNotice];
}

/*----------------------------------------------------------------------------*
 * その他
 *----------------------------------------------------------------------------*/

// ユーザ一覧の再ソート
- (void)sortUsers {
	// リストのソート
	[lock lock];
	[userList sortUsingSelector:@selector(compare:)];
	[lock unlock];
	[self fireUserListChangeNotice];
}

// ダイアルアップアドレス一覧
- (NSArray*)dialupAddresses {
	[lock lock];
	NSArray* array = [dialupSet allObjects];
	[lock unlock];
	return array;
}

@end
