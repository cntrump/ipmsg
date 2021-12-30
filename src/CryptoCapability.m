/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: CryptoCapability.m
 *	Module		: 暗号化能力情報クラス
 *============================================================================*/

#import "CryptoCapability.h"
#import "DebugLog.h"

@implementation CryptoCapability

/*----------------------------------------------------------------------------*/
#pragma mark - プロパティアクセス
/*----------------------------------------------------------------------------*/

// 暗号化機能利用可否
- (BOOL)supportEncryption
{
	if (!self.supportAES256 && !self.supportBlowfish128) {
		// 共通鍵暗号が使えないためNG
		return NO;
	}
	if (!self.supportRSA2048 && !self.supportRSA1024) {
		// 公開鍵暗号が使えないためNG
		return NO;
	}
	return YES;
}

// 公開鍵指紋機能利用可否
- (BOOL)supportFingerPrint
{
	return (self.supportRSA2048 && self.supportSignSHA1);
}

/*----------------------------------------------------------------------------*/
#pragma mark - 公開メソッド
/*----------------------------------------------------------------------------*/

// 指定の条件と合致する（利用可能な）暗号化能力情報を返す
- (instancetype)capabilityMatchedWith:(CryptoCapability*)otherObj
{
	typeof(self) newObj = [[[self.class alloc] init] autorelease];
	// 共通鍵暗号
	newObj.supportBlowfish128	= self.supportBlowfish128 && otherObj.supportBlowfish128;
	newObj.supportAES256		= self.supportAES256 && otherObj.supportAES256;
	// 公開鍵暗号
	newObj.supportRSA1024		= self.supportRSA1024 && otherObj.supportRSA1024;
	newObj.supportRSA2048		= self.supportRSA2048 && otherObj.supportRSA2048;
	// オプション
	newObj.supportPacketNoIV	= self.supportPacketNoIV && otherObj.supportPacketNoIV;
	newObj.supportEncodeBase64	= self.supportEncodeBase64 && otherObj.supportEncodeBase64;
	newObj.supportSignSHA1		= self.supportSignSHA1 && otherObj.supportSignSHA1;
	newObj.supportSignSHA256	= self.supportSignSHA256 && otherObj.supportSignSHA256;

	return newObj;
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSObject
/*----------------------------------------------------------------------------*/

// 概要
- (NSString*)description
{
	return [NSString stringWithFormat:@"CryptoCompatibylity[Encryption=%s,FingerPrint=%s]("
										@"AES256=%s,Blowfish128=%s,"
										@"RSA2048=%s,RSA1024=%s,"
										@"packetNoIV=%s,Base64=%s,signSHA256=%s,signSHA1=%s)",
										BOOLSTR(self.supportEncryption),
										BOOLSTR(self.supportFingerPrint),
										BOOLSTR(self.supportAES256),
										BOOLSTR(self.supportBlowfish128),
										BOOLSTR(self.supportRSA2048),
										BOOLSTR(self.supportRSA1024),
										BOOLSTR(self.supportPacketNoIV),
										BOOLSTR(self.supportEncodeBase64),
										BOOLSTR(self.supportSignSHA256),
										BOOLSTR(self.supportSignSHA1)];
}


@end
