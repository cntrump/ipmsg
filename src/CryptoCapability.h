/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: CryptoCapability.h
 *	Module		: 暗号化能力情報クラス
 *============================================================================*/

#import <Foundation/Foundation.h>

@interface CryptoCapability : NSObject

// 機能利用可否
@property(readonly)	BOOL	supportEncryption;
@property(readonly)	BOOL	supportFingerPrint;

// 共通鍵暗号能力
@property(assign)	BOOL	supportBlowfish128;
@property(assign)	BOOL	supportAES256;
// 公開鍵暗号能力
@property(assign)	BOOL	supportRSA1024;
@property(assign)	BOOL	supportRSA2048;
// オプション
@property(assign)	BOOL	supportPacketNoIV;
@property(assign)	BOOL	supportEncodeBase64;
@property(assign)	BOOL	supportSignSHA1;
@property(assign)	BOOL	supportSignSHA256;

// 指定の条件と合致する（利用可能な）暗号化能力情報を返す
- (instancetype)capabilityMatchedWith:(CryptoCapability*)otherObj;

@end
