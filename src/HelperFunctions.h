/*============================================================================*
 * (C) 2001-2003 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: HelperFunctions.h
 *	Module		: ヘルパー関数	
 *	Description	: OS X 10.1をサポートするために、10.2のみに存在する関数のラッパーを定義
 *============================================================================*/

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// 文字列をトークンに分解する
extern char* IPMtokenize(char* str, const char* delim, char** ptr);

// 64bit数値を文字列に変換する
extern NSString* IPMstringWithULL(unsigned long long value);

// 文字列を64bit数値に変換する
extern unsigned long long IPMstrtoull(const char* ptr, char** endPtr, int base);

#ifdef __cplusplus
}	// extern "C"
#endif
