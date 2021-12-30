/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: SendControl.m
 *	Module		: 送信メッセージウィンドウコントローラ
 *============================================================================*/

#import <Cocoa/Cocoa.h>
#import "SendControl.h"
#import "AppControl.h"
#import "Config.h"
#import "LogManager.h"
#import "UserInfo.h"
#import "UserManager.h"
#import "RecvMessage.h"
#import "SendMessage.h"
#import "SendAttachment.h"
#import "RecvFile.h"
#import "MessageCenter.h"
#import "ReceiveControl.h"
#import "DebugLog.h"

/*============================================================================*
 * 定数等
 *============================================================================*/

#define _SEARCH_MENUITEM_TAG_USER		(0)
#define _SEARCH_MENUITEM_TAG_GROUP		(1)
#define _SEARCH_MENUITEM_TAG_HOST		(2)
#define _SEARCH_MENUITEM_TAG_LOGON		(3)

static NSDate*				gLastTimeOfEntrySent	= nil;
static NSMutableDictionary*	gUserListColumns		= nil;
static NSRecursiveLock*		gUserListColsLock		= nil;

typedef NSMutableArray<UserInfo*>		_UserList;
typedef NSMutableArray<SendAttachment*>	_AttachList;
typedef NSMutableArray<NSImage*>		_IconList;

/*============================================================================*
 * 内部クラス拡張
 *============================================================================*/

@interface SendControl()  <NSSplitViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property(retain)	_UserList*		users;						// ユーザ一覧
@property(retain)	NSPredicate*	userPredicate;				// ユーザ検索フィルタ
@property(retain)	_UserList*		selectedUsers;				// 選択ユーザリスト
@property(retain)	_AttachList*	attachments;				// 添付ファイル一覧
@property(retain)	_IconList*		icons;						// アイコン一覧
@property(retain)	id<NSObject>	userListChangedObserver;	// 通知オブサーバ

- (void)updateSearchFieldPlaceholder;

@end

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation SendControl

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/

// 初期化
- (instancetype)initWithSendMessage:(NSString*)msg
						recvMessage:(RecvMessage*)recv
{
	self = [super init];
	if (self) {
		_recvMsg		= [recv retain];
		_users			= [UserManager.sharedManager.users mutableCopy];
		_selectedUsers	= [[NSMutableArray alloc] init];
		_attachments	= [[_AttachList alloc] init];
		_icons			= [[_IconList alloc] init];
		if (!gUserListColumns) {
			gUserListColumns	= [[NSMutableDictionary alloc] init];
		}
		if (!gUserListColsLock) {
			gUserListColsLock	= [[NSRecursiveLock alloc] init];
		}

		// Nibファイルロード
		if (![NSBundle.mainBundle loadNibNamed:@"SendWindow" owner:self topLevelObjects:nil]) {
			[self release];
			return nil;
		}

		// 引用メッセージの設定
		if (msg.length > 0) {
			// 引用文字列行末の改行がなければ追加
			if ([msg characterAtIndex:msg.length - 1] != '\n') {
				msg = [msg stringByAppendingString:@"\n"];
			}
			[_messageArea insertText:msg replacementRange:NSMakeRange(0, 0)];
		}

		// ユーザ数ラベルの設定
		[self userListChanged:nil];

		// 添付機能ON/OFF
		_attachButton.enabled = MessageCenter.isAttachmentAvailable;

		// 添付ヘッダカラム名設定
		[self setAttachHeader];

		// 送信先ユーザの選択
		if (_recvMsg) {
			NSUInteger index = [_users indexOfObject:_recvMsg.fromUser];
			if (index != NSNotFound) {
				[self.userTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
							byExtendingSelection:Config.sharedConfig.allowSendingToMultiUser];
				[self.userTable scrollRowToVisible:index];
			}
		}

		// ユーザリスト変更の通知登録
		NSNotificationCenter* nc = NSNotificationCenter.defaultCenter;
		__weak typeof(self) weakSelf = self;
		_userListChangedObserver = [[nc addObserverForName:kIPMsgUserListChangedNotification
													object:nil
													 queue:nil
												usingBlock:^(NSNotification* _Nonnull note) {
															// 非同期でメインスレッドで処理する
															dispatch_async(dispatch_get_main_queue(), ^{
																[weakSelf userListChanged:note];
															});
														}] retain];

		// ウィンドウ表示
		[_window makeKeyAndOrderFront:self];
		// ファーストレスポンダ設定
		[_window makeFirstResponder:_messageArea];
	}

	return self;
}

