/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: UserManager.m
 *	Module		: ユーザ情報一覧管理クラス
 *============================================================================*/

#import "UserManager.h"
#import "UserInfo.h"
#import "DebugLog.h"

/*============================================================================*
 * NSNotification通知キー
 *============================================================================*/

NSString* const kIPMsgUserListChangedNotification = @"IPMsgUserListChanged";

/*============================================================================*
 * 内部クラス拡張
 *============================================================================*/

@interface UserManager()

@property(retain)	NSMutableArray<UserInfo*>*	userList;

- (void)fireUserListChangeNotice;

@end

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation UserManager

//*---------------------------------------------------------------------------*
#pragma mark - クラスメソッド
//*---------------------------------------------------------------------------*

// 共有インスタンスを返す
+ (instancetype)sharedManager
{
	static UserManager*		sharedManager = nil;
	static dispatch_once_t	once;

	dispatch_once(&once, ^{
		sharedManager = [[UserManager alloc] init];
	});

	return sharedManager;
}

//*---------------------------------------------------------------------------*
#pragma mark - 初期化/解放
//*---------------------------------------------------------------------------*

// 初期化
- (instancetype)init
{
	self = [super init];
	if (self) {
		_userList = [[NSMutableArray<UserInfo*> alloc] init];
	}
	return self;
}

// 解放
- (void)dealloc
{
	[_userList release];
	[super dealloc];
}

//*---------------------------------------------------------------------------*
#pragma mark - プロパティアクセス
//*---------------------------------------------------------------------------*

// ユーザ情報一覧
- (NSArray<UserInfo*>*)users
{
	@synchronized (self.userList) {
		return [NSArray arrayWithArray:self.userList];
	}
}

//*---------------------------------------------------------------------------*
#pragma mark - ユーザー情報アクセス
//*---------------------------------------------------------------------------*

// 指定キーのユーザ情報を返す（見つからない場合nil）
- (UserInfo*)userForLogOnUser:(NSString*)logOn address:(struct sockaddr_in*)addr
{
	@synchronized (self.userList) {
		for (UserInfo* user in self.userList) {
			if ([user.logOnName isEqualToString:logOn] &&
				(user.address.sin_addr.s_addr == addr->sin_addr.s_addr)) {
				return [[user retain] autorelease];
			}
		}
	}
	return nil;
}

// ユーザ追加
- (void)appendUser:(UserInfo*)user
{
	@synchronized (self.userList) {
		NSUInteger index = [self.userList indexOfObject:user];
		if (index == NSNotFound) {
			// なければ追加
			[self.userList addObject:user];
		} else {
			// あれば置き換え
			self.userList[index] = user;
		}
	}
	[self fireUserListChangeNotice];
}

// ユーザ削除
- (void)removeUser:(UserInfo*)user
{
	BOOL changed = NO;
	@synchronized (self.userList) {
		NSUInteger index = [self.userList indexOfObject:user];
		if (index != NSNotFound) {
			// あれば削除
			[self.userList removeObjectAtIndex:index];
			changed = YES;
		}
	}
	if (changed) {
		[self fireUserListChangeNotice];
	}
}

// ずべてのユーザを削除
- (void)removeAllUsers
{
	@synchronized (self.userList) {
		[self.userList removeAllObjects];
	}
	[self fireUserListChangeNotice];
}

//*---------------------------------------------------------------------------*
#pragma mark - 内部利用
//*---------------------------------------------------------------------------*

// ユーザ一覧変更通知発行
- (void)fireUserListChangeNotice
{
	NSNotificationCenter* nc = NSNotificationCenter.defaultCenter;
	[nc postNotificationName:kIPMsgUserListChangedNotification object:nil];
}

@end
