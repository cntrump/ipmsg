/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: LogManager.h
 *	Module		: ログ管理クラス
 *============================================================================*/

#import <Foundation/Foundation.h>

@class RecvMessage;
@class SendMessage;
@class UserInfo;

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface LogManager : NSObject

@property(copy)	NSString*	filePath;		// ログファイルパス

// ファクトリ
+ (LogManager*)standardLog;
+ (LogManager*)alternateLog;

// ログ出力
- (void)writeRecvLog:(RecvMessage*)info;
- (void)writeRecvLog:(RecvMessage*)info withRange:(NSRange)range;
- (void)writeSendLog:(SendMessage*)info to:(NSArray<UserInfo*>*)to;

@end