// 解放
- (void)dealloc
{
	if (_userListChangedObserver) {
		[NSNotificationCenter.defaultCenter removeObserver:_userListChangedObserver];
		[_userListChangedObserver release];
	}
	[_icons release];
	[_attachments release];
	[_userPredicate release];
	[_selectedUsers release];
	[_users release];
	[_recvMsg release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*
 * ボタン／チェックボックス操作
 *----------------------------------------------------------------------------*/

- (IBAction)buttonPressed:(id)sender
{
	// 更新ボタン
	if (sender == self.refreshButton) {
		[self updateUserList:nil];
	}
	// 添付追加ボタン
	else if (sender == self.attachAddButton) {
		// 添付追加／削除ボタンを押せなくする
		self.attachAddButton.enabled	= NO;
		self.attachDelButton.enabled	= NO;
		// シート表示
		NSOpenPanel* op = NSOpenPanel.openPanel;
		op.canChooseDirectories = YES;
		[op beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
			if (result == NSModalResponseOK) {
				for (NSURL* url in op.URLs) {
					[self appendAttachmentByPath:url.path];
				}
			}
			self.attachAddButton.enabled	= YES;
			self.attachDelButton.enabled	= (self.attachTable.numberOfSelectedRows > 0);
		}];
	}
	// 添付削除ボタン
	else if (sender == self.attachDelButton) {
		NSInteger selIdx = self.attachTable.selectedRow;
		if (selIdx >= 0) {
			[self.attachments removeObjectAtIndex:selIdx];
			[self.icons removeObjectAtIndex:selIdx];
			[self.attachTable reloadData];
			[self setAttachHeader];
		}
	} else {
		ERR(@"unknown button pressed(%@)", sender);
	}
}

- (IBAction)checkboxChanged:(id)sender
{
	// 封書チェックボックスクリック
	if (sender == self.sealCheck) {
		BOOL state = self.sealCheck.state;
		// 封書チェックがチェックされているときだけ鍵チェックが利用可能
		self.passwordCheck.enabled = state;
		// 封書チェックのチェックがはずされた場合は鍵のチェックも外す
		if (!state) {
			self.passwordCheck.state = NSOffState;
		}
	}
	// 鍵チェックボックス
	else if (sender == self.passwordCheck) {
		// nop
	} else {
		ERR(@"Unknown button pressed(%@)", sender);
	}
}

// 送信メニュー選択時処理
- (IBAction)sendMessage:(id)sender
{
	[self sendPressed:sender];
}

// 送信ボタン押下／送信メニュー選択時処理
- (IBAction)sendPressed:(id)sender
{
	Config*	config = Config.sharedConfig;
	if (config.inAbsence) {
		// 不在モードを解除して送信するか確認
		NSAlert* alert = [[[NSAlert alloc] init] autorelease];
		alert.alertStyle		= NSAlertStyleWarning;
		alert.messageText		= NSLocalizedString(@"SendDlg.AbsenceOff.Title", nil);
		alert.informativeText	= [NSString stringWithFormat:NSLocalizedString(@"SendDlg.AbsenceOff.Msg", nil), [config absenceTitleAtIndex:config.absenceIndex]];
		[alert addButtonWithTitle:NSLocalizedString(@"SendDlg.AbsenceOff.OK", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"SendDlg.AbsenceOff.Cancel", nil)];
		[alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSAlertFirstButtonReturn) {
				// 不在モードを解除してメッセージを送信
				dispatch_async(dispatch_get_main_queue(), ^() {
					[(AppControl*)NSApp.delegate setAbsenceOff];
					[self sendMessage:self];
				});
			}
		}];
		return;
	}

	// 送信情報構築
	SendMessage* info = [[[SendMessage alloc] init] autorelease];
	info.packetNo		= MessageCenter.nextPacketNo;
	info.message		= self.messageArea.string;
	info.sealed			= (self.sealCheck.state == NSControlStateValueOn);
	info.locked			= (self.passwordCheck.state == NSControlStateValueOn);
	info.attachments	= [NSArray<SendAttachment*> arrayWithArray:self.attachments];
	// 送信先
	NSArray<UserInfo*>*	to = [self.users objectsAtIndexes:self.userTable.selectedRowIndexes];
	// メッセージ送信
	[MessageCenter.sharedCenter sendMessage:info to:to];
	// ログ出力
	[LogManager.standardLog writeSendLog:info to:to];
	// 受信ウィンドウ消去（初期設定かつ返信の場合）
	if (self.recvMsg && config.hideReceiveWindowOnReply) {
		for (NSWindow* window in NSApp.orderedWindows) {
			if ([window.delegate isKindOfClass:ReceiveControl.class]) {
				if ([((ReceiveControl*)window.delegate).recvMsg isEqual:self.recvMsg]) {
					// 返信元の受信ウィンドウを発見したので閉じる
					[window performClose:self];
				}
			}
		}
	}
	// 自ウィンドウを消去
	[self.window performClose:self];
}

