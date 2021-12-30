/*============================================================================*
 * (C) 2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: SendAttachment.m
 *	Module		: 送信添付ファイル情報クラス
 *============================================================================*/

#import "SendAttachment.h"
#import "UserInfo.h"
#import "DebugLog.h"

typedef NSMutableArray<UserInfo*>	_UserList;

@interface SendAttachment()

@property(retain)	_UserList*	userList;

@end

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation SendAttachment

/*----------------------------------------------------------------------------*
 * ファクトリ
 *----------------------------------------------------------------------------*/

+ (instancetype)attachmentWithPath:(NSString*)path
{
	return [[[SendAttachment alloc] initWithPath:path] autorelease];
}

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/

// 初期化（送信用）
- (instancetype)initWithPath:(NSString*)path
{
	self = [super init];
	if (self) {
		NSFileManager* fm = NSFileManager.defaultManager;
		// ファイル存在チェック
		if (![fm fileExistsAtPath:path]) {
			ERR(@"file not exists(%@)", path);
			[self release];
			return nil;
		}
		// ファイル読み込みチェック
		if (![fm isReadableFileAtPath:path]) {
			ERR(@"file not readable(%@)", path);
			[self release];
			return nil;
		}

		NSURL*	fileURL = [NSURL fileURLWithPath:path];
		id		value;
		// リンクファイルチェック（エイリアス）
		if ([fileURL getResourceValue:&value forKey:NSURLIsAliasFileKey error:nil]) {
			if ([value boolValue]) {
				// エイリアスファイルは除く
				ERR(@"file is hfs Alias(%@)", path);
				[self release];
				return nil;
			}
		}
		// リンクファイルチェック（シンボリックリンク）
		if ([fileURL getResourceValue:&value forKey:NSURLIsSymbolicLinkKey error:nil]) {
			if ([value boolValue]) {
				// シンボリックリンクは除く
				ERR(@"file is Symbolic link(%@)", path);
				[self release];
				return nil;
			}
		}

		NSDictionary<NSFileAttributeKey, id>* attrs = [fm attributesOfItemAtPath:path error:nil];
		NSString* type = attrs[NSFileType];
		if (![type isEqualToString:NSFileTypeRegular] &&
			![type isEqualToString:NSFileTypeDirectory]) {
			WRN(@"filetype unsupported(%@ is %@)", path, type);
			[self release];
			return nil;
		}

		_fileID		= NSNotFound;
		_path		= [path copy];
		_name		= [path.lastPathComponent.precomposedStringWithCanonicalMapping copy];;
		_userList	= [[_UserList alloc] init];
	}
	return self;
}

// 解放
- (void)dealloc
{
	if (_trashTimer.isValid) {
		DBG(@"Attachment Release Timer canceled(PacketNo=%ld,FileID=%ld)", _packetNo, _fileID);
		[_trashTimer invalidate];
	}
	[_trashTimer release];
	[_userList release];
	[_path release];
	[_name release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*
 * プロパティアクセス
 *----------------------------------------------------------------------------*/

// 未ダウンロードユーザ一覧
- (NSArray<UserInfo*>*)remainUsers
{
	@synchronized (self.userList) {
		return self.userList;
	}
}

/*----------------------------------------------------------------------------*
 * 送信ユーザ管理
 *----------------------------------------------------------------------------*/

// 送信ユーザ追加
- (NSInteger)addUser:(UserInfo*)user
{
	@synchronized (self.userList) {
		if (![self.userList containsObject:user]) {
			[self.userList addObject:user];
		}
		return self.userList.count;
	}
}

// 送信ユーザ削除
- (NSInteger)removeUser:(UserInfo*)user
{
	@synchronized (self.userList) {
		[self.userList removeObject:user];
		return self.userList.count;
	}
}

/*----------------------------------------------------------------------------*
 * その他
 *----------------------------------------------------------------------------*/

// オブジェクト概要
- (NSString*)description
{
	return [NSString stringWithFormat:@"SendAttachment[FileID:%ld,File:%@,Users:%ld]",
									self.fileID, self.name, self.userList.count];
}

@end
