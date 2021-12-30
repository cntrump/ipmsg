/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RecvAttachment.m
 *	Module		: 受信添付情報抽象クラス
 *============================================================================*/

#import "RecvAttachment.h"
#import "DebugLog.h"

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation RecvAttachment

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/

// 初期化
- (instancetype)init
{
	self = [super init];
	if (self) {
		_type	= _ATTACH_TYPE_UNKNOWN;
		_fileID	= NSNotFound;
	}
	return self;
}

// 解放
- (void)dealloc
{
	[_name release];
	[_createTime release];
	[_modifyTime release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*
 * 受信データ保存
 *----------------------------------------------------------------------------*/

- (BOOL)openHandle
{
	ERR(@"Need to override(Internal Error)");
	return NO;
}

- (BOOL)writeData:(void*)data length:(size_t)len
{
	ERR(@"Need to override(Internal Error)");
	return NO;
}

- (void)closeHandle
{
	ERR(@"Need to override(Internal Error)");
}

/*----------------------------------------------------------------------------*
 * その他
 *----------------------------------------------------------------------------*/

// オブジェクト概要
- (NSString*)description
{
	return [NSString stringWithFormat:@"RecvAttachment[FileID:%ld,File:%@]",
													self.fileID, self.name];
}

@end