/*----------------------------------------------------------------------------*
 * 添付ファイル
 *----------------------------------------------------------------------------*/

- (void)appendAttachmentByPath:(NSString*)path
{
	for (SendAttachment* attach in self.attachments) {
		if ([attach.path isEqualToString:path]) {
			WRN(@"already contains attachment(%@)", path);
			return;
		}
	}
	SendAttachment*	newAttach = [SendAttachment attachmentWithPath:path];
	if (!newAttach) {
		WRN(@"attachement invalid(%@)", path);
		return;
	}
	NSImage* newIcon = [self iconImageForPath:path];
	if (newIcon) {
		[newIcon setSize:NSMakeSize(16, 16)];
	} else {
		newIcon = [[[NSImage alloc] initWithSize:NSMakeSize(16,16)] autorelease];
	}
	[self.attachments addObject:newAttach];
	[self.icons addObject:newIcon];

	[self.attachTable reloadData];
	[self setAttachHeader];
	[self.attachDrawer open:self];
}

/*----------------------------------------------------------------------------*
 * その他
 *----------------------------------------------------------------------------*/

- (IBAction)searchMenuItemSelected:(id)sender
{
	if ([sender isKindOfClass:NSMenuItem.class]) {
		NSMenuItem*			item	= sender;
		NSControlStateValue	newSt	= (item.state == NSOnState) ? NSOffState : NSOnState;
		BOOL				newVal	= (BOOL)(newSt == NSOnState);
		Config*				cfg		= Config.sharedConfig;

		item.state = newSt;
		switch (item.tag) {
			case _SEARCH_MENUITEM_TAG_USER:
				cfg.sendSearchByUserName = newVal;
				break;
			case _SEARCH_MENUITEM_TAG_GROUP:
				cfg.sendSearchByGroupName = newVal;
				break;
			case _SEARCH_MENUITEM_TAG_HOST:
				cfg.sendSearchByHostName = newVal;
				break;
			case _SEARCH_MENUITEM_TAG_LOGON:
				cfg.sendSearchByLogOnName = newVal;
				break;
			default:
				ERR(@"unknown tag(%ld)", item.tag);
				break;
		}
		[self updateUserSearch:self];
		[self updateSearchFieldPlaceholder];
	}
}

// ユーザリスト更新
- (IBAction)updateUserList:(id)sender
{
	if (!gLastTimeOfEntrySent || (gLastTimeOfEntrySent.timeIntervalSinceNow < -2.0)) {
		[UserManager.sharedManager removeAllUsers];
		[MessageCenter.sharedCenter broadcastEntry];
	} else {
		DBG(@"Cancel Refresh User(%f)", [gLastTimeOfEntrySent timeIntervalSinceNow]);
	}
	[gLastTimeOfEntrySent release];
	gLastTimeOfEntrySent = [[NSDate date] retain];
}

