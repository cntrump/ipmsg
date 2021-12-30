/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: CryptoManager.m
 *	Module		: 暗号化管理クラス
 *============================================================================*/

#import "CryptoManager.h"
#import "RSAPublicKey.h"
#import "Config.h"
#import "NSData+IPMessenger.h"
#import "DebugLog.h"

#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>

#define _VERBOSE_DEBUG_LOG		(1)

/*============================================================================*
 * 定数/マクロ定義
 *============================================================================*/

#define _KEYCHAIN_KEY_LABEL		@"IP Messenger Encryption Key"
#define _KEYCHAIN_KEY_COMMENT	@"Generated by IP Messegner for macOS."

#if _VERBOSE_DEBUG_LOG
#define	V_DBG(...)	DBG(__VA_ARGS__)
#else
#define	V_DBG(...)
#endif

/*============================================================================*
 * 内部クラス拡張
 *============================================================================*/

@interface CryptoManager()

@property(retain)	RSAPublicKey*	publicKey2048;
@property(retain)	RSAPublicKey*	publicKey1024;
@property(assign)	SecKeyRef		privateKey2048;
@property(assign)	SecKeyRef		privateKey1024;

- (NSData*)signWithAlgorithm:(SecKeyAlgorithm)algorithm data:(NSData*)data keySize:(NSInteger)keySize;
- (BOOL)verifySign:(NSData*)sign algorithm:(SecKeyAlgorithm)algorithm data:(NSData*)data key:(RSAPublicKey*)key;

@end

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation CryptoManager

/*----------------------------------------------------------------------------*/
#pragma mark - クラスメソッド
/*----------------------------------------------------------------------------*/

// ファクトリ
+ (instancetype)sharedManager
{
	static CryptoManager*	sharedInstance = nil;
	static dispatch_once_t	once;
	dispatch_once(&once, ^{
		sharedInstance = [[CryptoManager alloc] init];
	});
	return sharedInstance;
}

/*----------------------------------------------------------------------------*/
#pragma mark - 初期化/解放
/*----------------------------------------------------------------------------*/

// 初期化
- (instancetype)init
{
	self = [super init];
	if (self) {
		_selfCapability = [[CryptoCapability alloc] init];
		_selfCapability.supportAES256		= YES;
		_selfCapability.supportBlowfish128	= YES;
		_selfCapability.supportRSA2048		= YES;
		_selfCapability.supportRSA1024		= YES;
		_selfCapability.supportPacketNoIV	= YES;
		_selfCapability.supportEncodeBase64	= YES;
		_selfCapability.supportSignSHA256	= YES;
		_selfCapability.supportSignSHA1		= YES;
	}

	return self;
}

