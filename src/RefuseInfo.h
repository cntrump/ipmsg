/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RefuseInfo.h
 *	Module		: 通知拒否条件情報クラス
 *============================================================================*/

#import <Foundation/Foundation.h>

@class UserInfo;

/*============================================================================*
 * 定数定義
 *============================================================================*/

// 拒否判定対象
typedef NS_ENUM(NSInteger, IPRefuseTarget)
{
	IP_REFUSE_USER,			// ユーザ名
	IP_REFUSE_GROUP,		// グループ名
	IP_REFUSE_MACHINE,		// マシン名
	IP_REFUSE_LOGON,		// ログオン名
	IP_REFUSE_ADDRESS		// IPアドレス

};

// 拒否判定条件
typedef NS_ENUM(NSInteger, IPRefuseCondition)
{
	IP_REFUSE_MATCH,		// 一致する
	IP_REFUSE_CONTAIN,		// 含む
	IP_REFUSE_START,		// 始まる
	IP_REFUSE_END			// 終わる

};

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface RefuseInfo : NSObject <NSCopying>

@property(readonly)	IPRefuseTarget		target;		// 判定対象
@property(readonly)	NSString*			string;		// 文字列
@property(readonly)	IPRefuseCondition	condition;	// 判定条件

// ファクトリ
+ (instancetype)refuseInfoWithTarget:(IPRefuseTarget)aTarget
							  string:(NSString*)aString
						   condition:(IPRefuseCondition)aCondition;

// 初期化
- (instancetype)initWithTarget:(IPRefuseTarget)aTarget
						string:(NSString*)aString
					 condition:(IPRefuseCondition)aCondition;

// 判定
- (BOOL)match:(UserInfo*)user;

@end