- (IBAction)userListMenuItemSelected:(id)sender with:(id)identifier
{
	NSTableColumn* col = [self.userTable tableColumnWithIdentifier:identifier];
	if (col) {
		// あるので消す
		[gUserListColsLock lock];
		[gUserListColumns setObject:col forKey:identifier];
		[gUserListColsLock unlock];
		[self.userTable removeTableColumn:col];
		[sender setState:NSOffState];
		[Config.sharedConfig setSendWindowUserListColumn:identifier hidden:YES];
	} else {
		// ないので追加する
		[gUserListColsLock lock];
		[self.userTable addTableColumn:[gUserListColumns objectForKey:identifier]];
		[gUserListColsLock unlock];
		[sender setState:NSOnState];
		[Config.sharedConfig setSendWindowUserListColumn:identifier hidden:NO];
	}
}

- (IBAction)userListUserMenuItemSelected:(id)sender
{
	[self userListMenuItemSelected:sender
							  with:kIPMsgUserInfoUserNamePropertyIdentifier];
}

- (IBAction)userListGroupMenuItemSelected:(id)sender
{
	[self userListMenuItemSelected:sender
							  with:kIPMsgUserInfoGroupNamePropertyIdentifier];
}

- (IBAction)userListHostMenuItemSelected:(id)sender
{
	[self userListMenuItemSelected:sender
							  with:kIPMsgUserInfoHostNamePropertyIdentifier];
}

- (IBAction)userListIPAddressMenuItemSelected:(id)sender
{
	[self userListMenuItemSelected:sender
							  with:kIPMsgUserInfoIPAddressPropertyIdentifier];
}

- (IBAction)userListLogonMenuItemSelected:(id)sender
{
	[self userListMenuItemSelected:sender
							  with:kIPMsgUserInfoLogOnNamePropertyIdentifier];
}

- (IBAction)userListVersionMenuItemSelected:(id)sender
{
	[self userListMenuItemSelected:sender
							  with:kIPMsgUserInfoVersionPropertyIdentifer];
}

// ユーザ一覧変更時処理
- (void)userListChanged:(NSNotification*)aNotification
{
	[self.users setArray:UserManager.sharedManager.users];
	NSInteger totalNum = self.users.count;
	if (self.userPredicate) {
		[self.users filterUsingPredicate:self.userPredicate];
	}
	[self.users sortUsingDescriptors:self.userTable.sortDescriptors];
	// ユーザ数設定
	NSString* label = [NSString stringWithFormat:NSLocalizedString(@"SendDlg.UserNumStr", nil), self.users.count, totalNum];
	[self.userNumLabel setStringValue:label];
	// ユーザリストの再描画
	[self.userTable reloadData];
	// 再選択
	[self.userTable deselectAll:self];
	NSMutableIndexSet* selectIndexes = [NSMutableIndexSet indexSet];
	for (UserInfo* user in self.selectedUsers) {
		NSUInteger index = [self.users indexOfObject:user];
		if (index != NSNotFound) {
			[selectIndexes addIndex:index];
		}
	}
	if (selectIndexes.count > 0) {
		[self.userTable selectRowIndexes:selectIndexes
					byExtendingSelection:Config.sharedConfig.allowSendingToMultiUser];
	}
}

- (IBAction)searchUser:(id)sender
{
	NSResponder* firstResponder = self.window.firstResponder;
	if ([firstResponder isKindOfClass:NSTextView.class]) {
		NSTextView* tv = (NSTextView*)firstResponder;
		if ([tv.delegate isKindOfClass:NSTextField.class]) {
			NSTextField* tf = (NSTextField*)tv.delegate;
			if (tf == self.searchField) {
				// 検索フィールド（セル内の部品）にフォーカスがある場合はメッセージ領域に移動
				[self.window makeFirstResponder:self.messageArea];
				return;
			}
		}
	}
	// 検索フィールドにフォーカスがなければフォーカスを移動
	[self.window makeFirstResponder:self.searchField];
}

