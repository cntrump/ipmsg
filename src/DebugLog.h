/*============================================================================*
 * (C) 2001-2010 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
 *	File		: DebugLog.h
 *	Module		: デバッグログ機能		
 *	Description	: デバッグログマクロ定義
 *============================================================================*/

#include <Foundation/Foundation.h>

/*============================================================================*
 * 出力フラグ
 *		IPMSG_DEBUGがメインスイッチ（定義がない場合全レベル強制OFF）
 *		※ XCodeのビルドスタイルにて定義されている
 *			・Release ビルドスタイル：出力しない（定義なし）
 *			・Debug   ビルドスタイル：出力する（定義あり）
 *============================================================================*/
 
// レベル別出力フラグ
//		0:出力しない
//		1:出力する
#define IPMSG_LOG_DBG	1
#define IPMSG_LOG_WRN	1
#define IPMSG_LOG_ERR	1

/*============================================================================*
 * デバッグレベルログ
 *============================================================================*/
 
#if defined(IPMSG_DEBUG) && (IPMSG_LOG_DBG == 1)
	#define _LOG_DBG		@"D ",__FILE__,__LINE__
	#define DBG0(fmt)		IPMsgLog(_LOG_DBG,fmt)
	#define DBG(fmt, ...)	IPMsgLog(_LOG_DBG,[NSString stringWithFormat:fmt,__VA_ARGS__])
#else
	#define DBG(fmt, ...)
	#define DBG0(fmt)
#endif

/*============================================================================*
 * 警告レベルログ
 *============================================================================*/

#if defined(IPMSG_DEBUG) && (IPMSG_LOG_WRN == 1)
	#define _LOG_WRN		@"W-",__FILE__,__LINE__
	#define WRN0(fmt)		IPMsgLog(_LOG_WRN,fmt)
	#define WRN(fmt, ...)	IPMsgLog(_LOG_WRN,[NSString stringWithFormat:fmt,__VA_ARGS__])
#else
	#define WRN0(fmt)
	#define WRN(fmt, ...)
#endif

/*============================================================================*
 * エラーレベルログ
 *============================================================================*/
 
#if defined(IPMSG_DEBUG) && (IPMSG_LOG_ERR == 1)
	#define _LOG_ERR		@"E*",__FILE__,__LINE__
	#define ERR0(fmt)		IPMsgLog(_LOG_ERR,fmt)
	#define ERR(fmt, ...)	IPMsgLog(_LOG_ERR,[NSString stringWithFormat:fmt,__VA_ARGS__])
#else
	#define ERR0(fmt)
	#define ERR(fmt, ...)
#endif

/*============================================================================*
 * 関数プロトタイプ
 *============================================================================*/

#ifdef __cplusplus
extern "C" {
#endif

#if defined(IPMSG_DEBUG)
// ログ出力関数
void IPMsgLog(NSString* level, char* file, int line, NSString* msg);
#endif

#ifdef __cplusplus
}	// extern "C"
#endif
