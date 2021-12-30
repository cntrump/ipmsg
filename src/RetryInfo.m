/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RetryInfo.m
 *	Module		: メッセージ再送情報クラス
 *============================================================================*/

#import "RetryInfo.h"
#import "UserInfo.h"

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation RetryInfo

/*----------------------------------------------------------------------------*
 * ファクトリ
 *----------------------------------------------------------------------------*/

+ (instancetype)infoWithPacketNo:(NSInteger)pNo
						 command:(UInt32)cmd
							  to:(UserInfo*)to
						 message:(NSString*)msg
						  option:(NSString*)opt
{
	return [[[RetryInfo alloc] initWithPacketNo:pNo
										command:cmd
											 to:to
										message:msg
										 option:opt] autorelease];
}

+ (NSString*)identifyKeyForPacketNo:(NSInteger)pNo to:(UserInfo*)to
{
	return [NSString stringWithFormat:@"%ld/%@", pNo, to.description];
}

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/

// 初期化
- (instancetype)initWithPacketNo:(NSInteger)pNo
						 command:(UInt32)cmd
							  to:(UserInfo*)to
						 message:(NSString*)msg
						  option:(NSString*)opt
{
	self = [super init];
	if (self) {
		_packetNo	= pNo;
		_command	= cmd;
		_toUser		= [to retain];
		_message	= [msg copy];
		_option		= [opt copy];
		_retryCount	= 0;
	}
	return self;
}

// 解放
- (void)dealloc
{
	[_toUser release];
	[_message release];
	[_option release];
	[super dealloc];
}

- (NSString*)identifyKey
{
	return [RetryInfo identifyKeyForPacketNo:self.packetNo to:self.toUser];
}

@end