- (IBAction)updateUserSearch:(id)sender
{
	NSString* searchWord = self.searchField.stringValue;
	self.userPredicate = nil;
	if (searchWord.length > 0) {
		Config*				cfg	= Config.sharedConfig;
		NSMutableString*	fmt	= [NSMutableString string];
		if (cfg.sendSearchByUserName) {
			[fmt appendFormat:@"%@ contains[c] '%@'", kIPMsgUserInfoUserNamePropertyIdentifier, searchWord];
		}
		if (cfg.sendSearchByGroupName) {
			if (fmt.length > 0) {
				[fmt appendString:@" OR "];
			}
			[fmt appendFormat:@"%@ contains[c] '%@'", kIPMsgUserInfoGroupNamePropertyIdentifier, searchWord];
		}
		if (cfg.sendSearchByHostName) {
			if (fmt.length > 0) {
				[fmt appendString:@" OR "];
			}
			[fmt appendFormat:@"%@ contains[c] '%@'", kIPMsgUserInfoHostNamePropertyIdentifier, searchWord];
		}
		if (cfg.sendSearchByLogOnName) {
			if (fmt.length > 0) {
				[fmt appendString:@" OR "];
			}
			[fmt appendFormat:@"%@ contains[c] '%@'", kIPMsgUserInfoLogOnNamePropertyIdentifier, searchWord];
		}
		if (fmt.length > 0) {
			self.userPredicate = [NSPredicate predicateWithFormat:fmt];
		}
	}
	[self userListChanged:nil];
}

- (void)updateSearchFieldPlaceholder
{
	Config* cfg = Config.sharedConfig;
	NSMutableArray<NSString*>* array = [NSMutableArray<NSString*> array];
	if (cfg.sendSearchByUserName) {
		[array addObject:NSLocalizedString(@"SendDlg.Search.Target.User", nil)];
	}
	if (cfg.sendSearchByGroupName) {
		[array addObject:NSLocalizedString(@"SendDlg.Search.Target.Group", nil)];
	}
	if (cfg.sendSearchByHostName) {
		[array addObject:NSLocalizedString(@"SendDlg.Search.Target.Host", nil)];
	}
	if (cfg.sendSearchByLogOnName) {
		[array addObject:NSLocalizedString(@"SendDlg.Search.Target.LogOn", nil)];
	}
	NSString* str = @"";
	if (array.count > 0) {
		NSString* sep = NSLocalizedString(@"SendDlg.Search.Placeholder.Separator", nil);
		NSString* fmt = NSLocalizedString(@"SendDlg.Search.Placeholder.Normal", nil);
		str = [NSString stringWithFormat:fmt, [array componentsJoinedByString:sep]];
	} else {
		str = NSLocalizedString(@"SendDlg.Search.Placeholder.Invalid", nil);
	}
	[self.searchField.cell setPlaceholderString:str];
}

// メッセージ部フォントパネル表示
- (void)showSendMessageFontPanel:(id)sender
{
	[NSFontManager.sharedFontManager orderFrontFontPanel:self];
}

// メッセージ部フォント保存
- (void)saveSendMessageFont:(id)sender
{
	Config.sharedConfig.sendMessageFont = self.messageArea.font;
}

// メッセージ部フォントを標準に戻す
- (void)resetSendMessageFont:(id)sender
{
	self.messageArea.font = Config.sharedConfig.defaultSendMessageFont;
}

// 送信不可の場合にメニューからの送信コマンドを抑制する
- (BOOL)respondsToSelector:(SEL)aSelector
{
	if (aSelector == @selector(sendMessage:)) {
		return self.sendButton.enabled;
	}
	return [super respondsToSelector:aSelector];
}

- (void)setAttachHeader
{
	NSString*	format	= NSLocalizedString(@"SendDlg.Attach.Header", nil);
	NSString*	title	= [NSString stringWithFormat:format, self.attachments.count];
	[self.attachTable tableColumnWithIdentifier:@"Attachment"].headerCell.stringValue = title;
}

