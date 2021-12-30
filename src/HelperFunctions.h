/*============================================================================*
 * (C) 2001-2003 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: HelperFunctions.h
 *	Module		: �w���p�[�֐�	
 *	Description	: OS X 10.1���T�|�[�g���邽�߂ɁA10.2�݂̂ɑ��݂���֐��̃��b�p�[���`
 *============================================================================*/

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// ��������g�[�N���ɕ�������
extern char* IPMtokenize(char* str, const char* delim, char** ptr);

// 64bit���l�𕶎���ɕϊ�����
extern NSString* IPMstringWithULL(unsigned long long value);

// �������64bit���l�ɕϊ�����
extern unsigned long long IPMstrtoull(const char* ptr, char** endPtr, int base);

#ifdef __cplusplus
}	// extern "C"
#endif
