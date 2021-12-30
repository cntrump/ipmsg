/*============================================================================*
 * (C) 2001-2010 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: UserManager.h
 *	Module		: ユーザ一覧管理クラス		
 *============================================================================*/

#import <Foundation/Foundation.h>

@class UserInfo;

/*============================================================================*
 * Notification 通知キー
 *============================================================================*/

// ユーザ一覧変更
#define NOTICE_USER_LIST_CHANGED		@"IPMsgUserListChanged"

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface UserManager : NSObject {
	NSMutableArray*		userList;		// ユーザ一覧
	NSMutableSet*		dialupSet;		// ダイアルアップアドレス一覧
	NSRecursiveLock*	lock;			// 更新排他用ロック
}

// ファクトリ
+ (UserManager*)sharedManager;

// ユーザ情報取得
- (int)numberOfUsers;
- (int)indexOfUser:(UserInfo*)user;
- (UserInfo*)userAtIndex:(int)index;
- (UserInfo*)userForLogOnUser:(NSString*)logOn address:(struct sockaddr_in*)addr;

// ユーザ情報追加／削除
- (void)appendUser:(UserInfo*)info;
- (void)removeUser:(UserInfo*)info;
- (void)removeAllUsers;

// その他
- (void)sortUsers;
- (NSArray*)dialupAddresses;

@end
