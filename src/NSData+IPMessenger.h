/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: NSData+IPMessenger.h
 *	Module		: NSDataカテゴリ拡張
 *============================================================================*/

#import <Foundation/Foundation.h>

@interface NSData(IPMessenger)

// バイナリ文字列からNSDataを生成する
+ (instancetype)dataWithHexEncodedString:(NSString*)binaryString;
+ (instancetype)dataWithBase64EncodedString:(NSString*)binaryString;
+ (instancetype)dataWithBinaryEncodedString:(NSString*)binaryString base64Encoded:(BOOL)base64;

// バイナリ文字列からNSDataを生成する
- (instancetype)initWithHexEncodedString:(NSString*)binaryString;
- (instancetype)initWithBase64EncodedString:(NSString*)binaryString;
- (instancetype)initWithBinaryEncodedString:(NSString*)binaryString base64Encoded:(BOOL)base64;

// バイナリ文字列に変換する
- (NSString*)hexEncodedString;
- (NSString*)base64EncodedString;
- (NSString*)binaryEncodedStringUsingBase64:(BOOL)useBase64;

// バイト列反転データ作成
- (NSData*)dataWithReversedBytes;
- (NSData*)dataWithReversedBytesInRange:(NSRange)range;

@end
