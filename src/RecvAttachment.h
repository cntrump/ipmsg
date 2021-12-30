/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RecvAttachment.h
 *	Module		: 受信添付情報抽象クラス
 *============================================================================*/

#import <Foundation/Foundation.h>

/*============================================================================*
 * 定数定義
 *============================================================================*/

// 添付ファイル種別
typedef NS_ENUM(NSInteger, AttachmentType)
{
	ATTACH_TYPE_REGULAR_FILE,		// 通常ファイル
	ATTACH_TYPE_DIRECTORY,			// ディレクトリ
	ATTACH_TYPE_RET_PARENT,			// 親ディレクトリ移動（ディレクトリダウンロード時）
	ATTACH_TYPE_CLIPBOARD,			// 埋め込みクリップボード
	_ATTACH_TYPE_UNKNOWN			// その他
};

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface RecvAttachment : NSObject

@property(assign)	NSInteger		fileID;				// ファイルID
@property(assign)	AttachmentType	type;				// 種別
@property(copy)		NSString*		name;				// ファイル名
@property(assign)	size_t			size;				// ファイルサイズ
@property(retain)	NSDate*			createTime;			// ファイル生成時刻
@property(retain)	NSDate*			modifyTime;			// ファイル最終更新時刻
@property(assign)	BOOL			readonly;			// 読み込み専用かどうか
@property(assign)	BOOL			hidden;				// 隠しファイルかどうか
@property(assign)	BOOL			extensionHidden;	// 拡張子を隠すかどうか
@property(assign)	OSType			hfsFileType;		// HFSファイルタイプ
@property(assign)	OSType			hfsCreator;			// HFSクリエータ
@property(assign)	short			permission;			// POXISパーミッション

- (BOOL)openHandle;
- (BOOL)writeData:(void*)data length:(size_t)len;
- (void)closeHandle;

@end
