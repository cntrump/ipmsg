/*============================================================================*
 * (C) 2001-2003 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: NSStringIPMessenger.m
 *	Module		: NSStringカテゴリ拡張		
 *============================================================================*/

#import "NSStringIPMessenger.h"
#import "DebugLog.h"

@implementation NSString(IPMessenger)

// IPMessenger用送受信文字列変換（C文字列→NSString)
+ (id)stringWithIPMsgCString:(const char*)cString {
	return [[[NSString alloc] initWithIPMsgCString:cString] autorelease];
}

// IPMessenger用送受信文字列変換（C文字列→NSString)
- (id)initWithIPMsgCString:(const char*)cString {
	NSData* data;
	char*	lang = getenv("LANG");
	if (!cString) {
		[self release];
		return nil;
	}
	data = [NSData dataWithBytes:cString length:strlen(cString)];
	self = [self initWithData:data encoding:NSShiftJISStringEncoding];
	// 日本語環境なら'\'は'¥'に変換（IPMsgのプロトコルがSJISだから）
	if (lang) {
		if (strncmp(lang, "ja", 2) == 0) {
			NSRange range = [self rangeOfString:@"\\" options:NSLiteralSearch];
			if (range.location != NSNotFound) {
				NSMutableString* str = [self mutableCopy];
				static NSString* yen = nil;
				if (!yen) {
					char	cYen[]	= { 0, 0xA5, 0 };
					NSData*	dYen	= [NSData dataWithBytes:cYen length:sizeof(cYen)];
					yen = [[NSString alloc] initWithData:dYen encoding:NSUnicodeStringEncoding];
				}
				while (range.location != NSNotFound) {
					[str replaceCharactersInRange:range withString:yen];
					range = [str rangeOfString:@"\\" options:NSLiteralSearch];
				}
				[self release];
				self = str;
			}
		}
	}
	return self;
}

// IPMessenger用送受信文字列変換（NSString→C文字列)
- (const char*)ipmsgCString {
	NSData*			data1;
	NSMutableData*	data2;
	NSRange			range = [self rangeOfString:@"\245" options:NSLiteralSearch];
	if (range.location != NSNotFound) {
		// '¥'は'\'に変換しておかないと文字化けする（IPMsgのプロトコルがSJISだから）
		NSMutableString* str = [[self mutableCopy] autorelease];
		while (range.location != NSNotFound) {
			[str replaceCharactersInRange:range withString:@"\\"];
			range = [str rangeOfString:@"\245" options:NSLiteralSearch];
		}
		data1 = [str dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES];
	} else {
		// '¥'がないならそのまま
		data1 = [self dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES];
	}
	data2 = [NSMutableData dataWithLength:([data1 length] + 1)];
	[data2 setData:data1];
	return (const char*)[data2 bytes];
}

// FSSpec獲得（Carbon）
- (BOOL)getFSSpec:(FSSpec*)fsSpec {
	FSRef		fsRef;
	OSStatus	osStatus;
	OSErr		osError;
	Boolean		isDir;
	
	if (![self isAbsolutePath]) {
		WRN1(@"not absolute path unable to get FSSpec(%@)", self);
		return NO;
	}
	osStatus = FSPathMakeRef([self UTF8String], &fsRef, &isDir);
	if (osStatus != noErr) {
		WRN2(@"FSRef make error(%@,status=%d)", self, osStatus);
		return NO;
	}
	osError = FSGetCatalogInfo(&fsRef, kFSCatInfoNone, NULL, NULL, fsSpec, NULL);
	if (osError != noErr) {
		WRN2(@"FSSpec get error(%@,err=%d)", self, osError);
		return NO;
	}
	
	return YES;
}

// FInfo獲得（Carbon）
- (BOOL)getFInfo:(FInfo*)fInfo {
	FSSpec			fsSpec;
	OSErr			osError;
	
	if (![self getFSSpec:&fsSpec]) {
		WRN2(@"FSSpec get error(%@,err=%d)", self, osError);
		return NO;
	}

	fInfo->fdFlags = 0;
	osError = FSpGetFInfo(&fsSpec, fInfo);
	if (osError != noErr) {
		WRN2(@"FInfo get error(%@,err=%d)", self, osError);
		return NO;
	}

	return YES;
}

@end
