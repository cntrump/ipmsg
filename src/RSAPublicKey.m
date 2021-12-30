/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RSAPublicKey.m
 *	Module		: RSA公開鍵情報クラス
 *============================================================================*/

#import "RSAPublicKey.h"
#import "DebugLog.h"

#import <Security/Security.h>
#import <Security/SecAsn1Coder.h>

#define _VERBOSE_DEBUG_LOG		(0)

/*============================================================================*
 * ASN.1 Encode/Decode関連定義
 *============================================================================*/

/*
 [ASN.1 RSA公開鍵フォーマット]

  RSAPublicKey ::= SEQUENCE {
	modulus         INTEGER,  -- n
	publicExponent  INTEGER   -- e
  }
 */

// RSAPublicKey
typedef struct
{
	SecAsn1Item	modulus;	// INTEGER
	SecAsn1Item	exponent;	// INTEGER

} _RSAPublicKeyData;

// RSAPublicKey(struct RSAPublicKeyData)
static const SecAsn1Template _RSAPublicKeyTemplate[] = {
	{ SEC_ASN1_SEQUENCE, 0, NULL, sizeof(_RSAPublicKeyData) },
	{ SEC_ASN1_INTEGER, offsetof(_RSAPublicKeyData, modulus), NULL, 0 },
	{ SEC_ASN1_INTEGER, offsetof(_RSAPublicKeyData, exponent), NULL, 0 },
	{ 0, 0, NULL, 0 }
};

/*============================================================================*
 * マクロ定義
 *============================================================================*/

#if _VERBOSE_DEBUG_LOG
#define	V_DBG(...)	DBG(__VA_ARGS__)
#else
#define	V_DBG(...)
#endif

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation RSAPublicKey

/*----------------------------------------------------------------------------*/
#pragma mark - クラスメソッド
/*----------------------------------------------------------------------------*/

// ファクトリ（SecKeyRef, Exp, Mod）
+ (instancetype)keyWithNativeKey:(SecKeyRef)key exponent:(UInt32)exp modulus:(NSData*)mod
{
	return [[[RSAPublicKey alloc] initWithNativeKey:key exponent:exp modulus:mod] autorelease];
}

// ファクトリ（Exp, Mod）
+ (instancetype)keyWithExponent:(UInt32)exp modulus:(NSData*)mod
{
	return [[[RSAPublicKey alloc] initWithExponent:exp modulus:mod] autorelease];
}

// ファクトリ（SecKeyRef）
+ (instancetype)keyWithNativeKey:(SecKeyRef)key
{
	return [[[RSAPublicKey alloc] initWithNativeKey:key] autorelease];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 初期化/解放
/*----------------------------------------------------------------------------*/

// 初期化（Exp, Mod）
- (instancetype)initWithNativeKey:(SecKeyRef)key exponent:(UInt32)exp modulus:(NSData*)mod
{
	self = [super init];
	if (self) {
		_nativeKey	= key;
		_exponent	= exp;
		_modulus	= [mod copy];
		CFRetain(_nativeKey);
	}
	return self;
}

// 初期化（Exp, Mod）
- (instancetype)initWithExponent:(UInt32)exp modulus:(NSData*)mod
{
	self = [super init];
	if (self) {
		SecAsn1CoderRef	encoder 	= NULL;
		CFErrorRef		error		= NULL;
		@try {
			V_DBG(@"Start Convert PublicKey to SecKeyRef");

			//-------------------------------
			// Exp,Mod -> ASN.1 DER
			//-------------------------------
			OSStatus ret = SecAsn1CoderCreate(&encoder);
			if (ret != errSecSuccess) {
				[NSException raise:@"ERROR" format:@"SecAsn1CoderCreate failed(%d)", ret];
			}

			_RSAPublicKeyData 	keyData;
			SecAsn1Item			derItem;
			memset(&keyData, 0, sizeof(keyData));
			memset(&derItem, 0, sizeof(derItem));
			// ConvertKeyData
			UInt32 networkByteOrderExp = htonl(exp);
			keyData.modulus.Data	= (uint8_t*)mod.bytes;
			keyData.modulus.Length	= mod.length;
			keyData.exponent.Data	= (uint8_t*)&networkByteOrderExp;
			keyData.exponent.Length	= sizeof(networkByteOrderExp);
			ret = SecAsn1EncodeItem(encoder, &keyData, _RSAPublicKeyTemplate, &derItem);
			if (ret != errSecSuccess) {
				[NSException raise:@"ERROR" format:@"SecAsn1EncodeItem(KeyData) failed(%d)", ret];
			}

			NSData* derData = [NSData dataWithBytesNoCopy:derItem.Data length:derItem.Length freeWhenDone:NO];
			V_DBG(@"ASN.1 DER encoed successed(%ldbytes)", derData.length);

			//-------------------------------
			// PKCS#1(ASN.1 DER) -> SecKeyRef
			//-------------------------------
			NSDictionary* publicKeyQuery =	@{
				(__bridge id)kSecAttrKeyType		: (__bridge id)kSecAttrKeyTypeRSA,
				(__bridge id)kSecAttrKeyClass		: (__bridge id)kSecAttrKeyClassPublic,
				(__bridge id)kSecAttrKeySizeInBits	: @(mod.length * 8),
				(__bridge id)kSecAttrIsPermanent	: @NO,
				(__bridge id)kSecAttrLabel 			: @"IP Messanger internal generated",
			};
			SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)derData, (__bridge CFDictionaryRef)publicKeyQuery, &error);
			if (!key) {
				[NSException raise:@"ERROR" format:@"SecKeyCopyExternalRepresentation failed(%@)", (__bridge NSError*)error];
			}
			V_DBG(@"ASN.1 DER -> SecKeyRef convert successed 2(%ldbytes)", derData.length);

			//-------------------------------
			// Setup Properties
			//-------------------------------

			_exponent	= exp;
			_modulus	= [[NSData alloc] initWithData:mod];
			_nativeKey	= key;

			V_DBG(@"Created   secKeyRef=%p", _nativeKey);
			V_DBG(@"Parameter exponent =0x%X", _exponent);
			V_DBG(@"Parameter modulus  =%ldbits,%@", _modulus.length * 8, _modulus);

			V_DBG(@"Finish Convert PublicKey to SecKeyRef");
		}
		@catch(NSException* exp) {
			ERR(@"Convert Exp&Mod -> SefKeyRef error:%@", exp);
			if (error) {
				CFRelease(error);
			}
		}
		@finally {
			if (encoder) {
				SecAsn1CoderRelease(encoder);
			}
		}
	}
	return self;
}

