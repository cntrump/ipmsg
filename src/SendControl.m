/*============================================================================*
 * (C) 2001-2010 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for MacOS X
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
#import "Attachment.h"
#import "AttachmentFile.h"
#import "AttachmentServer.h"
#import "MessageCenter.h"
#import "WindowManager.h"
#import "ReceiveControl.h"
#import "DebugLog.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
typedef unsigned int NSUInteger;
#endif

static NSImage* attachmentImage		= nil;
static NSDate*	lastTimeOfEntrySent	= nil;
 
/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation SendControl

/*----------------------------------------------------------------------------*
 * 初期化／解放
 *----------------------------------------------------------------------------*/

// 初期化
- (id)initWithSendMessage:(NSString*)msg recvMessage:(RecvMessage*)recv {
	self = [super init];
	
	selectedUsers		= [[NSMutableArray alloc] init];
	selectedUsersLock	= [[NSLock alloc] init];
	receiveMessage		= [recv retain];
	attachments			= [[NSMutableArray alloc] init];
	attachmentsDic		= [[NSMutableDictionary alloc] init];
	
	// Nibファイルロード
	if (![NSBundle loadNibNamed:@"SendWindow.nib" owner:self]) {
		[self autorelease];
		return nil;
	}

	// 引用メッセージの設定
	if (msg) {
		if ([msg length] > 0) {
			// 引用文字列行末の改行がなければ追加
			if ([msg characterAtIndex:[msg length] - 1] != '\n') {
				[messageArea insertText:[msg stringByAppendingString:@"\n"]];
			} else {
				[messageArea insertText:msg];
			}
		}
	}

	// ユーザ数ラベルの設定
	[self userListChanged:nil];
	
	// 添付機能ON/OFF
	[attachButton setEnabled:[AttachmentServer isAvailable]];
	
	// 添付ヘッダカラム名設定
	[self setAttachHeader];

	// 送信先ユーザの選択
	if (receiveMessage) {
		NSUInteger index = [[UserManager sharedManager] indexOfUser:[receiveMessage fromUser]];
		if (index != NSNotFound) {
			[userTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
				   byExtendingSelection:[[Config sharedConfig] allowSendingToMultiUser]];
			[userTable scrollRowToVisible:index];
		}
	}

	// ウィンドウマネージャへの登録
	if (receiveMessage) {
		[[WindowManager sharedManager] setReplyWindow:self forKey:receiveMessage];
	}
	
	// ユーザリスト変更の通知登録
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(userListChanged:)
												 name:NOTICE_USER_LIST_CHANGED
											   object:nil];
	// ウィンドウ表示
	[window makeKeyAndOrderFront:self];
	// ファーストレスポンダ設定
	[window makeFirstResponder:messageArea];

	return self;
}

