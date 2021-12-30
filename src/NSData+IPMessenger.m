/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: NSData+IPMessenger.m
 *	Module		: NSDataカテゴリ拡張
 *============================================================================*/

#import "NSData+IPMessenger.h"
#import "DebugLog.h"

/*============================================================================*
 * 定数定義
 *============================================================================*/

// HEX encode用テーブル
static const char encTableHEX[17] = "0123456789abcdef";

// HEX decode用テーブル
static const UInt8 hexDecTable[128] = {
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0,    1,    2,    3,    4,    5,    6,    7,    8,    9, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF,   10,   11,   12,   13,   14,   15, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF,   10,   11,   12,   13,   14,   15, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
};

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation NSData(IPMessenger)

/*----------------------------------------------------------------------------*/
#pragma mark - クラスメソッド
/*----------------------------------------------------------------------------*/

// HEX文字列からNSDataを生成する
+ (instancetype)dataWithHexEncodedString:(NSString*)binaryString
{
	return [NSData dataWithBinaryEncodedString:binaryString base64Encoded:NO];
}

// Base64文字列からNSDataを生成する
+ (instancetype)dataWithBase64EncodedString:(NSString*)binaryString
{
	return [NSData dataWithBinaryEncodedString:binaryString base64Encoded:YES];
}

// バイナリ文字列からNSDataを生成する
+ (instancetype)dataWithBinaryEncodedString:(NSString*)binaryString base64Encoded:(BOOL)base64
{
	return [[[NSData alloc] initWithBinaryEncodedString:binaryString base64Encoded:base64] autorelease];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 初期化
/*----------------------------------------------------------------------------*/

// HEX文字列からNSDataを生成する
- (instancetype)initWithHexEncodedString:(NSString*)binaryString
{
	return [self initWithBinaryEncodedString:binaryString base64Encoded:NO];
}

// Base64文字列からNSDataを生成する
- (instancetype)initWithBase64EncodedString:(NSString*)binaryString
{
	return [self initWithBinaryEncodedString:binaryString base64Encoded:YES];
}

// バイナリ文字列からNSDataを生成する
- (instancetype)initWithBinaryEncodedString:(NSString*)binaryString base64Encoded:(BOOL)base64
{
	if (base64) {
		NSDataBase64DecodingOptions opt = 0;	// strict
		self = [self initWithBase64EncodedString:binaryString options:opt];
	} else {
		if (binaryString.length % 2 != 0) {
			ERR(@"invalid length(%ld)", binaryString.length);
			[self release];
			return nil;
		}
		const char* src = binaryString.UTF8String;	// 実質ASCII
		size_t		len = binaryString.length >> 1;
		UInt8		dst[len];
		for (NSInteger i = 0; i < binaryString.length; i += 2) {
			if (src[i] & 0x80) {
				ERR(@"Invalid data src[%ld]=0x%02X", i, src[i]);
				return nil;
			}
			// MSB
			UInt8 val = hexDecTable[src[i]];
			if (val > 15) {
				ERR(@"Invalid data src[%ld]=0x%02X", i, src[i]);
			}
			dst[i >> 1] = val << 4;
			// LSB
			val = hexDecTable[src[i+1]];
			if (val > 15) {
				ERR(@"Invalid data src[%ld]=0x%02X", i, src[i]);
			}
			dst[i >> 1] |= val;
		}
		self = [self initWithBytes:dst length:len];
	}
	return self;
}

/*----------------------------------------------------------------------------*/
#pragma mark - バイナリ文字列変換
/*----------------------------------------------------------------------------*/

// HEX文字列に変換する
- (NSString*)hexEncodedString
{
	return [self binaryEncodedStringUsingBase64:NO];
}

// Base64文字列に変換する
- (NSString*)base64EncodedString
{
	return [self binaryEncodedStringUsingBase64:YES];
}

// バイナリ文字列に変換する
- (NSString*)binaryEncodedStringUsingBase64:(BOOL)useBase64
{
	if (useBase64) {
		NSDataBase64EncodingOptions opt = 0;	// no LineBreak
		return [self base64EncodedStringWithOptions:opt];
	}

	// HEX
	char	buf[self.length * 2 + 1];
	UInt8*	src	= (UInt8*)self.bytes;
	char*	dst	= &buf[0];

	// HEX
	for (NSUInteger i = 0; i < self.length; i++) {
		*(dst++) = encTableHEX[*src >> 4];
		*(dst++) = encTableHEX[*src & 0x0F];
		src++;
	}
	*dst = '\0';

	return [NSString stringWithUTF8String:buf];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 反転データ作成
/*----------------------------------------------------------------------------*/

// バイト列反転データ
- (NSData*)dataWithReversedBytes
{
	return [self dataWithReversedBytesInRange:NSMakeRange(0, self.length)];
}

// 指定範囲バイト列反転データ
- (NSData*)dataWithReversedBytesInRange:(NSRange)range
{
	if (range.location + range.length > self.length) {
		ERR(@"Invalid Parameter(overlow:%@)", NSStringFromRange(range));
		return nil;
	}
	NSMutableData*	temp = [self mutableCopy];
	UInt8*			head = (UInt8*)temp.bytes + range.location;
	UInt8*			tail = head + range.length - 1;

	for (UInt8* end = head + (range.length/2); head < end; head++, tail--) {
		UInt8 work = *head;
		*head = *tail;
		*tail = work;
	}

	return temp;
}

@end
