/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RecvClipboard.m
 *	Module		: 添付ファイルオブジェクトクラス
 *============================================================================*/

#import <Cocoa/Cocoa.h>

//	#define IPMSG_LOG_TRC	0

#import "RecvClipboard.h"
#import "NSString+IPMessenger.h"
#import "DebugLog.h"

/*============================================================================*
 * プライベートメソッド定義
 *============================================================================*/

@interface RecvClipboard()

@property(retain)	NSImage*		image;
@property(retain)	NSMutableData*	handle;

@end

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation RecvClipboard

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/

// 解放
- (void)dealloc
{
	[_image release];
	[_handle release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*
 * ファイル入出力関連
 *----------------------------------------------------------------------------*/

// 書き込み用に開く
- (BOOL)openHandle
{
	self.handle = [NSMutableData dataWithCapacity:self.size];
	if (!self.handle) {
		ERR(@"Buffer create error(size=%zd)", self.size);
		return NO;
	}
	return YES;
}

// ファイル書き込み
- (BOOL)writeData:(void*)data length:(size_t)len
{
	if (!self.handle) {
		ERR(@"Buffer handle not created.");
		return NO;
	}
	[self.handle appendBytes:data length:len];
	return YES;
}

// ファイルクローズ
- (void)closeHandle
{
	if (!self.handle) {
		ERR(@"Buffer handle not created.");
		return;
	}
	self.image = [[[NSImage alloc] initWithData:self.handle] autorelease];
	if (!self.image) {
		ERR(@"Image Convert error.(%@)", self.name);
	}
	self.handle = nil;
}

/*----------------------------------------------------------------------------*
 * その他
 *----------------------------------------------------------------------------*/

// オブジェクト概要
- (NSString*)description
{
	return [NSString stringWithFormat:@"RecvClipboard[FileID:%ld,File:%@]", self.fileID, self.name];
}

@end
