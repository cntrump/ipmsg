/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RecvMessage.m
 *	Module		: 受信メッセージクラス
 *============================================================================*/

#import "RecvMessage.h"
#import "Config.h"
#import "UserInfo.h"
#import "RecvFile.h"
#import "DebugLog.h"

@implementation RecvMessage

/*============================================================================*
 * 初期化／解放
 *============================================================================*/

// 解放
- (void)dealloc
{
	[_receiveDate release];
	[_fromUser release];
	[_attachments release];
	[_clipboards release];
	[_message release];
	[super dealloc];
}

/*============================================================================*
 * その他
 *============================================================================*/

// ダウンロード完了済み添付ファイル削除
- (void)removeDownloadedAttachments
{
	NSMutableIndexSet* remains = [NSMutableIndexSet indexSet];
	[self.attachments enumerateObjectsUsingBlock:^(RecvFile* _Nonnull file, NSUInteger idx, BOOL* _Nonnull stop) {
		if (!file.downloaded) {
			[remains addIndex:idx];
		}
	}];
	if (remains.count != self.attachments.count) {
		self.attachments = [self.attachments objectsAtIndexes:remains];
	}
}

/*============================================================================*
 * その他（親クラスオーバーライド）
 *============================================================================*/

// 等価判定
- (BOOL)isEqual:(id)obj
{
	if ([obj isKindOfClass:self.class]) {
		typeof(self) target = obj;
		return ([self.fromUser isEqual:target.fromUser] &&
				(self.packetNo == target.packetNo));
	}
	return NO;
}

// オブジェクト文字列表現
- (NSString*)description
{
	return [NSString stringWithFormat:@"RecvMessage:PacketNo=%ld,from=%@", self.packetNo, self.fromUser];
}

@end
