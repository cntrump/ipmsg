/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: SendMessage.h
 *	Module		: 送信メッセージクラス
 *============================================================================*/

#import <Foundation/Foundation.h>

@class SendAttachment;

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface SendMessage : NSObject

@property(assign)	NSInteger					packetNo;		// パケット番号
@property(copy)		NSString*					message;		// 送信メッセージ
@property(retain)	NSArray<SendAttachment*>*	attachments;	// 添付ファイル
@property(assign)	BOOL						sealed;			// 封書フラグ
@property(assign)	BOOL						locked;			// 施錠フラグ

@end