// 解放
- (void)dealloc {
	[selectedUsers release];
	[selectedUsersLock release];
	[receiveMessage release];
	[attachments release];
	[attachmentsDic release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*
 * ボタン／チェックボックス操作
 *----------------------------------------------------------------------------*/

- (IBAction)buttonPressed:(id)sender {
	// 更新ボタン
	if (sender == refreshButton) {
		[self updateUserList:nil];
	}
	// 添付追加ボタン
	else if (sender == attachAddButton) {
		NSOpenPanel* op = [NSOpenPanel openPanel];;
		// 添付追加／削除ボタンを押せなくする
		[attachAddButton setEnabled:NO];
		[attachDelButton setEnabled:NO];
		// シート表示
		[op setCanChooseDirectories:YES];
		[op beginSheetForDirectory:nil
							  file:nil
					modalForWindow:window
					 modalDelegate:self
					didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
					   contextInfo:sender];		
	}
	// 添付削除ボタン
	else if (sender == attachDelButton) {
		int selIdx = [attachTable selectedRow];
		if (selIdx >= 0) {
			Attachment* info = [attachments objectAtIndex:selIdx];
			[attachmentsDic removeObjectForKey:[[info file] path]];
			[attachments removeObjectAtIndex:selIdx];
			[attachTable reloadData];
			[self setAttachHeader];
		}
	} else {
		ERR(@"unknown button pressed(%@)", sender);
	}
}

- (IBAction)checkboxChanged:(id)sender {
	// 全員に送信チェックボックスクリック
	if (sender == sendAllCheck) {
		// チェックされたらユーザリストのすべてのユーザを選択状態にする
		// チェックが外されたらすべてのユーザを非選択状態にする
		if ([sendAllCheck state]) {
			[userTable selectAll:self];
		} else {
			[userTable deselectAll:self];
		}
	}
	// 封書チェックボックスクリック
	else if (sender == sealCheck) {
		BOOL state = [sealCheck state];
		// 封書チェックがチェックされているときだけ鍵チェックが利用可能
		[passwordCheck setEnabled:state];
		// 封書チェックのチェックがはずされた場合は鍵のチェックも外す
		if (!state) {
			[passwordCheck setState:NSOffState];
		}
	}
	// 鍵チェックボックス
	else if (sender == passwordCheck) {
		// nop
	} else {
		ERR(@"Unknown button pressed(%@)", sender);
	}		
}

// シート終了処理
- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)code contextInfo:(void*)info {
	if (info == sendButton) {
		[sheet orderOut:self];
		if (code == NSOKButton) {
			// 不在モードを解除してメッセージを送信
			[[NSApp delegate] setAbsenceOff];
			[self sendMessage:self];
		}
	} else if (info == attachAddButton) {
		if (code == NSOKButton) {
			NSOpenPanel*	op = (NSOpenPanel*)sheet;
			NSString*		fn = [op filename];
			[self appendAttachmentByPath:fn];
		}
		[sheet orderOut:self];
		[attachAddButton setEnabled:YES];
		[attachDelButton setEnabled:([attachTable numberOfSelectedRows] > 0)];
	}
}

// 送信メニュー選択時処理
- (IBAction)sendMessage:(id)sender {
	[self sendPressed:sender];
}

// 送信ボタン押下／送信メニュー選択時処理
- (IBAction)sendPressed:(id)sender {
	SendMessage*	info;
	NSMutableArray*	to;
	NSString*		msg;
	BOOL			sealed;
	BOOL			locked;
	NSIndexSet*		users;
	Config*			config = [Config sharedConfig];
	NSUInteger		index;
	
	if ([config isAbsence]) {
		// 不在モードを解除して送信するか確認
		NSBeginAlertSheet(	NSLocalizedString(@"SendDlg.AbsenceOff.Title", nil),
							NSLocalizedString(@"SendDlg.AbsenceOff.OK", nil),
							NSLocalizedString(@"SendDlg.AbsenceOff.Cancel", nil),
							nil,
							window,
							self,
							@selector(sheetDidEnd:returnCode:contextInfo:),
							nil,
							sender,
							NSLocalizedString(@"SendDlg.AbsenceOff.Msg", nil),
								[config absenceTitleAtIndex:[config absenceIndex]]);
		return;
	}

	// 送信情報整理
	msg		= [messageArea string];
	sealed	= [sealCheck state];
	locked	= [passwordCheck state];
	to		= [[[NSMutableArray alloc] init] autorelease];
	users	= [userTable selectedRowIndexes];
	index	= [users firstIndex];
	while (index != NSNotFound) {
		[to addObject:[[UserManager sharedManager] userAtIndex:index]];
		index = [users indexGreaterThanIndex:index];
	}
	// 送信情報構築
	info = [SendMessage messageWithMessage:msg
							   attachments:attachments
									  seal:sealed
									  lock:locked];
	// メッセージ送信
	[[MessageCenter sharedCenter] sendMessage:info to:to];
	// ログ出力
	[[LogManager standardLog] writeSendLog:info to:to];
	// 受信ウィンドウ消去（初期設定かつ返信の場合）
	if ([config hideReceiveWindowOnReply]) {
		ReceiveControl* receiveWin = [[WindowManager sharedManager] receiveWindowForKey:receiveMessage];
		if (receiveWin) {
			[[receiveWin window] performClose:self];
		}
	}
	// 自ウィンドウを消去
	[window performClose:self];
}

// 選択ユーザ一覧の更新
- (void)updateSelectedUsers {
	if ([selectedUsersLock tryLock]) {
		NSIndexSet*		select	= [userTable selectedRowIndexes];
		UserManager*	manager	= [UserManager sharedManager];
		NSUInteger		index;
		[selectedUsers removeAllObjects];
		index = [select firstIndex];
		while (index != NSNotFound) {
			[selectedUsers addObject:[manager userAtIndex:index]];
			index = [select indexGreaterThanIndex:index];
		}
		[selectedUsersLock unlock];
	}
}

// SplitViewのリサイズ制限
- (float)splitView				:(NSSplitView*)sender
		  constrainMinCoordinate:(float)proposedMin
					 ofSubviewAt:(int)offset {
	if (offset == 0) {
		// 上側ペインの最小サイズを制限
		return 80;
	}
	return proposedMin;
}

// SplitViewのリサイズ制限
- (float)splitView				:(NSSplitView*)sender
		  constrainMaxCoordinate:(float)proposedMax
					 ofSubviewAt:(int)offset {
	if (offset == 0) {
		// 上側ペインの最大サイズを制限
		return [sender frame].size.height - [sender dividerThickness];
	}
	return proposedMax;
}

// SplitViewのリサイズ処理
- (void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSSize	newSize	= [sender frame].size;
	float	divider	= [sender dividerThickness];
	NSRect	frame1	= [splitSubview1 frame];
	NSRect	frame2	= [splitSubview2 frame];
	
	frame1.size.width	= newSize.width;
	if (frame1.size.height > newSize.height - divider) {
		// ヘッダ部の高さは変更しないがSplitViewの大きさ内には納める
		frame1.size.height = newSize.height - divider;
	}
	frame2.size.width	= newSize.width;
	frame2.size.height	= newSize.height - frame1.size.height - divider;
	[splitSubview1 setFrame:frame1];
	[splitSubview2 setFrame:frame2];
}

/*----------------------------------------------------------------------------*
 * NSTableDataSourceメソッド
 *----------------------------------------------------------------------------*/
 
- (int)numberOfRowsInTableView:(NSTableView*)aTableView {
	if (aTableView == userTable) {
		return [[UserManager sharedManager] numberOfUsers];
	} else if (aTableView == attachTable) {
		return [attachments count];
	} else {
		ERR(@"Unknown TableView(%@)", aTableView);
	}
	return 0;
}

- (id)tableView:(NSTableView*)aTableView
		objectValueForTableColumn:(NSTableColumn*)aTableColumn
		row:(int)rowIndex {
	if (aTableView == userTable) {
		UserInfo* info = [[UserManager sharedManager] userAtIndex:rowIndex];
		NSString* iden = [aTableColumn identifier];
		if ([iden isEqualToString:@"UserName"]) {
			return [info summeryString];
		} else if ([iden isEqualToString:@"Attachment"]) {
			return ([info attachmentSupport] ? attachmentImage : nil);
		} else if ([iden isEqualToString:@"Encrypt"]) {
			return ([info encryptSupport] ? @"E" : @"");
		} else {
			ERR(@"Unknown TableColumn(%@)", iden);
		}
	} else if (aTableView == attachTable) {
		Attachment*					attach;
		NSMutableAttributedString*	cellValue;
		NSFileWrapper*				fileWrapper;
		NSTextAttachment*			textAttachment;
		attach = [attachments objectAtIndex:rowIndex];
		if (!attach) {
			ERR(@"no attachments(row=%d)", rowIndex);
			return nil;
		}
		fileWrapper		= [[NSFileWrapper alloc] initRegularFileWithContents:nil];
		textAttachment	= [[NSTextAttachment alloc] initWithFileWrapper:fileWrapper];
		[(NSCell*)[textAttachment attachmentCell] setImage:[attach iconImage]];
		cellValue		= [[[NSMutableAttributedString alloc] initWithString:[[attach file] name]] autorelease]; 
		[cellValue replaceCharactersInRange:NSMakeRange(0, 0)
					   withAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
		[cellValue addAttribute:NSBaselineOffsetAttributeName
						  value:[NSNumber numberWithFloat:-3.0]
						  range:NSMakeRange(0, 1)];
		[textAttachment release];
		[fileWrapper release];
		return cellValue;
	} else {
		ERR(@"Unknown TableView(%@)", aTableView);
	}
	return nil;
}

// ユーザリストの選択変更
- (void)tableViewSelectionDidChange:(NSNotification*)aNotification {
	NSTableView* table = [aNotification object];
	if (table == userTable) {
		int selectNum = [userTable numberOfSelectedRows];
		// 選択ユーザ一覧更新
		[self updateSelectedUsers];
		// １つ以上のユーザが選択されていない場合は送信ボタンが押下不可
		[sendButton setEnabled:(selectNum > 0)];
		// すべてのユーザが選ばれている場合に全員に送信チェックボックスをONにする
		[sendAllCheck setState:(selectNum == [[UserManager sharedManager] numberOfUsers])];
	} else if (table == attachTable) {
		[attachDelButton setEnabled:([attachTable numberOfSelectedRows] > 0)];
	} else {
		ERR(@"Unknown TableView(%@)", table);
	}
}

/*----------------------------------------------------------------------------*
 * 添付ファイル
 *----------------------------------------------------------------------------*/

- (void)appendAttachmentByPath:(NSString*)path {
	AttachmentFile*	file;
	Attachment*		attach;
	file = [AttachmentFile fileWithPath:path];
	if (!file) {
		WRN(@"file invalid(%@)", path);
		return;
	}
	attach = [Attachment attachmentWithFile:file];
	if (!attach) {
		WRN(@"attachement invalid(%@)", path);
		return;
	}
	if ([attachmentsDic objectForKey:path]) {
		WRN(@"already contains attachment(%@)", path);
		return;
	}
	[attachments addObject:attach];
	[attachmentsDic setObject:attach forKey:path];
	[attachTable reloadData];
	[self setAttachHeader];
	[attachDrawer open:self];
}

/*----------------------------------------------------------------------------*
 * その他
 *----------------------------------------------------------------------------*/

// ユーザリスト更新
- (IBAction)updateUserList:(id)sender {
	if (!lastTimeOfEntrySent || ([lastTimeOfEntrySent timeIntervalSinceNow] < -2.0)) {
		[[UserManager sharedManager] removeAllUsers];
		[sendAllCheck setState:NO];
		[[MessageCenter sharedCenter] broadcastEntry];
	} else {
		DBG(@"Cancel Refresh User(%f)", [lastTimeOfEntrySent timeIntervalSinceNow]);
	}
	[lastTimeOfEntrySent release];
	lastTimeOfEntrySent = [[NSDate date] retain];
}

// ユーザ一覧変更時処理
- (void)userListChanged:(NSNotification*)aNotification {
	int i;
	[selectedUsersLock lock];
	// ユーザ数設定
	[userNumLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"SendDlg.UserNumStr", nil),
															[[UserManager sharedManager] numberOfUsers]]];
	// ユーザリストの再描画
	[userTable reloadData];
	// 再選択
	[userTable deselectAll:self];
	for (i = 0; i < [selectedUsers count]; i++) {
		NSUInteger index = [[UserManager sharedManager] indexOfUser:[selectedUsers objectAtIndex:i]];
		if (index != NSNotFound) {
			[userTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
				   byExtendingSelection:[[Config sharedConfig] allowSendingToMultiUser]];
		}
	}
	[selectedUsersLock unlock];
	[self updateSelectedUsers];
}

