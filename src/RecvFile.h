/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RecvFile.h
 *	Module		: 添付ファイルオブジェクトクラス
 *============================================================================*/

#import "RecvAttachment.h"

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface RecvFile : RecvAttachment

@property(copy)		NSString*	path;			// ファイルパス
@property(assign)	BOOL		downloaded;		// DL済みフラグ

- (BOOL)openHandle;
- (BOOL)writeData:(void*)data length:(size_t)len;
- (void)closeHandle;

@end