- (NSImage*)iconImageForPath:(NSString*)path
{
	NSWorkspace* ws = NSWorkspace.sharedWorkspace;

	// 絶対パス（ローカルファイル）
	if (path.isAbsolutePath) {
		NSImage* icon = [ws iconForFile:path];
		if (icon) {
			return icon;
		}
	}

	NSFileManager*	fm = NSFileManager.defaultManager;
	NSDictionary<NSFileAttributeKey, id>* attrs = [fm attributesOfItemAtPath:path error:nil];

	NSString* type = attrs[NSFileType];
	if ([type isEqualToString:NSFileTypeDirectory]) {
		// ディレクトリ
		if ([path.pathExtension isEqualToString:@"app"]) {
			return [ws iconForFileType:@"app"];
		}
		return [ws iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
	}

	// ファイルタイプあり
	NSNumber* hfsType = attrs[NSFileHFSTypeCode];
	if (hfsType) {
		return [ws iconForFileType:NSFileTypeForHFSTypeCode(hfsType.unsignedShortValue)];
	}
	// 最後のたのみ拡張子
	return [ws iconForFileType:path.pathExtension];
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSTableView
/*----------------------------------------------------------------------------*/


- (NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
	if (aTableView == self.userTable) {
		return self.users.count;
	} else if (aTableView == self.attachTable) {
		return self.attachments.count;
	} else {
		ERR(@"Unknown TableView(%@)", aTableView);
	}
	return 0;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)rowIndex
{
	if (tableView == self.userTable) {
		UserInfo* info = self.users[rowIndex];
		NSString* iden = tableColumn.identifier;
		if ([iden isEqualToString:kIPMsgUserInfoUserNamePropertyIdentifier]) {
			return info.userName;
		} else if ([iden isEqualToString:kIPMsgUserInfoGroupNamePropertyIdentifier]) {
			return info.groupName;
		} else if ([iden isEqualToString:kIPMsgUserInfoHostNamePropertyIdentifier]) {
			return info.hostName;
		} else if ([iden isEqualToString:kIPMsgUserInfoIPAddressPropertyIdentifier]) {
			return info.ipAddress;
		} else if ([iden isEqualToString:kIPMsgUserInfoLogOnNamePropertyIdentifier]) {
			return info.logOnName;
		} else if ([iden isEqualToString:kIPMsgUserInfoVersionPropertyIdentifer]) {
			return info.version;
		} else {
			ERR(@"Unknown TableColumn(%@)", iden);
		}
	} else if (tableView == self.attachTable) {
		SendAttachment*	attach = self.attachments[rowIndex];
		if (!attach) {
			ERR(@"no attachments(row=%ld)", rowIndex);
			return nil;
		}
		NSFileWrapper* fw = [[[NSFileWrapper alloc] initRegularFileWithContents:[NSData data]] autorelease];
		NSTextAttachment* ta = [[[NSTextAttachment alloc] initWithFileWrapper:fw] autorelease];
		((NSCell*)ta.attachmentCell).image = self.icons[rowIndex];
		NSAttributedString*	as = [NSAttributedString attributedStringWithAttachment:ta];
		NSMutableAttributedString* val = [[[NSMutableAttributedString alloc] initWithString:attach.name] autorelease];
		[val replaceCharactersInRange:NSMakeRange(0, 0) withAttributedString:as];
		[val addAttribute:NSBaselineOffsetAttributeName value:@(-3.0) range:NSMakeRange(0, 1)];
		return val;
	} else {
		ERR(@"Unknown TableView(%@)", tableView);
	}
	return nil;
}

// ユーザリストの選択変更
- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
	NSTableView* table = aNotification.object;
	if (table == self.userTable) {
		dispatch_async(dispatch_get_main_queue(), ^() {
			NSIndexSet* selection = table.selectedRowIndexes;
			// 選択ユーザ一覧更新
			[self.selectedUsers setArray:[self.users objectsAtIndexes:selection]];
			// １つ以上のユーザが選択されていない場合は送信ボタンが押下不可
			self.sendButton.enabled = (selection.count > 0);
		});
	} else if (table == self.attachTable) {
		dispatch_async(dispatch_get_main_queue(), ^() {
			self.attachDelButton.enabled = (self.attachTable.numberOfSelectedRows > 0);
		});
	} else {
		ERR(@"Unknown TableView(%@)", table);
	}
}

// ソートの変更
- (void)tableView:(NSTableView*)aTableView sortDescriptorsDidChange:(NSArray*)oldDescriptors
{
	dispatch_async(dispatch_get_main_queue(), ^() {
		[self.users sortUsingDescriptors:aTableView.sortDescriptors];
		[aTableView reloadData];
		// 再選択
		[self.userTable deselectAll:self];
		NSMutableIndexSet* selectIndexes = [NSMutableIndexSet indexSet];
		for (UserInfo* user in self.selectedUsers) {
			NSUInteger index = [self.users indexOfObject:user];
			if (index != NSNotFound) {
				[selectIndexes addIndex:index];
			}
		}
		if (selectIndexes.count > 0) {
			[self.userTable selectRowIndexes:selectIndexes
						byExtendingSelection:NO];
		}
	});
}


/*----------------------------------------------------------------------------*/
#pragma mark - NSSplitView
/*----------------------------------------------------------------------------*/

// SplitViewのリサイズ制限
- (CGFloat)splitView:(NSSplitView*)split constrainMinCoordinate:(CGFloat)proposedMin
		 ofSubviewAt:(NSInteger)offset
{
	if (offset == 0) {
		// 上側ペインの最小サイズを制限
		return 90;
	}
	return proposedMin;
}

// SplitViewのリサイズ制限
- (CGFloat)splitView:(NSSplitView*)split constrainMaxCoordinate:(CGFloat)proposedMax
		 ofSubviewAt:(NSInteger)offset
{
	if (offset == 0) {
		// 上側ペインの最大サイズを制限
		return split.frame.size.height - split.dividerThickness - 2;
	}
	return proposedMax;
}

// SplitViewのリサイズ処理
- (void)splitView:(NSSplitView*)split resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSSize	newSize	= split.frame.size;
	float	divider	= split.dividerThickness;
	NSRect	frame1	= [self.splitSubview1 frame];
	NSRect	frame2	= [self.splitSubview2 frame];

	frame1.size.width = newSize.width;
	if (frame1.size.height > newSize.height - divider) {
		// ヘッダ部の高さは変更しないがSplitViewの大きさ内には納める
		frame1.size.height = newSize.height - divider;
	}
	frame2.origin.x		= -1;
	frame2.size.width	= newSize.width + 2;
	frame2.size.height	= newSize.height - frame1.size.height - divider;
	[self.splitSubview1 setFrame:frame1];
	[self.splitSubview2 setFrame:frame2];
}

