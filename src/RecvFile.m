/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: RecvFile.m
 *	Module		: 添付ファイルオブジェクトクラス
 *============================================================================*/

#import <Cocoa/Cocoa.h>

//	#define IPMSG_LOG_TRC	0

#import "RecvFile.h"
#import "NSString+IPMessenger.h"
#import "DebugLog.h"

/*============================================================================*
 * プライベートメソッド定義
 *============================================================================*/

@interface RecvFile()

@property(retain)	NSFileHandle*	handle;

@end

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation RecvFile

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/

// 解放
- (void)dealloc
{
	[_path release];
	[_handle release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*
 * ファイル入出力関連
 *----------------------------------------------------------------------------*/

// 書き込み用に開く
- (BOOL)openHandle
{
	NSFileManager* fm = NSFileManager.defaultManager;

	if (self.handle != nil) {
		// 既に開いていれば閉じる（バグ）
		WRN(@"openToRead:Recalled(%@)", self.path);
		[self.handle closeFile];
		self.handle = nil;
	}

	if (!self.path) {
		// ファイルパス未定義は受信添付ファイルの場合ありえる（バグ）
		ERR(@"filePath not specified.(%@)", self.name);
		return NO;
	}

	switch (self.type) {
	case ATTACH_TYPE_REGULAR_FILE:
		//		DBG(@"type[file]=%@,size=%d", self.name, fileSize);
		// 既存ファイルがあれば削除
		if ([fm fileExistsAtPath:self.path]) {
			if (![fm removeItemAtPath:self.path error:NULL]) {
				ERR(@"remove error exist file(%@)", self.path);
				dispatch_sync(dispatch_get_main_queue(), ^{
					NSAlert* alert = [[[NSAlert alloc] init] autorelease];
					alert.alertStyle = NSAlertStyleCritical;
					alert.messageText = NSLocalizedString(@"RecvDlg.Attach.NoPermission.Title", nil);
					alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"RecvDlg.Attach.NoPermission.Msg", nil), self.path];
					[alert runModal];
				});
			}
		}
		// ファイル作成
		if (![fm createFileAtPath:self.path
						 contents:nil
					   attributes:[self makeFileAttributes]]) {
			ERR(@"file create error(%@)", self.path);
			return NO;
		}
		// オープン（サイズ０は除く）
		if (self.size > 0) {
			self.handle = [NSFileHandle fileHandleForWritingAtPath:self.path];
			if (!self.handle) {
				ERR(@"file open error(%@)", self.path);
				return NO;
			}
		}
		break;
	case ATTACH_TYPE_DIRECTORY:
		//		DBG(@"type[subDir]=%@", self.name);
		// 既存ファイルがあれば削除
		if ([fm fileExistsAtPath:self.path]) {
			if (![fm removeItemAtPath:self.path error:NULL]) {
				ERR(@"remove error exist dir(%@)", self.path);
				dispatch_sync(dispatch_get_main_queue(), ^{
					NSAlert* alert = [[[NSAlert alloc] init] autorelease];
					alert.alertStyle = NSAlertStyleCritical;
					alert.messageText = NSLocalizedString(@"RecvDlg.Attach.NoPermission.Title", nil);
					alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"RecvDlg.Attach.NoPermission.Msg", nil), self.path];
					[alert runModal];
				});
			}
		}
		// ディレクトリ作成
		if (![fm createDirectoryAtPath:self.path
		   withIntermediateDirectories:YES
							attributes:[self makeFileAttributes]
								 error:NULL]) {
				  ERR(@"dir create error(%@)", self.path);
			return NO;
		}
		break;
	default:
		ERR(@"unsupported file type(%ld,%@)", self.type, self.name);
		break;
	}

	return YES;
}

// ファイル書き込み
- (BOOL)writeData:(void*)data length:(size_t)len
{
	if (!self.handle) {
		ERR(@"handle not opend.");
		return NO;
	}
	@try {
		[self.handle writeData:[NSData dataWithBytesNoCopy:data length:len freeWhenDone:NO]];
		return YES;
	}
	@catch (NSException* exception) {
		ERR(@"write error([%@]size=%lu)", exception.name, len);
	}
	return NO;
}

// ファイルクローズ
- (void)closeHandle
{
	if (self.handle) {
		[self.handle closeFile];
		self.handle = nil;
	}
	NSFileManager*			fm = NSFileManager.defaultManager;
	NSDictionary*			orgDic;
	NSMutableDictionary*	newDic;
	switch (self.type) {
	case ATTACH_TYPE_REGULAR_FILE:
	case ATTACH_TYPE_DIRECTORY:
		// FileManager属性の設定
		orgDic = [fm attributesOfItemAtPath:self.path error:NULL];
		newDic = [NSMutableDictionary dictionaryWithCapacity:orgDic.count];
		[newDic addEntriesFromDictionary:orgDic];
		[newDic addEntriesFromDictionary:[self makeFileAttributes]];
		newDic[NSFileImmutable] = @(self.readonly);
		[fm setAttributes:newDic ofItemAtPath:self.path error:NULL];
		if (self.hidden) {
			NSURL* fileURL = [NSURL fileURLWithPath:self.path];
			NSError* error = nil;
			if (![fileURL setResourceValue:@YES forKey:NSURLIsHiddenKey error:&error]) {
				ERR(@"Hidden set error(%@,%@)", self.path, error);
			}
		}
		break;
	default:
		// NOP
		break;
	}
}

// ファイル属性（NSFileManager用）作成
- (NSDictionary*)makeFileAttributes
{
	NSMutableDictionary* attr = [NSMutableDictionary dictionaryWithCapacity:6];

	// アクセス権（安全のため0600は必ず付与）
	if (self.permission != 0) {
		attr[NSFilePosixPermissions] = @(self.permission|0600);
	}

	// 作成日時
	if (self.createTime) {
		attr[NSFileCreationDate] = self.createTime;
	}

	// 更新日時
	if (self.modifyTime) {
		attr[NSFileModificationDate] = self.modifyTime;
	}

	// 拡張子非表示
	attr[NSFileExtensionHidden] = @(self.extensionHidden);

	// ファイルタイプ
	if (self.hfsFileType != 0) {
		attr[NSFileHFSTypeCode] = @(self.hfsFileType);
	}

	// クリエータ
	if (self.hfsCreator != 0) {
		attr[NSFileHFSCreatorCode] = @(self.hfsCreator);
	}

	return attr;
}

/*----------------------------------------------------------------------------*
 * その他
 *----------------------------------------------------------------------------*/

// オブジェクト概要
- (NSString*)description
{
	return [NSString stringWithFormat:@"ReccFile[FileID:%ld,File:%@]", self.fileID, self.name];
}

@end
