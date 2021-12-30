/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: UserManager.h
 *	Module		: ユーザ情報一覧管理クラス
 *============================================================================*/

#import <Foundation/Foundation.h>
#import <netinet/in.h>

@class UserInfo;

/*============================================================================*
 * Notification 通知キー
 *============================================================================*/

/// ユーザ情報一覧更新通知
extern NSString* const kIPMsgUserListChangedNotification;

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface UserManager : NSObject

/// ユーザ情報一覧
@property(readonly)	NSArray<UserInfo*>*	users;

// 共有インスタンス
+ (instancetype)sharedManager;

// ユーザ検索
- (UserInfo*)userForLogOnUser:(NSString*)logOn address:(struct sockaddr_in*)addr;

// ユーザ追加／削除
- (void)appendUser:(UserInfo*)user;
- (void)removeUser:(UserInfo*)user;
- (void)removeAllUsers;

@end
