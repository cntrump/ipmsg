/*============================================================================*
 * (C) 2001-2003 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: NSStringIPMessenger.h
 *	Module		: NSStringカテゴリ拡張		
 *============================================================================*/

#import <Foundation/Foundation.h>


@interface NSString(IPMessenger)

// IPMessenger用送受信文字列変換（C文字列→NSString)
+ (id)stringWithIPMsgCString:(const char*)cString;

// IPMessenger用送受信文字列変換（C文字列→NSString)
- (id)initWithIPMsgCString:(const char*)cString;

// IPMessenger用送受信文字列変換
- (const char*)ipmsgCString;

// FSSpec獲得（Carbon）
- (BOOL)getFSSpec:(FSSpec*)fsSpec;

// FInfo獲得（Carbon）
- (BOOL)getFInfo:(FInfo*)fInfo;

@end
