/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RecvClipboard.h
 *	Module		: クリップボード画像オブジェクトクラス
 *============================================================================*/

#import <Cocoa/Cocoa.h>
#import "RecvAttachment.h"

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface RecvClipboard : RecvAttachment

@property(readonly)	NSImage*	image;				// 埋め込み画像
@property(assign)	NSInteger	clipboardPos;		// 埋め込み位置

- (BOOL)openHandle;
- (BOOL)writeData:(void*)data length:(size_t)len;
- (void)closeHandle;

@end
