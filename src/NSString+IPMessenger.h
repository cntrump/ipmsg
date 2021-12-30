/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: NSString+IPMessenger.h
 *	Module		: NSStringカテゴリ拡張
 *============================================================================*/

#import <Foundation/Foundation.h>

@interface NSString(IPMessenger)

// 送受信文字列変換（C文字列→NSString)
+ (instancetype)stringWithCString:(const char*)nullTerminatedCString utf8Encoded:(BOOL)utf8;
+ (instancetype)stringWithData:(NSData *)data utf8Encoded:(BOOL)utf8;

// 送受信データ変換（NSString→NSData)
- (NSData*)dataUsingUTF8:(BOOL)useUTF8 nullTerminate:(BOOL)containNull;
- (NSData*)dataUsingUTF8:(BOOL)useUTF8 nullTerminate:(BOOL)containNull maxLength:(NSUInteger)maxLength;

@end