// 解放
- (void)dealloc
{
	[_selfCapability release];
	[_publicKey2048 release];
	[_publicKey1024 release];
	if (_privateKey2048) {
		CFRelease(_privateKey2048);
	}
	if (_privateKey1024) {
		CFRelease(_privateKey1024);
	}
	[super dealloc];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 起動/終了
/*----------------------------------------------------------------------------*/

// 起動
- (BOOL)startup
{
	// RSA2048
	if (self.selfCapability.supportRSA2048) {
		// セットアップ
		if (![self setupKeyPairForSizeInBits:2048]) {
			ERR(@"Failed Generate KeyPair for RSA2048. -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 公開鍵：暗号化可否チェック
		else if (!SecKeyIsAlgorithmSupported(self.publicKey2048.nativeKey,
											 kSecKeyOperationTypeEncrypt,
											 kSecKeyAlgorithmRSAEncryptionPKCS1)) {
			ERR(@"RSA2048 PublicKey not support Encryption -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 秘密鍵：復号化可否チェック
		else if (!SecKeyIsAlgorithmSupported(self.privateKey2048,
											 kSecKeyOperationTypeDecrypt,
											 kSecKeyAlgorithmRSAEncryptionPKCS1)) {
			ERR(@"RSA2048 PrivateKey not support Decryption -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 秘密鍵：署名可否チェック
		else if (!SecKeyIsAlgorithmSupported(self.privateKey2048,
											 kSecKeyOperationTypeSign,
											 kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA1)) {
			ERR(@"RSA2048 PrivateKey not support Sign SHA1 -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		else if (!SecKeyIsAlgorithmSupported(self.privateKey2048,
											 kSecKeyOperationTypeSign,
											 kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256)) {
			ERR(@"RSA2048 PrivateKey not support Sign SHA256 -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 公開鍵：検証可否チェック
		else if (!SecKeyIsAlgorithmSupported(self.publicKey2048.nativeKey,
											 kSecKeyOperationTypeVerify,
											 kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA1)) {
			ERR(@"RSA2048 PublicKey not support Verify SHA1 -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		else if (!SecKeyIsAlgorithmSupported(self.publicKey2048.nativeKey,
											 kSecKeyOperationTypeVerify,
											 kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256)) {
			ERR(@"RSA2048 PublicKey not support Verify SHA256 -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 利用可能
		else {
			DBG(@"RSA2048 KeyPair setup succeeded");
		}
	}

	// RSA1024
	if (self.selfCapability.supportRSA1024) {
		if (![self setupKeyPairForSizeInBits:1024]) {
			ERR(@"Failed Generate KeyPair for RSA1024. -> disable");
			self.selfCapability.supportRSA1024 = NO;
		}
		// 公開鍵：暗号化可否チェック
		else if (!SecKeyIsAlgorithmSupported(self.publicKey1024.nativeKey,
											 kSecKeyOperationTypeEncrypt,
											 kSecKeyAlgorithmRSAEncryptionPKCS1)) {
			ERR(@"RSA1024 PublicKey not support Encryption -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 秘密鍵：復号化可否チェック
		else if (!SecKeyIsAlgorithmSupported(self.privateKey1024,
											 kSecKeyOperationTypeDecrypt,
											 kSecKeyAlgorithmRSAEncryptionPKCS1)) {
			ERR(@"RSA1024 PrivateKey not support Decryption -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 秘密鍵：署名可否チェック
		else if (!SecKeyIsAlgorithmSupported(self.privateKey1024,
											 kSecKeyOperationTypeSign,
											 kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA1)) {
			ERR(@"RSA1024 PrivateKey not support Sign SHA1 -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		else if (!SecKeyIsAlgorithmSupported(self.privateKey1024,
											 kSecKeyOperationTypeSign,
											 kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256)) {
			ERR(@"RSA1024 PrivateKey not support Sign SHA256 -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 公開鍵：検証可否チェック
		else if (!SecKeyIsAlgorithmSupported(self.publicKey1024.nativeKey,
											 kSecKeyOperationTypeVerify,
											 kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA1)) {
			ERR(@"RSA1024 PUblicKey not support Verify SHA1 -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		else if (!SecKeyIsAlgorithmSupported(self.publicKey1024.nativeKey,
											 kSecKeyOperationTypeVerify,
											 kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256)) {
			ERR(@"RSA1024 PublicKey not support Verify SHA256 -> disable");
			self.selfCapability.supportRSA2048 = NO;
		}
		// 利用可能
		else {
			DBG(@"RSA1024 KeyPair setup succeeded");
		}
	}

	return YES;
}

// 終了
- (BOOL)shutdown
{
	return YES;
}

/*----------------------------------------------------------------------------*/
#pragma mark - 乱数
/*----------------------------------------------------------------------------*/

// ランダムデータ生成
- (NSData*)randomData:(size_t)byteSize
{
	UInt8 buffer[byteSize];

	int ret = SecRandomCopyBytes(kSecRandomDefault, byteSize, buffer);
	if (ret != errSecSuccess) {
		ERR(@"SecureRandomData copy error(%d)", ret);
		return nil;
	}

	return [NSData dataWithBytes:buffer length:byteSize];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 公開鍵指紋
/*----------------------------------------------------------------------------*/

// 公開鍵指紋作成
- (NSData*)publicKeyFingerPrintForRSA2048Modulus:(NSData*)modulus
{
	NSParameterAssert(modulus != nil);

	if (modulus.length != 2048/8) {
		ERR(@"Parameter moduls not 2048bit(%ldbit)", modulus.length * 8);
		return nil;
	}

	// 反転バイト列作成（Windows版との互換性のため）
	NSData* reversedModulus = [modulus dataWithReversedBytes];

	// SHA1ダイジェスト作成
	UInt8 digestWork[CC_SHA1_DIGEST_LENGTH + 4];
	memset(digestWork, 0, sizeof(digestWork));
	CC_SHA1(reversedModulus.bytes, (CC_LONG)reversedModulus.length, digestWork);
	NSData* digestData		= [NSData dataWithBytesNoCopy:digestWork length:sizeof(digestWork) freeWhenDone:NO];

	// SHA1ダイジェスト反転（Windows版との互換性のため）
	NSData* digestRevData	= [digestData dataWithReversedBytesInRange:NSMakeRange(0, CC_SHA1_DIGEST_LENGTH)];

	// 指紋バイナリ作成
	UInt8 	fingerPrint[8];
	UInt64*	input0	= (UInt64*)&digestRevData.bytes[0];
	UInt64*	input1	= (UInt64*)&digestRevData.bytes[8];
	UInt64* input2	= (UInt64*)&digestRevData.bytes[16];
	UInt64* outBuf	= (UInt64*)&fingerPrint[0];
	*outBuf = *input0 ^ *input1 ^ *input2;

	return [NSData dataWithBytes:fingerPrint length:8];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 暗号化
/*----------------------------------------------------------------------------*/

// RSA暗号化
- (NSData*)encryptRSA:(NSData*)srcData key:(RSAPublicKey*)key
{
	NSParameterAssert(srcData != nil);
	NSParameterAssert(key != nil);

	CFErrorRef	error		= NULL;
	CFDataRef	resultData	= NULL;
	resultData = SecKeyCreateEncryptedData(key.nativeKey,
										   kSecKeyAlgorithmRSAEncryptionPKCS1,
										   (__bridge CFDataRef)srcData,
										   &error);
	if (!resultData) {
		ERR(@"EncryptError(%@)", (__bridge NSError*)error);
		CFRelease(error);
		return nil;
	}

	NSData* result = (__bridge NSData*)resultData;
	[result autorelease];

	return result;
}

// AES暗号化
- (NSData*)encryptAES:(NSData*)srcData key:(NSData*)key iv:(NSData*)iv
{
	NSParameterAssert(srcData != nil);
	NSParameterAssert(key != nil);
	NSParameterAssert(iv != nil);

	if (key.length != kCCKeySizeAES256) {
		ERR(@"AES%ld not support(only AES256 allowed)", key.length * 8);
		return nil;
	}

	size_t	bufSize	= srcData.length + kCCBlockSizeAES128;
	void*	buffer	= malloc(bufSize);
	size_t	outSize	= 0;

	CCCryptorStatus ret = CCCrypt(kCCEncrypt,
								  kCCAlgorithmAES,
								  kCCOptionPKCS7Padding,
								  key.bytes,
								  key.length,
								  iv.bytes,
								  srcData.bytes,
								  srcData.length,
								  buffer,
								  bufSize,
								  &outSize);
	if (ret != kCCSuccess) {
		ERR(@"CCCrypt(AES) failed(ret=%d)", ret);
		free(buffer);
		return nil;
	}

	return [NSData dataWithBytesNoCopy:buffer length:outSize freeWhenDone:YES];
}

// Blowfish暗号化
- (NSData*)encryptBlowfish:(NSData*)srcData key:(NSData*)key iv:(NSData*)iv
{
	NSParameterAssert(srcData != nil);
	NSParameterAssert(key != nil);
	NSParameterAssert(iv != nil);

	if (key.length != 128/8) {
		ERR(@"Blowfish%ld not support(only Blowfish128 allowed)", key.length * 8);
		return nil;
	}

	size_t	bufSize	= srcData.length + kCCBlockSizeBlowfish;
	void*	buffer	= malloc(bufSize);
	size_t	outSize	= 0;

	CCCryptorStatus ret = CCCrypt(kCCEncrypt,
								  kCCAlgorithmBlowfish,
								  kCCOptionPKCS7Padding,
								  key.bytes,
								  key.length,
								  iv.bytes,
								  srcData.bytes,
								  srcData.length,
								  buffer,
								  bufSize,
								  &outSize);
	if (ret != kCCSuccess) {
		ERR(@"CCCrypt(Blowfish) failed(ret=%d)", ret);
		free(buffer);
		return nil;
	}

	return [NSData dataWithBytesNoCopy:buffer length:outSize freeWhenDone:YES];
	return nil;
}

/*----------------------------------------------------------------------------*/
#pragma mark - 復号化
/*----------------------------------------------------------------------------*/

// RSA復号化
- (NSData*)decryptRSA:(NSData*)srcData privateKeyBitSize:(UInt32)keySize;
{
	NSParameterAssert(srcData != nil);

	SecKeyRef privateKey = nil;
	switch (keySize) {
	case 2048:
		privateKey = self.privateKey2048;
		break;
	case 1024:
		privateKey = self.privateKey1024;
		break;
	default:
		ERR(@"Unsupported keySize(%d)", keySize);
		return nil;
	}

	CFErrorRef	error		= NULL;
	CFDataRef	resultData	= NULL;
	resultData = SecKeyCreateDecryptedData(privateKey,
										   kSecKeyAlgorithmRSAEncryptionPKCS1,
										   (__bridge CFDataRef)srcData,
										   &error);
	if (!resultData) {
		ERR(@"DecryptError(%@)", (__bridge NSError*)error);
		CFRelease(error);
		return nil;
	}

	NSData* result = (__bridge NSData*)resultData;
	[result autorelease];
	return result;
}

// AES復号化
- (NSData*)decryptAES:(NSData*)srcData key:(NSData*)key iv:(NSData*)iv
{
	NSParameterAssert(srcData != nil);
	NSParameterAssert(key != nil);
	NSParameterAssert(iv != nil);

	if (key.length != kCCKeySizeAES256) {
		ERR(@"AES%ld not support(only AES256 allowed)", key.length * 8);
		return nil;
	}

	size_t	bufSize	= srcData.length + kCCBlockSizeAES128;
	void*	buffer	= malloc(bufSize);
	size_t	outSize	= 0;

	CCCryptorStatus ret = CCCrypt(kCCDecrypt,
								  kCCAlgorithmAES,
								  kCCOptionPKCS7Padding,
								  key.bytes,
								  key.length,
								  iv.bytes,
								  srcData.bytes,
								  srcData.length,
								  buffer,
								  bufSize,
								  &outSize);
	if (ret != kCCSuccess) {
		ERR(@"CCCrypt(AES) failed(ret=%d)", ret);
		free(buffer);
		return nil;
	}

	return [NSData dataWithBytesNoCopy:buffer length:outSize freeWhenDone:YES];
}

// Blowfish復号化
- (NSData*)decryptBlowfish:(NSData*)srcData key:(NSData*)key iv:(NSData*)iv
{
	NSParameterAssert(srcData != nil);
	NSParameterAssert(key != nil);
	NSParameterAssert(iv != nil);

	if (key.length != 128/8) {
		ERR(@"Blowfish%ld not support(only Browfish128 allowed)", key.length * 8);
		return nil;
	}

	size_t	bufSize	= srcData.length + kCCBlockSizeBlowfish;
	void*	buffer	= malloc(bufSize);
	size_t	outSize	= 0;

	CCCryptorStatus ret = CCCrypt(kCCDecrypt,
								  kCCAlgorithmBlowfish,
								  kCCOptionPKCS7Padding,
								  key.bytes,
								  key.length,
								  iv.bytes,
								  srcData.bytes,
								  srcData.length,
								  buffer,
								  bufSize,
								  &outSize);
	if (ret != kCCSuccess) {
		ERR(@"CCCrypt(Blowfish) failed(ret=%d)", ret);
		free(buffer);
		return nil;
	}

	return [NSData dataWithBytesNoCopy:buffer length:outSize freeWhenDone:YES];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 署名
/*----------------------------------------------------------------------------*/

// 署名作成（SHA256）
- (NSData*)signSHA256:(NSData*)data privateKeyBitSize:(NSInteger)keySize;
{
	return [self signWithAlgorithm:kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256
							  data:data
						   keySize:keySize];
}

// 署名作成（SHA1）
- (NSData*)signSHA1:(NSData*)data privateKeyBitSize:(NSInteger)keySize;
{
	return [self signWithAlgorithm:kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA1
							  data:data
						   keySize:keySize];
}

// 署名作成（内部利用）
- (NSData*)signWithAlgorithm:(SecKeyAlgorithm)algorithm data:(NSData*)data keySize:(NSInteger)keySize;
{
	NSParameterAssert(data != nil);

	// 秘密鍵決定
	SecKeyRef	privateKey	= NULL;
	switch (keySize) {
	case 2048:
		privateKey = self.privateKey2048;
		break;
	case 1024:
		privateKey = self.privateKey1024;
		break;
	default:
		ERR(@"invalid privateKeyBitSize(%ld)", keySize);
		return nil;
	}

	// 署名
	CFErrorRef	error		= NULL;
	CFDataRef	resultData	= NULL;
	resultData = SecKeyCreateSignature(privateKey,
									   algorithm,
									   (__bridge CFDataRef)data,
									   &error);
	if (!resultData) {
		ERR(@"CreateSignature Error(algo=%@,%@)", (__bridge NSString*)algorithm, (__bridge NSError*)error);
		CFRelease(error);
		return nil;
	}

	NSData* result = (__bridge NSData*)resultData;
	[result autorelease];
	return result;
}

// 署名検証（SHA256）
- (BOOL)verifySHA256:(NSData*)sign data:(NSData*)data key:(RSAPublicKey*)key
{
	return [self verifySign:sign
				  algorithm:kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256
					   data:data
						key:key];
}

// 署名検証（SHA1）
- (BOOL)verifySHA1:(NSData*)sign data:(NSData*)data key:(RSAPublicKey*)key
{
	return [self verifySign:sign
				  algorithm:kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA1
					   data:data
						key:key];
}

// 署名検証（内部利用）
- (BOOL)verifySign:(NSData*)sign algorithm:(SecKeyAlgorithm)algorithm data:(NSData*)data key:(RSAPublicKey*)key
{
	NSParameterAssert(data != nil);

	CFErrorRef	error	= NULL;
	Boolean result = SecKeyVerifySignature(key.nativeKey,
										   algorithm,
										   (__bridge CFDataRef)data,
										   (__bridge CFDataRef)sign,
										   &error);
	if (!result) {
		ERR(@"VerifySignature Error(algo=%@,%@)", (__bridge NSString*)algorithm, (__bridge NSError*)error);
		CFRelease(error);
		return NO;
	}

	return YES;
}

/*----------------------------------------------------------------------------*/
#pragma mark - 内部利用
/*----------------------------------------------------------------------------*/

// 公開鍵暗号 鍵ペア用意
- (BOOL)setupKeyPairForSizeInBits:(NSInteger)bitSize;
{
	NSParameterAssert((bitSize == 1024) || (bitSize == 2048));

	V_DBG(@"Start Setup RSA%ld key pair", bitSize);

	SecKeyRef	publicKey	= NULL;
	SecKeyRef	privateKey	= NULL;
	CFErrorRef	error		= NULL;

	@try {
		NSString*	keyLabel	= _KEYCHAIN_KEY_LABEL;
		NSData*		keyComment	= [_KEYCHAIN_KEY_COMMENT dataUsingEncoding:NSUTF8StringEncoding];
		CFTypeRef	returnRef;
		OSStatus 	ret;

		// 秘密鍵取得（検索→なければ生成）
		NSDictionary* privateKeyQuery =	@{
			(__bridge id)kSecClass				: (__bridge id)kSecClassKey,
			(__bridge id)kSecAttrKeyType		: (__bridge id)kSecAttrKeyTypeRSA,
			(__bridge id)kSecAttrKeyClass		: (__bridge id)kSecAttrKeyClassPrivate,
			(__bridge id)kSecAttrKeySizeInBits	: @(bitSize),
			(__bridge id)kSecAttrLabel 			: keyLabel,
			(__bridge id)kSecAttrApplicationTag	: keyComment,
			(__bridge id)kSecReturnRef			: @YES,
		};
		returnRef = NULL;
		ret = SecItemCopyMatching((__bridge CFDictionaryRef)privateKeyQuery, &returnRef);
		if (ret != errSecSuccess) {
			if (ret != errSecItemNotFound) {
				[NSException raise:@"ERROR" format:@"SecItemCopyMatching(PrivateKey) failed(%d)", ret];
			}
			V_DBG(@"RSA%ld PrivateKey not exist in KeyChain", bitSize);
		} else if (!returnRef) {
			[NSException raise:@"ERROR" format:@"SecItemCopyMatching(PrivateKey) failed(returned NULL)"];
		} else if (CFGetTypeID(returnRef) != SecKeyGetTypeID()) {
			[NSException raise:@"ERROR" format:@"SecItemCopyMatching(PrivateKey) failed(not SecKeyRef)"];
		} else {
			privateKey = (SecKeyRef)returnRef;
			V_DBG(@"RSA%ld PrivateKey exist(%p)", bitSize, privateKey);
		}

		// 公開鍵取得（取得→変換）
		if (!privateKey) {
			// まだ鍵がないので生成
			DBG(@"Generate New RSA%ld KeyPair(not exist)", bitSize);
			NSDictionary* keyAttr =	@{
				(__bridge id)kSecAttrKeyType		: (__bridge id)kSecAttrKeyTypeRSA,
				(__bridge id)kSecAttrKeySizeInBits	: @(bitSize),
				(__bridge id)kSecAttrIsPermanent	: @YES,
				(__bridge id)kSecAttrIsExtractable	: @YES,
				(__bridge id)kSecAttrAccessible		: (__bridge id)kSecAttrAccessibleWhenUnlocked,
				(__bridge id)kSecAttrLabel			: keyLabel,
				(__bridge id)kSecAttrApplicationTag	: keyComment,
			};
			privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)keyAttr, &error);
			if (!privateKey) {
				[NSException raise:@"ERROR" format:@"SecKeyCreateRandomKey failed(%@)", (__bridge NSError*)error];
			}
			V_DBG(@"Generate RSA%ld Private Key succeeded", bitSize);
		}
		// 公開鍵生成
		publicKey = SecKeyCopyPublicKey(privateKey);
		if (!publicKey) {
			[NSException raise:@"ERROR" format:@"SecKeyCopyPublicKey failed"];
		}
		V_DBG(@"RSA%ld PublicKey copied", bitSize);

		// 公開鍵変換
		RSAPublicKey* convertedKey = [RSAPublicKey keyWithNativeKey:publicKey];
		if (!convertedKey) {
			// 変換（SecKeyCreateWithData）に失敗するケースが頻繁にあるので、
			// 記憶しておいたExp,Mod（秘密鍵生成初回はうまくいく）で公開鍵を生成
			// ※失敗するのはXcodeから起動したデバッグビルドだけという情報もあり
			WRN(@"RSA%ld PublicKey conversion failed -> Create with Config data", bitSize);
			Config* cfg = Config.sharedConfig;
			UInt32 	exp	= (bitSize == 2048) ? cfg.rsa2048PublicKeyExponent : cfg.rsa1024PublicKeyExponent;
			NSData*	mod	= (bitSize == 2048) ? cfg.rsa2048PublicKeyModulus : cfg.rsa2048PublicKeyModulus;
			convertedKey = [RSAPublicKey keyWithNativeKey:publicKey exponent:exp modulus:mod];
			if (!convertedKey) {
				[NSException raise:@"ERROR" format:@"RSA%ld PublicKey Create error(exp=%x,mod=%@)", bitSize, exp, mod];
			}
		} else {
			// 成功したExp,Modを記憶
			V_DBG(@"RSA%ld PublicKey conversion succeeded", bitSize);
			Config* cfg = Config.sharedConfig;
			switch (bitSize) {
			case 2048:
				cfg.rsa2048PublicKeyExponent	= convertedKey.exponent;
				cfg.rsa2048PublicKeyModulus		= convertedKey.modulus;
				break;
			case 1024:
				cfg.rsa1024PublicKeyExponent	= convertedKey.exponent;
				cfg.rsa1024PublicKeyModulus		= convertedKey.modulus;
				break;
			default:
				[NSException raise:@"ERROR" format:@"Invalid BitSize %ld(internal error)", bitSize];
			}
			// 強制終了や落ちた場合に備えていったん保存
			[cfg save];
		}
		CFRelease(publicKey);
		publicKey = NULL;

		switch (bitSize) {
		case 2048:
			self.publicKey2048	= convertedKey;
			self.privateKey2048	= privateKey;
			break;
		case 1024:
			self.publicKey1024	= convertedKey;
			self.privateKey1024	= privateKey;
			break;
		default:
			[NSException raise:@"ERROR" format:@"Invalid BitSize %ld(internal error)", bitSize];
		}

		// ここまでくれば成功
		V_DBG(@"RSA%ld KeyPair setup complete", bitSize);
	}
	@catch (NSException* exp) {
		ERR(@"RSA%ld KeyPair setup error:%@", bitSize, exp);
		if (error) {
			CFRelease(error);
		}
		if (publicKey) {
			CFRelease(publicKey);
		}
		if (privateKey) {
			CFRelease(privateKey);
		}
		return NO;
	}

	return YES;
}

@end