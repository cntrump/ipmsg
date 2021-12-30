/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: SendAttachment.h
 *	Module		: 送信添付ファイル情報クラス
 *============================================================================*/

#import <Foundation/Foundation.h>

@class UserInfo;

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface SendAttachment : NSObject

@property(assign)	NSInteger			packetNo;		// パケット番号
@property(assign)	NSInteger			fileID;			// ファイルID
@property(readonly)	NSString*			path;			// ファイルパス
@property(readonly)	NSString*			name;			// ファイル名
@property(readonly)	NSArray<UserInfo*>*	remainUsers;	// 未ダウンロードユーザ
@property(retain)	NSTimer*			trashTimer;		// 破棄タイマ

// ファクトリ
+ (instancetype)attachmentWithPath:(NSString*)path;

// 初期化
- (instancetype)initWithPath:(NSString*)path;

// 送信ユーザ管理
- (NSInteger)addUser:(UserInfo*)user;
- (NSInteger)removeUser:(UserInfo*)user;

@end
