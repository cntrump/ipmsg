/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: LogManager.m
 *	Module		: ログ管理クラス
 *============================================================================*/

#import <Foundation/Foundation.h>
#import "LogManager.h"
#import "UserInfo.h"
#import "Config.h"
#import "RecvMessage.h"
#import "SendMessage.h"
#import "DebugLog.h"

// 定数定義
static NSString* _HEAD_START	= @"=====================================\n";
static NSString* _HEAD_END		= @"-------------------------------------\n";

@interface LogManager()

@property(retain)	NSFileManager*		fileMgr;
@property(copy)		NSString*			typeBroadcast;
@property(copy)		NSString*			typeMulticast;
@property(copy)		NSString*			typeAutoReturn;
@property(copy)		NSString*			typeLocked;
@property(copy)		NSString*			typeSealed;
@property(copy)		NSString*			typeAttached;
@property(retain)	NSDateFormatter*	dateFormat;

- (void)writeLog:(NSString*)msg;

@end

// クラス実装
@implementation LogManager

/*============================================================================*
 * ファクトリ
 *============================================================================*/

// 標準ログ
+ (LogManager*)standardLog
{
	static LogManager*		standardLog = nil;
	static dispatch_once_t	once;
	dispatch_once(&once, ^{
		standardLog = [[LogManager alloc] initWithPath:Config.sharedConfig.standardLogFile];
	});
	return standardLog;
}

// 重要ログ
+ (LogManager*)alternateLog
{
	static LogManager*		alternateLog = nil;
	static dispatch_once_t	once;
	dispatch_once(&once, ^{
		alternateLog = [[LogManager alloc] initWithPath:Config.sharedConfig.alternateLogFile];
	});
	return alternateLog;
}

/*============================================================================*
 * 初期化／解放
 *============================================================================*/

// 初期化
- (id)initWithPath:(NSString*)path
{
	self = [super init];
	if (self) {
		if (!path) {
			ERR(@"Param Error(path is null)");
			[self release];
			return nil;
		}
		_fileMgr		= NSFileManager.defaultManager;
		_filePath		= [[path stringByExpandingTildeInPath] copy];
		_typeBroadcast	= [NSLocalizedString(@"Log.Type.Broadcast", nil) copy];
		_typeMulticast	= [NSLocalizedString(@"Log.Type.Multicast", nil) copy];
		_typeAutoReturn	= [NSLocalizedString(@"Log.Type.AutoRet", nil) copy];
		_typeLocked		= [NSLocalizedString(@"Log.Type.Locked", nil) copy];
		_typeSealed		= [NSLocalizedString(@"Log.Type.Sealed", nil) copy];
		_typeAttached	= [NSLocalizedString(@"Log.Type.Attachment", nil) copy];
		_dateFormat		= [[NSDateFormatter alloc] init];
		_dateFormat.formatterBehavior	= NSDateFormatterBehavior10_4;
		_dateFormat.dateStyle			= NSDateFormatterFullStyle;
		_dateFormat.timeStyle			= NSDateFormatterMediumStyle;
	}
	return self;
}

// 解放
- (void)dealloc
{
	[_fileMgr release];
	[_filePath release];
	[_typeBroadcast release];
	[_typeMulticast release];
	[_typeAutoReturn release];
	[_typeLocked release];
	[_typeSealed release];
	[_typeAttached release];
	[_dateFormat release];
	[super dealloc];
}

/*============================================================================*
 * ログ出力
 *============================================================================*/

// 受信ログ出力
- (void)writeRecvLog:(RecvMessage*)info
{
	[self writeRecvLog:info withRange:NSMakeRange(0, 0)];
}

// 受信ログ出力
- (void)writeRecvLog:(RecvMessage*)info withRange:(NSRange)range
{
	// メッセージ編集
	NSMutableString* msg = [NSMutableString string];
	[msg appendString:_HEAD_START];
	[msg appendString:@" From: "];
	[msg appendString:info.fromUser.summaryString];
	[msg appendString:@"\n  at "];
	[msg appendString:[self.dateFormat stringFromDate:info.receiveDate]];
	if (info.broadcast) {
		[msg appendString:self.typeBroadcast];
	}
	if (info.absence) {
		[msg appendString:self.typeAutoReturn];
	}
	if (info.multicast) {
		[msg appendString:self.typeMulticast];
	}
	if (info.locked) {
		[msg appendString:self.typeLocked];
	} else if (info.sealed) {
		[msg appendString:self.typeSealed];
	}
	[msg appendString:@"\n"];
	[msg appendString:_HEAD_END];
	if (range.length > 0) {
		[msg appendString:[info.message substringWithRange:range]];
	} else {
		[msg appendString:info.message];
	}
	[msg appendString:@"\n\n"];

	// ログ出力
	[self writeLog:msg];
}

// 送信ログ出力
- (void)writeSendLog:(SendMessage*)info to:(NSArray<UserInfo*>*)to
{
	// メッセージ編集
	NSMutableString* msg = [NSMutableString string];
	[msg appendString:_HEAD_START];
	for (UserInfo* user in to) {
		[msg appendString:@" To: "];
		[msg appendString:user.summaryString];
		[msg appendString:@"\n"];
	}
	[msg appendString:@"  at "];
	[msg appendString:[self.dateFormat stringFromDate:[NSDate date]]];
	if (to.count > 1) {
		[msg appendString:self.typeMulticast];
	}
	if (info.locked) {
		[msg appendString:self.typeLocked];
	} else if (info.sealed) {
		[msg appendString:self.typeSealed];
	}
	if (info.attachments.count > 0) {
		[msg appendString:self.typeAttached];
	}
	[msg appendString:@"\n"];
	[msg appendString:_HEAD_END];
	[msg appendString:info.message];
	[msg appendString:@"\n\n"];

	// ログ出力
	[self writeLog:msg];
}

// メッセージ出力（内部用）
- (void)writeLog:(NSString*)msg
{
	if (!msg) {
		return;
	}
	if (msg.length <= 0) {
		return;
	}
	if (![self.fileMgr fileExistsAtPath:self.filePath]) {
		const Byte	dat[]	= { 0xEF, 0xBB, 0xBF };
		NSData*		bom		= [NSData dataWithBytes:dat length:sizeof(dat)];
		if (![self.fileMgr createFileAtPath:self.filePath contents:bom attributes:nil]) {
			ERR(@"LogFile Create Error.(%@)", self.filePath);
			return;
		}
	}
	if (![self.fileMgr isWritableFileAtPath:self.filePath]) {
		ERR(@"LogFile not writable.(%@)", self.filePath);
		return;
	}
	NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
	if (!file) {
		ERR(@"LogFile open Error.(%@)", self.filePath);
		return;
	}
	[file seekToEndOfFile];
	[file writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
	[file closeFile];
}

@end