// SplitViewリサイズ時処理
- (void)splitViewDidResizeSubviews:(NSNotification*)aNotification
{
	Config.sharedConfig.sendWindowSplit = self.splitSubview1.frame.size.height;
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSWindow
/*----------------------------------------------------------------------------*/

// ウィンドウリサイズ時処理
- (void)windowDidResize:(NSNotification *)notification
{
	// ウィンドウサイズを保存
	Config.sharedConfig.sendWindowSize = self.window.frame.size;
}

// ウィンドウクローズ時処理
- (void)windowWillClose:(NSNotification*)aNotification
{
	if (self.userListChangedObserver) {
		[NSNotificationCenter.defaultCenter removeObserver:self.userListChangedObserver];
		self.userListChangedObserver = nil;
	}
	[self release];
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSObject
/*----------------------------------------------------------------------------*/

// Nibファイルロード時処理
- (void)awakeFromNib
{
	Config*	config = Config.sharedConfig;

	// 要ウィンドウリサイズによりサイズが変更されてしまう前に保持
	float splitPoint = config.sendWindowSplit;

	// ウィンドウ位置、サイズ決定
	NSSize	screenSize	= NSScreen.mainScreen.visibleFrame.size;
	NSRect	windowRect	= self.window.frame;
	NSSize	windowSize	= config.sendWindowSize;
	int sw	= screenSize.width;
	int sh	= screenSize.height;
	int ww	= windowRect.size.width;
	int wh	= windowRect.size.height;
	windowRect.origin.x = (sw - ww) / 2 + (arc4random_uniform(INT32_MAX) % (sw / 4)) - sw / 8;
	windowRect.origin.y = (sh - wh) / 2 + (arc4random_uniform(INT32_MAX) % (sh / 4)) - sh / 8;
	if (windowSize.width != 0) {
		windowRect.size.width = windowSize.width;
	}
	if (windowSize.height != 0) {
		windowRect.size.height = windowSize.height;
	}
	[self.window setFrame:windowRect display:NO];

	// SplitViewサイズ決定
	NSRect frame;
	if (splitPoint != 0) {
		// 上部
		frame = self.splitSubview1.frame;
		frame.size.height = splitPoint;
		[self.splitSubview1 setFrame:frame];
		// 下部
		frame = self.splitSubview2.frame;
		frame.origin.x		= -1;
		frame.size.width	+= 2;
		frame.size.height = self.splitView.frame.size.height - splitPoint - self.splitView.dividerThickness;
		[self.splitSubview2 setFrame:frame];
		// 全体
		[self.splitView adjustSubviews];
	}
	frame = self.splitSubview2.frame;
	frame.origin.x		= -1;
	frame.size.width	+= 2;
	[self.splitSubview2 setFrame:frame];

	// 封書チェックをデフォルト判定
	if (config.sealCheckDefault) {
		self.sealCheck.state		= NSControlStateValueOn;
		self.passwordCheck.enabled	= YES;
	}

	// 複数ユーザへの送信を許可
	self.userTable.allowsMultipleSelection = config.allowSendingToMultiUser;

	// ユーザリストの行間設定（デフォルト[3,2]→[2,1]）
	self.userTable.intercellSpacing = NSMakeSize(2, 1);

	// ユーザリストのカラム処理
	NSArray<NSString*>* array = @[	kIPMsgUserInfoUserNamePropertyIdentifier,
									kIPMsgUserInfoGroupNamePropertyIdentifier,
									kIPMsgUserInfoHostNamePropertyIdentifier,
									kIPMsgUserInfoIPAddressPropertyIdentifier,
									kIPMsgUserInfoLogOnNamePropertyIdentifier,
									kIPMsgUserInfoVersionPropertyIdentifer ];
	for (NSString* identifier in array) {
		NSTableColumn* column = [self.userTable tableColumnWithIdentifier:identifier];
		if (column) {
			// カラム保持
			[gUserListColsLock lock];
			[gUserListColumns setObject:column forKey:identifier];
			[gUserListColsLock unlock];
			// 設定値に応じてカラムの削除
			if ([config sendWindowUserListColumnHidden:identifier]) {
				[self.userTable removeTableColumn:column];
			}
		}
	}

	// ユーザリストのソート設定反映
	[self.users sortUsingDescriptors:self.userTable.sortDescriptors];

	// 検索フィールドのメニュー設定
	[self.searchMenu itemWithTag:_SEARCH_MENUITEM_TAG_USER].state	= config.sendSearchByUserName ? NSOnState : NSOffState;
	[self.searchMenu itemWithTag:_SEARCH_MENUITEM_TAG_GROUP].state	= config.sendSearchByGroupName ? NSOnState : NSOffState;
	[self.searchMenu itemWithTag:_SEARCH_MENUITEM_TAG_HOST].state	= config.sendSearchByHostName ? NSOnState : NSOffState;
	[self.searchMenu itemWithTag:_SEARCH_MENUITEM_TAG_LOGON].state	= config.sendSearchByLogOnName ? NSOnState : NSOffState;
	[self.searchField.cell setSearchMenuTemplate:self.searchMenu];
	[self updateSearchFieldPlaceholder];

	// 添付リストの行設定
	self.attachTable.rowHeight = 16.0;

	// 添付ボタンのアイコン設定
	self.attachButton.image.template = YES;

	// メッセージ部フォント
	if (config.sendMessageFont) {
		self.messageArea.font = config.sendMessageFont;
	}

	// ファーストレスポンダ設定
	[self.window makeFirstResponder:self.messageArea];
}

@end