// 初期化（SecKeyRef）
- (instancetype)initWithNativeKey:(SecKeyRef)key
{
	self = [super init];
	if (self) {
		SecAsn1CoderRef	decoder = NULL;
		CFErrorRef		error	= NULL;
		@try {
			V_DBG(@"Start Convert SecKeyRef to PublicKey");

			//-------------------------------
			// SecKeyRef -> PKCS#1(ASN.1 DER)
			//-------------------------------
			CFDataRef derRef = SecKeyCopyExternalRepresentation(key, &error);
			if (!derRef) {
				[NSException raise:@"ERROR" format:@"SecKeyCopyExternalRepresentation failed(%@)", (__bridge NSError*)error];
			}
			NSData* derData = (__bridge NSData*)derRef;
			[derData autorelease];
			V_DBG(@"ASN.1 DER export successed 2(%ldbytes)", derData.length);

			//-------------------------------
			// ASN.1 DER Decode
			//-------------------------------
			OSStatus ret = SecAsn1CoderCreate(&decoder);
			if (ret != errSecSuccess) {
				[NSException raise:@"ERROR" format:@"SecAsn1CoderCreate failed(%d)", ret];
			}

			_RSAPublicKeyData keyData;
			memset(&keyData, 0, sizeof(keyData));
			ret = SecAsn1Decode(decoder, derData.bytes, derData.length, _RSAPublicKeyTemplate, &keyData);
			if (ret != errSecSuccess) {
				[NSException raise:@"ERROR" format:@"SecAsn1DecodeData failed(%d)", ret];
			}
			V_DBG(@"ASN.1 RSAPublicKey decode");

			//-------------------------------
			// Setup Properties
			//-------------------------------
			NSUInteger exp = 0;
			for (size_t i = 0; i < keyData.exponent.Length; i++) {
				exp = (exp << 8) | keyData.exponent.Data[i];
			}
			if (exp > UINT32_MAX) {
				[NSException raise:@"ERROR" format:@"Exponent overflow(0x%lX)", exp];
			}

			_exponent	= (UInt32)exp;
			_modulus	= [[NSData alloc] initWithBytes:keyData.modulus.Data length:keyData.modulus.Length];
			_nativeKey	= key;
			CFRetain(_nativeKey);

			V_DBG(@"Parameter     secKeyRef=%p", _nativeKey);
			V_DBG(@"ASN.1 decoded exponent =0x%X", _exponent);
			V_DBG(@"ASN.1 decoded modulus  =%ldbits,%@", _modulus.length * 8, _modulus);

			V_DBG(@"Finish Convert SecKeyRef to PublicKey");
		}
		@catch (NSException* exp) {
			ERR(@"SecKeyRef convert error:%@", exp);
			if (error) {
				CFRelease(error);
			}
			[self release];
			return nil;
		}
		@finally {
			if (decoder) {
				SecAsn1CoderRelease(decoder);
			}
		}
	}
	return self;
}

// 解放
- (void)dealloc
{
	if (_nativeKey) {
		CFRelease(_nativeKey);
	}
	[_modulus release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*/
#pragma mark - プロパティアクセス
/*----------------------------------------------------------------------------*/

// 鍵長
- (NSInteger)keySizeInBits
{
	return self.modulus.length * 8;
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSObject
/*----------------------------------------------------------------------------*/

// 概要
- (NSString*)description
{
	return [NSString stringWithFormat:@"RSAPublicKey(exp=%X,mod=%ldbits)", self.exponent, self.keySizeInBits];
}

@end