// ウィンドウを返す
- (NSWindow*)window {
	return window;
}

// ウィンドウサイズを標準に戻す
- (void)resetSendWindowSize:(id)sender {
	[[Config sharedConfig] resetSendWindowSize];
}

// ウィンドウサイズの保存
- (void)saveSendWindowSize:(id)sender {
	[[Config sharedConfig] setSendWindowSize:[[NSApp keyWindow] frame].size split:[splitSubview1 frame].size.height];
}

// ウィンドウ位置の保存
- (void)saveSendWindowPosition:(id)sender {
	Config*	config = [Config sharedConfig];
	if ([sender state]) {
		[config resetSendWindowPosition];
		[sender setState:NO];
	} else {
		[config setSendWindowPosition:[[NSApp keyWindow] frame].origin];
		[sender setState:YES];
	}
}

// メッセージ部フォントパネル表示
- (void)showSendMessageFontPanel:(id)sender {
	[[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

// メッセージ部フォント保存
- (void)saveSendMessageFont:(id)sender {
	[[Config sharedConfig] setSendMessageFont:[messageArea font]];
}

// メッセージ部フォントを標準に戻す
- (void)resetSendMessageFont:(id)sender {
	[messageArea setFont:[[Config sharedConfig] defaultSendMessageFont]];
}

// 送信不可の場合にメニューからの送信コマンドを抑制する
- (BOOL)respondsToSelector:(SEL)aSelector {
	if (aSelector == @selector(sendMessage:)) {
		return [sendButton isEnabled];
	}
	return [super respondsToSelector:aSelector];
}

/*----------------------------------------------------------------------------*
 *  デリゲート
 *----------------------------------------------------------------------------*/

// Nibファイルロード時処理
- (void)awakeFromNib {
	Config*			config		= [Config sharedConfig];
	NSPoint			pos			= [config sendWindowPosition];
	NSSize			size		= [config sendWindowSize];
	float			splitPoint	= [config sendWindowSplit];
	NSRect			frame		= [window frame];
	NSTableColumn*	column;
	
	// ウィンドウ位置、サイズ決定
	if ((pos.x != 0) || (pos.y != 0)) {
		frame.origin.x = pos.x;
		frame.origin.y = pos.y;
	} else {
		// 位置が固定されていない場合ランダム
		int sw	= [[NSScreen mainScreen] visibleFrame].size.width;
		int sh	= [[NSScreen mainScreen] visibleFrame].size.height;
		int ww	= [window frame].size.width;
		int wh	= [window frame].size.height;
		frame.origin.x = (sw - ww) / 2 + (rand() % (sw / 4)) - sw / 8;
		frame.origin.y = (sh - wh) / 2 + (rand() % (sh / 4)) - sh / 8; 
	}
	if ((size.width != 0) || (size.height != 0)) {
		frame.size.width	= size.width;
		frame.size.height	= size.height;
	}
	[window setFrame:frame display:NO];
	
	// SplitViewサイズ決定
	if (splitPoint != 0) {
		// 上部
		frame = [splitSubview1 frame];
		frame.size.height = splitPoint;
		[splitSubview1 setFrame:frame];
		// 下部
		frame = [splitSubview2 frame];
		frame.size.height = [splitView frame].size.height - splitPoint - [splitView dividerThickness];
		[splitSubview2 setFrame:frame];
		// 全体
		[splitView adjustSubviews];
	}
	
	// 封書チェックをデフォルト判定
	if ([config sealCheckDefault]) {
		[sealCheck setState:NSOnState];
		[passwordCheck setEnabled:YES];
	}
	
	// 全員に送信チェック
	[sendAllCheck setEnabled:[config sendAllUsersCheckEnabled]];
	
	// 複数ユーザへの送信を許可
	[userTable setAllowsMultipleSelection:[config allowSendingToMultiUser]];
	
	// ユーザリストの行間設定（デフォルト[3,2]→[2,1]）
	[userTable setIntercellSpacing:NSMakeSize(2, 1)];
	
	// 添付リストの行設定
	[attachTable setRowHeight:16.0];
	
	// メッセージ部フォント
	if ([config sendMessageFont]) {
		[messageArea setFont:[config sendMessageFont]];
	}
	
	// TableCell設定
	column = [userTable tableColumnWithIdentifier:@"Attachment"];
	[column setDataCell:[[[NSImageCell alloc] init] autorelease]];
	
	// ファイル添付アイコン
	if (!attachmentImage) {
		attachmentImage = [[NSImage alloc] initWithContentsOfFile:
								[[NSBundle mainBundle] pathForResource:@"AttachS" ofType:@"tiff"]];
	}
	
	// ファーストレスポンダ設定
	[window makeFirstResponder:messageArea];
}

// ウィンドウクローズ時処理
- (void)windowWillClose:(NSNotification*)aNotification {
	[[WindowManager sharedManager] removeReplyWindowForKey:receiveMessage];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
// なぜか解放されないので手動で
[attachDrawer release];
	[self release];
}

- (void)setAttachHeader {
	NSString*		format	= NSLocalizedString(@"SendDlg.Attach.Header", nil);
	NSString*		title	= [NSString stringWithFormat:format, [attachments count]];
	[[[attachTable tableColumnWithIdentifier:@"Attachment"] headerCell] setStringValue:title];
}


@end