/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RSAPublicKey.h
 *	Module		: RSA公開鍵情報クラス
 *============================================================================*/

#import <Foundation/Foundation.h>

@interface RSAPublicKey : NSObject

@property(readonly)	NSInteger	keySizeInBits;	// キー長
@property(readonly)	UInt32		exponent;		// 指数
@property(readonly)	NSData*		modulus;		// 法
@property(readonly)	SecKeyRef	nativeKey;		// OS(SecurityFramework)鍵

+ (instancetype)keyWithNativeKey:(SecKeyRef)key exponent:(UInt32)exp modulus:(NSData*)mode;
+ (instancetype)keyWithExponent:(UInt32)exp modulus:(NSData*)mode;
+ (instancetype)keyWithNativeKey:(SecKeyRef)key;

- (instancetype)initWithNativeKey:(SecKeyRef)key exponent:(UInt32)exp modulus:(NSData*)mod;
- (instancetype)initWithExponent:(UInt32)exp modulus:(NSData*)mod;
- (instancetype)initWithNativeKey:(SecKeyRef)key;

@end
