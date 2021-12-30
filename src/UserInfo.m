/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: UserInfo.m
 *	Module		: ユーザ情報クラス
 *============================================================================*/

#import "UserInfo.h"
#import "RSAPublicKey.h"
#import "NSData+IPMessenger.h"
#import "DebugLog.h"

#include <arpa/inet.h>

NSString* const kIPMsgUserInfoUserNamePropertyIdentifier	= @"UserName";
NSString* const kIPMsgUserInfoGroupNamePropertyIdentifier	= @"GroupName";
NSString* const kIPMsgUserInfoHostNamePropertyIdentifier	= @"HostName";
NSString* const kIPMsgUserInfoLogOnNamePropertyIdentifier	= @"LogOnName";
NSString* const kIPMsgUserInfoVersionPropertyIdentifer		= @"Version";
NSString* const kIPMsgUserInfoIPAddressPropertyIdentifier	= @"IPAddress";

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation UserInfo

//*---------------------------------------------------------------------------*
#pragma mark - クラスメソッド
//*---------------------------------------------------------------------------*

// ファクトリ
+ (instancetype)userWithHostName:(NSString*)host
					   logOnName:(NSString*)logOn
						 address:(struct sockaddr_in*)addr
{
	return [[[UserInfo alloc] initWithHostName:host
									 logOnName:logOn
									   address:addr] autorelease];
}

//*---------------------------------------------------------------------------*
#pragma mark - 初期化／解放
//*---------------------------------------------------------------------------*

// 初期化
- (instancetype)initWithHostName:(NSString*)host
					   logOnName:(NSString*)logOn
						 address:(struct sockaddr_in*)addr
{
	self = [super init];
	if (self) {
		_hostName	= [host copy];
		_logOnName	= [logOn copy];
		_address	= *addr;
		_ipAddress	= [[NSString alloc] initWithUTF8String:inet_ntoa(addr->sin_addr)];
		if ([_logOnName containsString:@"-<"]) {
			NSArray<NSString*>* comp = [_logOnName componentsSeparatedByString:@"-<"];
			if (comp.count == 2) {
				if ((comp[1].length == 17) && ([comp[1] characterAtIndex:16] == '>')) {
					NSString* str = [[comp[1] substringToIndex:16] retain];
					_fingerPrint = [[NSData alloc] initWithHexEncodedString:str];
				}
			}
		}
	}
	return self;
}

// 解放
- (void)dealloc
{
	[_hostName release];
	[_logOnName release];
	[_fingerPrint release];
	[_ipAddress release];
	[_userName release];
	[_groupName release];
	[_cryptoCapability release];
	[_publicKey release];
	[_version release];
	[super dealloc];
}

//*---------------------------------------------------------------------------*
#pragma mark - プロパティアクセス
//*---------------------------------------------------------------------------*

// 表示文字列
- (NSString*)summaryString
{
	NSMutableString* desc = [NSMutableString string];

	// ユーザ名
	if (self.userName.length > 0) {
		[desc appendString:self.userName];
		// ログオン名
//		[desc appendFormat:@"[%@]", self.logOnName];
	} else {
		[desc appendString:self.logOnName];
	}

	// 不在マーク
	if (self.inAbsence) {
		[desc appendString:@"*"];
	}

	[desc appendString:@" ("];

	// グループ名
	if (self.groupName.length > 0) {
		[desc appendFormat:@"%@/", self.groupName];
	}

	// マシン名
	[desc appendString:self.hostName];

	// IPアドレス
//	[desc appendFormat:@"/%@", self.ipAddress]

	[desc appendString:@")"];

	return desc;
}

//*---------------------------------------------------------------------------*
#pragma mark - NSObject
//*---------------------------------------------------------------------------*

// KVC
- (id)valueForKey:(NSString*)key
{
	if ([key isEqualToString:kIPMsgUserInfoUserNamePropertyIdentifier]) {
		return self.userName;
	} else if ([key isEqualToString:kIPMsgUserInfoGroupNamePropertyIdentifier]) {
		return self.groupName;
	} else if ([key isEqualToString:kIPMsgUserInfoHostNamePropertyIdentifier]) {
		return self.hostName;
	} else if ([key isEqualToString:kIPMsgUserInfoIPAddressPropertyIdentifier]) {
		return self.ipAddress;
	} else if ([key isEqualToString:kIPMsgUserInfoLogOnNamePropertyIdentifier]) {
		return self.logOnName;
	} else if ([key isEqualToString:kIPMsgUserInfoVersionPropertyIdentifer]) {
		return self.version;
	}
	return @"";
}

// 等価判定
- (BOOL)isEqual:(id)anObject
{
	if ([anObject isKindOfClass:self.class]) {
		typeof(self) target = anObject;
		return ([self.logOnName isEqualToString:target.logOnName] &&
				[self.hostName isEqual:target.hostName]);
	}
	return NO;
}

// オブジェクト文字列表現
- (NSString*)description
{
	return [NSString stringWithFormat:@"%@@%@", self.logOnName, self.hostName];
}

@end
