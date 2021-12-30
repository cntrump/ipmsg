/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: NSString+IPMessenger.m
 *	Module		: NSStringカテゴリ拡張
 *============================================================================*/

#import "NSString+IPMessenger.h"
#import "DebugLog.h"

/*============================================================================*
 * 定数定義
 *============================================================================*/

// SJISリードバイト判定テーブル（2byte文字上位バイトは 0x81〜0x9F,0xE0〜0xFC）
static const BOOL _SjisLead[] = {
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0x0x
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0x1x
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0x2x
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0x3x
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0x4x
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0x5x
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0x6x
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0x7x
	NO,	YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,	// 0x8x
	YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,	// 0x9x
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0xAx
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0xBx
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0xCx
	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,	NO,		// 0xDx
	YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,	// 0xEx
	YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,YES,NO,	NO,	NO,		// 0xFx
};

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation NSString(IPMessenger)

/*----------------------------------------------------------------------------*/
#pragma mark - クラスメソッド
/*----------------------------------------------------------------------------*/

// IPMessenger用送受信文字列変換（C文字列→NSString)
+ (instancetype)stringWithCString:(const char*)nullTerminatedCString utf8Encoded:(BOOL)utf8
{
	NSStringEncoding enc = utf8 ? NSUTF8StringEncoding : [NSString localeDependStringEncoding];
	return [NSString stringWithCString:nullTerminatedCString encoding:enc];
}

+ (instancetype)stringWithData:(NSData *)data utf8Encoded:(BOOL)utf8
{
	NSStringEncoding enc = utf8 ? NSUTF8StringEncoding : [NSString localeDependStringEncoding];
	return [[[NSString alloc] initWithData:data encoding:enc] autorelease];
}

+ (NSStringEncoding)localeDependStringEncoding
{
	static NSStringEncoding enc = NSUIntegerMax;
	if (enc == NSUIntegerMax) {
		NSString* locale = NSLocale.currentLocale.localeIdentifier;
		DBG(@"locale=%@", locale);
		if ([locale hasPrefix:@"en"]) {
			DBG(@"MBCSEncoding = CP1252(ANSI)");
			enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsLatin1);
		} else if ([locale hasPrefix:@"zh-Hans"]) {
			DBG(@"MBCS Encoding = CP936(GBK)");
			enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSChineseSimplif);
		} else if ([locale hasPrefix:@"zh-Hant"]) {
			DBG(@"MBCS Encoding = CP950(Big5)");
			enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSChineseTrad);
		} else if ([locale hasPrefix:@"ko-Kore"]) {
			DBG(@"MBCS Encoding = CP949(UHC)");
			enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSKorean);
		} else {
			DBG(@"MBCSEncoding = CP932(Windows-31J)");
			enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
		}
	}
	return enc;
}

/*----------------------------------------------------------------------------*/
#pragma mark - データ変換
/*----------------------------------------------------------------------------*/

// IPMessenger用送受信データ変換（NSString→NSData)
- (NSData*)dataUsingUTF8:(BOOL)useUTF8 nullTerminate:(BOOL)containNull
{
	return [self dataUsingUTF8:useUTF8 nullTerminate:containNull maxLength:NSUIntegerMax];
}

// 指定サイズ未満の文字符号化データに変換する
- (NSData*)dataUsingUTF8:(BOOL)useUTF8 nullTerminate:(BOOL)containNull maxLength:(NSUInteger)maxLength
{
	if (containNull && (maxLength == 0)) {
		ERR(@"illlegal Parameter(containNull although maxLength is 0");
		return nil;
	}

	NSData* data = nil;
	if (useUTF8) {
		data = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	} else {
		// SJISの場合、'¥'は'\'に変換しておかないと文字化けする
		NSString* str = [self stringByReplacingOccurrencesOfString:@"¥" withString:@"\\"];
		data = [str dataUsingEncoding:[NSString localeDependStringEncoding] allowLossyConversion:YES];
	}
	if (data.length > maxLength - (containNull ? 1 : 0)) {
		// 切り詰め
		NSMutableData*	work	= [data mutableCopy];
		UInt8* 			bytes	= (UInt8*)work.mutableBytes;
		NSUInteger		pos		= maxLength - 1;
		// 最後の文字境界を探す
		if (useUTF8) {
			// UTF8のの文字境界は、上位1ビットが0(ASCII)か、上位2ビットが1（リードバイト）
			//	→ 上位2bitが10bのものはトレイルバイト
			while (((bytes[pos] & 0xC0) == 0x80) && (pos > 0)) {
				pos--;
			}
		} else {
			// SJISの文字境界は仕組み上前からなめる以外に判定できない
			UInt8*	ptr		= bytes;
			UInt8*	tail	= &bytes[pos];
			BOOL	isLead	= NO;
			for (; ptr < tail; ptr++) {
				if (isLead) {
					isLead = NO;
				} else {
					isLead = _SjisLead[*ptr];
				}
			}
			if (isLead) {
				// 末尾が2byte文字の上位バイトなら1byte切り詰める
				pos--;
			}
		}
		// 文字境界にNULL終端設定
		bytes[pos] = '\0';
		data = [NSData dataWithBytes:bytes length:pos + (containNull ? 1 : 0)];
	} else {
		// サイズ内
		if (containNull) {
			// NULL終端追加
			NSMutableData* work = [data mutableCopy];
			[work increaseLengthBy:1];
			data = work;
		}
	}
	return data;
}

@end
