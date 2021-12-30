/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: CryptoManager.h
 *	Module		: 暗号化管理クラス
 *============================================================================*/

#import <Foundation/Foundation.h>
#import "CryptoCapability.h"

@class RSAPublicKey;

@interface CryptoManager : NSObject

@property(readonly)	CryptoCapability*	selfCapability;
@property(readonly)	RSAPublicKey*		publicKey2048;
@property(readonly)	RSAPublicKey*		publicKey1024;

+ (instancetype)sharedManager;

- (BOOL)startup;
- (BOOL)shutdown;

// ランダムデータ作成
- (NSData*)randomData:(size_t)byteSize;

// 公開鍵指紋作成
- (NSData*)publicKeyFingerPrintForRSA2048Modulus:(NSData*)modulus;

// 暗号化関連
- (NSData*)encryptRSA:(NSData*)srcData key:(RSAPublicKey*)key;
- (NSData*)encryptAES:(NSData*)srcData key:(NSData*)key iv:(NSData*)iv;
- (NSData*)encryptBlowfish:(NSData*)srcData key:(NSData*)key iv:(NSData*)iv;

// 復号化関連
- (NSData*)decryptRSA:(NSData*)srcData privateKeyBitSize:(UInt32)keySize;
- (NSData*)decryptAES:(NSData*)srcData key:(NSData*)key iv:(NSData*)iv;
- (NSData*)decryptBlowfish:(NSData*)srcData key:(NSData*)key iv:(NSData*)iv;

// 署名関連
- (NSData*)signSHA256:(NSData*)data privateKeyBitSize:(NSInteger)keySize;
- (NSData*)signSHA1:(NSData*)data privateKeyBitSize:(NSInteger)keySize;
- (BOOL)verifySHA256:(NSData*)data data:(NSData*)sign key:(RSAPublicKey*)key;
- (BOOL)verifySHA1:(NSData*)data data:(NSData*)sign key:(RSAPublicKey*)key;

@end
