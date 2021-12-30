/*============================================================================*
 * (C) 2001-2003 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: HelperFunctions.m
 *	Module		: ヘルパー関数	
 *	Description	: OS X 10.1をサポートするために、10.2のみに存在する関数のラッパーを実装
 *============================================================================*/

#import "HelperFunctions.h"
#import "DebugLog.h"

// 文字列をトークンに分解する
char* IPMtokenize(char* str, const char* delim, char** ptr) {
#if MAC_OS_X_VERSION_10_2 <= MAC_OS_X_VERSION_MAX_ALLOWED
	return strtok_r(str, delim, ptr);
#else
	unsigned	len	= strlen(delim);
	char*		work = (str) ? str : *ptr;
	if (work) {
		unsigned i;
		for (i = 0; i < len; i++) {
			*ptr = strchr(work, delim[i]);
			if (*ptr) {
				// デリミタが見つかった場合
				**ptr = NULL;
				(*ptr)++;
				return work;
			}
		}
		// デリミタが見つからなかった場合
		work = NULL;
	} else {
		ERR0(@"parameter error(*ptr is NULL)");
	}
	return work;
#endif
}

// 64bit数値を16進文字列に変換する
NSString* IPMstringWithULL(unsigned long long value) {
#if MAC_OS_X_VERSION_10_2 <= MAC_OS_X_VERSION_MAX_ALLOWED
	return [NSString stringWithFormat:@"%llX", value];
#else
	unsigned long upper = (unsigned long)((value >> 32) & 0xFFFFFFFF);
	unsigned long lower = (unsigned long)(value & 0xFFFFFFFF);
	if (upper) {
		return [NSString stringWithFormat:@"%X%08X", upper, lower];
	}
	return [NSString stringWithFormat:@"%X", lower];
#endif
}

// 文字列を64bit数値に変換する
//（OS X 10.1用の部分はかなり簡略化、エラーケースを考えない）
unsigned long long IPMstrtoull(const char* ptr, char** endPtr, int base) {
#if MAC_OS_X_VERSION_10_2 <= MAC_OS_X_VERSION_MAX_ALLOWED
	return strtoull(ptr, endPtr, base);
#else
	unsigned len = strlen(ptr);
	if (base != 16) {
		ERR1(@"parameter error:base=%d", base);
		return 0;
	}
	if (len > 8) {
		char upper[9];
		char lower[9];
		strncpy(upper, ptr, len - 8);
		strncpy(lower, &ptr[len - 8], 8);
		return (((unsigned long long)strtoul(upper, NULL, 16)) << 32) + strtoul(lower, NULL, 16);
	}
	return (unsigned long long)strtoul(ptr, NULL, 16);
#endif
}