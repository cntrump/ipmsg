/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: ReceiveControl.m
 *	Module		: 受信メッセージウィンドウコントローラ
 *============================================================================*/

#import <Cocoa/Cocoa.h>

#import "ReceiveControl.h"
#import "Config.h"
#import "UserInfo.h"
#import "LogManager.h"
#import "MessageCenter.h"
#import "RecvMessage.h"
#import "SendControl.h"
#import "RecvFile.h"
#import "RecvClipboard.h"
#import "DebugLog.h"

/*============================================================================*
 * 内部定数/型定義
 *============================================================================*/

typedef NS_OPTIONS(NSInteger, _AttachSheetRefreshMask)
{
	_AttachSheetRefreshTitle		= 1 << 0,
	_AttachSheetRefreshFileName		= 1 << 1,
	_AttachSheetRefreshFileNum		= 1 << 2,
	_AttachSheetRefreshDirNum		= 1 << 3,
	_AttachSheetRefreshTotalSize	= 1 << 4,
	_AttachSheetRefreshDownloadSize	= 1 << 5,
};

typedef NSMutableArray<NSImage*>	_IconList;

/*============================================================================*
 * 内部クラス拡張
 *============================================================================*/

@interface ReceiveControl() <DownloaderDelegate>

@property(retain)	_IconList*				icons;					// アイコン一覧
@property(assign)	BOOL					closeConfirmed;			// 閉じる確認済
@property(retain)	NSDate*					dlStart;				// ダウンロード開始時刻
@property(weak)		id<DownloaderContext>	download;				// ダウンロード情報
@property(retain)	NSTimer*				dlSheetRefreshTimer;	// ダウンロードシート更新タイマ
@property(assign)	NSInteger				dlSheetRefreshFlags;	// ダウンロードシート更新マスク

- (void)setAttachHeader;

@end

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation ReceiveControl

/*----------------------------------------------------------------------------*/
#pragma mark - 初期化／解放
/*----------------------------------------------------------------------------*/

// 初期化
- (instancetype)initWithRecvMessage:(RecvMessage*)msg
{
	self = [super init];
	if (self) {
		_recvMsg	= [msg retain];
		_icons		= [[_IconList alloc] init];

		if (![NSBundle.mainBundle loadNibNamed:@"ReceiveWindow" owner:self topLevelObjects:nil]) {
			[self release];
			return nil;
		}

		Config*	config = Config.sharedConfig;

		if (_recvMsg.secureLevel > 0) {
			NSString* secureStr	= [@"" stringByPaddingToLength:_recvMsg.secureLevel
													withString:@"+"
											   startingAtIndex:0];
			_window.title = [NSString stringWithFormat:@"%@ %@", _window.title, secureStr];
		}

		// 重要ログボタン設定
		_altLogButton.image.template = YES;

		// ログ出力
		if (config.standardLogEnabled) {
			if (!_recvMsg.locked || !config.logChainedWhenOpen) {
				[LogManager.standardLog writeRecvLog:_recvMsg];
				_recvMsg.needLog = NO;
			}
		}

		// 表示内容の設定
		_dateLabel.objectValue 		= _recvMsg.receiveDate;
		_userNameLabel.stringValue	= _recvMsg.fromUser.summaryString;
		_messageArea.string			= _recvMsg.message;
		if (_recvMsg.multicast) {
			_infoBox.title	= NSLocalizedString(@"RecvDlg.BoxTitleMulti", nil);
		} else if (_recvMsg.broadcast) {
			_infoBox.title	= NSLocalizedString(@"RecvDlg.BoxTitleBroad", nil);
		} else if (_recvMsg.absence) {
			_infoBox.title	= NSLocalizedString(@"RecvDlg.BoxTitleAbsence", nil);
		}

		// クリッカブルURL設定
		if (config.useClickableURL) {
			_messageArea.linkTextAttributes = @{
				NSForegroundColorAttributeName: NSColor.systemBlueColor,
				NSUnderlineStyleAttributeName:	@(NSUnderlineStyleSingle),
			};
			NSMutableAttributedString*	attrStr	= _messageArea.textStorage;
			NSScanner*					scanner	= [NSScanner scannerWithString:_recvMsg.message];
			NSArray<NSString*>*			schemes	= @[@"http://", @"https://", @"ftp://", @"file://", @"rtsp://", @"afp://", @"mailto:"];
			NSString*					charStr	= NSLocalizedString(@"RecvDlg.URL.Delimiter", nil);
			NSCharacterSet*				charSet	= [NSCharacterSet characterSetWithCharactersInString:charStr];
			while (!scanner.atEnd) {
				NSString* sentence;
				if (![scanner scanUpToCharactersFromSet:charSet intoString:&sentence]) {
					continue;
				}
				NSRange		range;
				unsigned	i;
				for (i = 0; i < schemes.count; i++) {
					range = [sentence rangeOfString:schemes[i]];
					if (range.location != NSNotFound) {
						if (range.location > 0) {
							sentence	= [sentence substringFromIndex:range.location];
						}
						range.length	= sentence.length;
						range.location	= scanner.scanLocation - sentence.length;
						[attrStr addAttribute:NSLinkAttributeName value:sentence range:range];
						break;
					}
				}
				if (i < schemes.count) {
					continue;
				}
				range = [sentence rangeOfString:@"://"];
				if (range.location != NSNotFound) {
					range.location	= scanner.scanLocation - sentence.length;
					range.length	= sentence.length;
					[attrStr addAttribute:NSLinkAttributeName value:sentence range:range];
					continue;
				}
			}
		}

		// 埋め込みクリップボード挿入
		for (RecvClipboard* clip in _recvMsg.clipboards) {
			NSTextAttachmentCell*	cell	= [[[NSTextAttachmentCell alloc] initImageCell:clip.image] autorelease];
			NSTextAttachment*		attach	= [[[NSTextAttachment alloc] init] autorelease];
			attach.attachmentCell = cell;
			NSAttributedString* str = [NSAttributedString attributedStringWithAttachment:attach];
			[_messageArea.textStorage insertAttributedString:str atIndex:clip.clipboardPos];
		}
	}

	return self;
}

// 解放処理
- (void)dealloc
{
	[_dlStart release];
	[_download release];
	[_icons release];
	[_recvMsg release];
	[super dealloc];
}

/*----------------------------------------------------------------------------*/
#pragma mark - 公開メソッド
/*----------------------------------------------------------------------------*/

// ウィンドウ表示
- (void)showWindow
{
	Config*	config = Config.sharedConfig;

	// 準備
	[self setAttachHeader];
	[self.attachTable reloadData];
	[self.attachTable selectAll:self];
	[self buildIcons];

	if (!self.recvMsg.sealed) {
		[self.sealButton removeFromSuperview];
		[self.window makeFirstResponder:_messageArea];
		// 重要ログボタンの有効／無効
		self.altLogButton.hidden	= !config.alternateLogEnabled;
		self.altLogButton.enabled	= config.alternateLogEnabled;
		// 添付ボタンの有効／無効
		self.attachButton.enabled 	= (self.recvMsg.attachments.count > 0);
	} else {
		self.replyButton.enabled	= NO;
		self.quotCheck.enabled		= NO;
		self.messageArea.hidden		= YES;
		if (self.recvMsg.locked) {
			self.sealButton.title = NSLocalizedString(@"RecvDlg.LockBtnStr", nil);
		}
		[self.window makeFirstResponder:self.sealButton];
	}

	self.closeConfirmed = NO;

	// 表示
	NSWindow* orgKeyWin = NSApp.keyWindow;
	if (orgKeyWin) {
		if ([orgKeyWin.delegate isKindOfClass:SendControl.class]) {
			[self.window orderFront:self];
			[orgKeyWin orderFront:self];
		} else {
			[self.window makeKeyAndOrderFront:self];
		}
	} else {
		[self.window makeKeyAndOrderFront:self];
	}
	if ((self.recvMsg.attachments.count > 0) && !self.recvMsg.sealed) {
		[self.attachDrawer open];
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - イベントハンドラ
/*----------------------------------------------------------------------------*/

- (IBAction)buttonPressed:(id)sender
{
	if (sender == self.attachSaveButton) {
		self.attachSaveButton.enabled = NO;
		NSOpenPanel* op = [NSOpenPanel openPanel];
		op.canChooseFiles = NO;
		op.canChooseDirectories = YES;
		op.prompt = NSLocalizedString(@"RecvDlg.Attach.SelectBtn", nil);
		[op beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
			if (result == NSModalResponseOK) {
				NSFileManager*	fileManager	= NSFileManager.defaultManager;
				NSURL*			directory	= op.directoryURL;
				NSIndexSet*		indexes		= self.attachTable.selectedRowIndexes;
				NSMutableArray<RecvFile*>* targets = [NSMutableArray<RecvFile*> array];
				[self.recvMsg.attachments enumerateObjectsAtIndexes:indexes
															options:NSEnumerationConcurrent
														 usingBlock:^(RecvFile* _Nonnull attach, NSUInteger idx, BOOL* _Nonnull stop) {
					NSString* path = [directory.path stringByAppendingPathComponent:attach.name];
					// ファイル存在チェック
					if ([fileManager fileExistsAtPath:path]) {
						// 上書き確認
						WRN(@"file exists(%@)", path);
						NSAlert* alert = [[[NSAlert alloc] init] autorelease];
						alert.alertStyle = NSAlertStyleWarning;
						switch (attach.type) {
						case ATTACH_TYPE_DIRECTORY:
							alert.messageText		= NSLocalizedString(@"RecvDlg.AttachDirOverwrite.Title", nil);
							alert.informativeText	= [NSString stringWithFormat:NSLocalizedString(@"RecvDlg.AttachDirOverwrite.Msg", nil), attach.name];
							[alert addButtonWithTitle:NSLocalizedString(@"RecvDlg.AttachDirOverwrite.OK", nil)];
							[alert addButtonWithTitle:NSLocalizedString(@"RecvDlg.AttachDirOverwrite.Cancel", nil)];
							break;
						default:
							alert.messageText		= NSLocalizedString(@"RecvDlg.AttachFileOverwrite.Title", nil);
							alert.informativeText	= [NSString stringWithFormat:NSLocalizedString(@"RecvDlg.AttachFileOverwrite.Msg", nil), attach.name];
							[alert addButtonWithTitle:NSLocalizedString(@"RecvDlg.AttachFileOverwrite.OK", nil)];
							[alert addButtonWithTitle:NSLocalizedString(@"RecvDlg.AttachFileOverwrite.Cancel", nil)];
							break;
						}
						NSInteger result = [alert runModal];
						switch (result) {
						case NSAlertFirstButtonReturn:
							DBG(@"overwrite ok.");
							break;
						case NSAlertSecondButtonReturn:
							DBG(@"overwrite canceled.");
							[self.attachTable deselectRow:idx];	// 選択解除
							return;
						default:
							ERR(@"inernal error.");
							break;
						}
					}
					[targets addObject:attach];
				}];
				if (targets.count == 0) {
					WRN(@"downloader has no targets");
					return;
				}
				// ダウンロード準備（UI）
				self.attachSaveButton.enabled			= NO;
				self.attachTable.enabled				= NO;
				self.attachSheetProgress.indeterminate	= NO;
				self.attachSheetProgress.doubleValue	= 0;
				// シート表示
				[self.window beginSheet:self.attachSheet
					  completionHandler:^(NSModalResponse returnCode) {
					[self.dlSheetRefreshTimer invalidate];
					self.dlSheetRefreshTimer = nil;
					[self.recvMsg removeDownloadedAttachments];
					[self buildIcons];
					dispatch_async(dispatch_get_main_queue(), ^{
						self.attachSaveButton.enabled = (self.attachTable.numberOfSelectedRows > 0);
						[self.attachTable reloadData];
						[self setAttachHeader];
						self.attachTable.enabled = YES;
						if (self.recvMsg.attachments.count <= 0) {
							[self.attachDrawer close];
							self.attachButton.enabled = NO;
						}
					});
				}];
				// ダウンロード（スレッド）開始
				self.dlSheetRefreshFlags = 0;
				self.dlStart = [NSDate date];
				self.download = [MessageCenter.sharedCenter startDownload:targets
																	   of:self.recvMsg.packetNo
																	 from:self.recvMsg.fromUser
																	   to:directory.path
																 delegate:self];
				self.dlSheetRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
																			target:self
																		  selector:@selector(downloadSheetRefresh:)
																		  userInfo:nil
																		   repeats:YES];
			} else {
				self.attachSaveButton.enabled = (self.attachTable.numberOfSelectedRows > 0);
			}
		}];
	} else if (sender == self.attachSheetCancelButton) {
		[MessageCenter.sharedCenter stopDownload:self.download];
	} else {
		DBG(@"Unknown button pressed(%@)", sender);
	}
}

// 封書ボタン押下時処理
- (IBAction)openSeal:(id)sender
{
	if (self.recvMsg.locked) {
		// 鍵付きの場合
		// フィールド／ラベルをクリア
		self.pwdSheetField.stringValue		= @"";
		self.pwdSheetErrorLabel.stringValue	= @"";
		// シート表示
		[self.window beginSheet:self.pwdSheet
			  completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSModalResponseOK) {
				dispatch_async(dispatch_get_main_queue(), ^{
					// 封書消去
					[self.sealButton removeFromSuperview];
					self.messageArea.hidden		= NO;
					self.replyButton.enabled	= YES;
					self.quotCheck.enabled		= YES;
					self.altLogButton.enabled	= Config.sharedConfig.alternateLogEnabled;
					if (self.recvMsg.attachments.count > 0) {
						self.attachButton.enabled = YES;
						[self.attachDrawer open];
					}
				});

				// ログ出力
				if (self.recvMsg.needLog) {
					[LogManager.standardLog writeRecvLog:self.recvMsg];
					self.recvMsg.needLog = NO;
				}

				// 封書開封通知送信
				[MessageCenter.sharedCenter sendOpenSealMessage:self.recvMsg];
			}
		}];
	} else {
		// 封書消去
		[self.sealButton removeFromSuperview];
		self.messageArea.hidden		= NO;
		self.replyButton.enabled	= YES;
		self.quotCheck.enabled		= YES;
		self.altLogButton.enabled	= Config.sharedConfig.alternateLogEnabled;
		if (self.recvMsg.attachments.count > 0) {
			self.attachButton.enabled = YES;
			[self.attachDrawer open];
		}

		// 封書開封通知送信
		[MessageCenter.sharedCenter sendOpenSealMessage:self.recvMsg];
	}
}

// 返信ボタン押下時処理
- (IBAction)replyMessage:(id)sender
{
	for (NSWindow* window in NSApp.orderedWindows) {
		if ([window.delegate isKindOfClass:SendControl.class]) {
			if ([((SendControl*)window.delegate).recvMsg isEqual:self.recvMsg]) {
				// 既に返信ウィンドウがあるので手前に出す
				[window makeKeyAndOrderFront:self];
				return;
			}
		}
	}
	Config*		config	= Config.sharedConfig;
	NSString*	quotMsg	= nil;
	if (self.quotCheck.state == NSControlStateValueOn) {
		NSString* quote = config.quoteString;

		// 選択範囲があれば選択範囲を引用、なければ全文引用
		NSRange	range = self.messageArea.selectedRange;
		if (range.length <= 0) {
			quotMsg = self.messageArea.string;
		} else {
			quotMsg = [self.messageArea.string substringWithRange:range];
		}
		if ((quotMsg.length > 0) && (quote.length > 0)) {
			// 引用文字を入れる
			NSArray<NSString*>*	lines	= [quotMsg componentsSeparatedByString:@"\n"];
			size_t				len		= quotMsg.length + (quote.length + 1) * lines.count;
			NSMutableString*	strBuf	= [NSMutableString stringWithCapacity:len];
			for (NSString* line in lines) {
				[strBuf appendString:quote];
				[strBuf appendString:line];
				[strBuf appendString:@"\n"];
			}
			quotMsg = strBuf;
		}
	}
	// 送信ダイアログ作成
	[[SendControl alloc] initWithSendMessage:quotMsg recvMessage:self.recvMsg];
}

// 重要ログボタン押下時処理
- (IBAction)writeAlternateLog:(id)sender
{
	if (Config.sharedConfig.logWithSelectedRange) {
		[LogManager.alternateLog writeRecvLog:self.recvMsg
									withRange:self.messageArea.selectedRange];
	} else {
		[LogManager.alternateLog writeRecvLog:self.recvMsg];
	}
	self.altLogButton.enabled = NO;
}

// パスワード入力シートOKボタン押下時処理
- (IBAction)okPwdSheet:(id)sender
{
	NSString*	password	= Config.sharedConfig.password;
	NSString*	input		= self.pwdSheetField.stringValue;

	// パスワードチェック
	if (password) {
		if (password.length > 0) {
			if (input.length <= 0) {
				self.pwdSheetErrorLabel.stringValue = NSLocalizedString(@"RecvDlg.PwdChk.NoPwd", nil);
				return;
			}
			if (![password isEqualToString:[NSString stringWithCString:crypt(input.UTF8String, "IP") encoding:NSUTF8StringEncoding]] &&
				![password isEqualToString:input]) {
				// 平文とも比較するのはv0.4までとの互換性のため
				self.pwdSheetErrorLabel.stringValue = NSLocalizedString(@"RecvDlg.PwdChk.PwdErr", nil);
				return;
			}
		}
	}

	[self.window endSheet:self.pwdSheet returnCode:NSModalResponseOK];
}

// パスワード入力シートキャンセルボタン押下時処理
- (IBAction)cancelPwdSheet:(id)sender
{
	[self.window endSheet:self.pwdSheet returnCode:NSModalResponseCancel];
}

// メッセージ部フォントパネル表示
- (IBAction)showReceiveMessageFontPanel:(id)sender
{
	[NSFontManager.sharedFontManager orderFrontFontPanel:self];
}

// メッセージ部フォント保存
- (IBAction)saveReceiveMessageFont:(id)sender
{
	Config.sharedConfig.receiveMessageFont = self.messageArea.font;
}

// メッセージ部フォントを標準に戻す
- (IBAction)resetReceiveMessageFont:(id)sender
{
	self.messageArea.font = Config.sharedConfig.defaultReceiveMessageFont;
}

// 一番奥のウィンドウを手前に移動
- (IBAction)backWindowToFront:(id)sender
{
	NSArray<NSWindow*>*	wins = NSApp.orderedWindows;
	for (NSInteger i = wins.count - 1; i >= 0; i--) {
		NSWindow* win = wins[i];
		if (win.visible && [win.delegate isKindOfClass:ReceiveControl.class]) {
			[win makeKeyAndOrderFront:self];
			break;
		}
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - 内部処理
/*----------------------------------------------------------------------------*/

// メニュー活殺判定
- (BOOL)validateMenuItem:(NSMenuItem*)item
{
	// 封書開封前はメニューとキーボードショートカットで返信できてしまわないようにする
	if ([item.keyEquivalent isEqualToString:@"r"] &&
		(item.keyEquivalentModifierMask & NSEventModifierFlagCommand)) {
		return self.replyButton.enabled;
	}
	return YES;
}

// アイコン一覧更新
- (void)buildIcons
{
	[self.icons removeAllObjects];
	for (RecvFile* attach in self.recvMsg.attachments) {
		NSImage* newIcon = [self iconImageForAttachment:attach];
		if (newIcon) {
			[newIcon setSize:NSMakeSize(16, 16)];
		} else {
			newIcon = [[[NSImage alloc] initWithSize:NSMakeSize(16,16)] autorelease];
		}
		[self.icons addObject:newIcon];
	}
}

// アイコンイメージ取得
- (NSImage*)iconImageForAttachment:(RecvFile*)attach
{
	NSWorkspace* ws = NSWorkspace.sharedWorkspace;

	// HFSファイルタイプ
	if (attach.hfsFileType != 0) {
		return [ws iconForFileType:NSFileTypeForHFSTypeCode(attach.hfsFileType)];
	}

	// ディレクトリ
	if (attach.type == ATTACH_TYPE_DIRECTORY) {
		return [ws iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
	}

	// 最後のたのみ拡張子
	return [ws iconForFileType:attach.name.pathExtension];
}

// 添付一覧ヘッダ部更新
- (void)setAttachHeader
{
	NSString* format	= NSLocalizedString(@"RecvDlg.Attach.Header", nil);
	NSString* title		= [NSString stringWithFormat:format, self.recvMsg.attachments.count];
	[self.attachTable tableColumnWithIdentifier:@"Attachment"].headerCell.stringValue = title;
}

// 添付一覧ダブルクリック時処理
- (void)attachTableDoubleClicked:(id)sender
{
	if (sender == self.attachTable) {
		[self buttonPressed:self.attachSaveButton];
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - Downloader
/*----------------------------------------------------------------------------*/

- (void)downloadSheetRefresh:(NSTimer*)timer
{
	if (self.dlSheetRefreshFlags & _AttachSheetRefreshTitle) {
		NSUInteger	num		= self.download.totalCount;
		NSInteger	index	= self.download.downloadedCount + 1;
		NSString*	format	= NSLocalizedString(@"RecvDlg.AttachSheet.Title", nil);
		NSString*	title	= [NSString stringWithFormat:format, index, num];
		self.attachSheetTitleLabel.stringValue = title;
	}
	if (self.dlSheetRefreshFlags & _AttachSheetRefreshFileName) {
		self.attachSheetFileNameLabel.stringValue = self.download.currentFileName;
	}
	if (self.dlSheetRefreshFlags & _AttachSheetRefreshFileNum) {
		self.attachSheetFileNumLabel.objectValue = @(self.download.downloadedFiles);
	}
	if (self.dlSheetRefreshFlags & _AttachSheetRefreshDirNum) {
		self.attachSheetDirNumLabel.objectValue = @(self.download.downloadedDirs);
	}
	if (self.dlSheetRefreshFlags & _AttachSheetRefreshTotalSize) {
		self.attachSheetProgress.maxValue = self.download.totalSize;
	}
	if (self.dlSheetRefreshFlags & _AttachSheetRefreshDownloadSize) {
		self.attachSheetProgress.doubleValue	= self.download.downloadedSize;
		if (self.download.downloadedSize > 0) {
			NSTimeInterval interval = -self.dlStart.timeIntervalSinceNow;
			if (interval > 0) {
				double bps = (self.download.downloadedSize / interval) / 1024.0f;
				if (bps < 1024) {
					self.attachSheetSpeedLabel.stringValue = [NSString stringWithFormat:@"%0.1f KBytes/sec", bps];
				} else {
					bps /= 1024.0;
					self.attachSheetSpeedLabel.stringValue = [NSString stringWithFormat:@"%0.2f MBytes/sec", bps];
				}
			}
		}
	}
	if ((self.dlSheetRefreshFlags & _AttachSheetRefreshTotalSize) ||
		(self.dlSheetRefreshFlags & _AttachSheetRefreshDownloadSize)) {
		double	downSize	= self.download.downloadedSize;
		double	totalSize	= self.download.totalSize;
		if (downSize > 0) {
			unsigned ratio = (unsigned)((downSize / totalSize) * 100 + 0.5);
			self.attachSheetPercentageLabel.stringValue = [NSString stringWithFormat:@"%d %%", ratio];
		}
		NSString* str = nil;
		if (totalSize < 1024) {
			str = [NSString stringWithFormat:@"%lld / %lld Bytes", (UInt64)downSize, (UInt64)totalSize];
		}
		if (!str) {
			downSize /= 1024.0;
			totalSize /= 1024.0;
			if (totalSize < 1024) {
				str = [NSString stringWithFormat:@"%.1f / %.1f KBytes", downSize, totalSize];
			}
		}
		if (!str) {
			downSize /= 1024.0;
			totalSize /= 1024.0;
			if (totalSize < 1024) {
				str = [NSString stringWithFormat:@"%.2f / %.2f MBytes", downSize, totalSize];
			}
		}
		if (!str) {
			downSize /= 1024.0;
			totalSize /= 1024.0;
			str = [NSString stringWithFormat:@"%.2f / %.2f GBytes", downSize, totalSize];
		}
		self.attachSheetSizeLabel.stringValue = str;
	}
	self.dlSheetRefreshFlags = 0;
}

- (void)downloadWillStart
{
	dispatch_sync(dispatch_get_main_queue(), ^{
		self.attachSheetCancelButton.enabled		= YES;
		self.attachSheetTitleLabel.stringValue		= NSLocalizedString(@"RecvDlg.AttachSheet.Start", nil);
		self.attachSheetFileNameLabel.stringValue	= @"";
		self.attachSheetProgress.maxValue			= self.download.totalSize;
		self.attachSheetProgress.doubleValue		= 0;
		self.dlSheetRefreshFlags = _AttachSheetRefreshFileNum
									| _AttachSheetRefreshDirNum
									| _AttachSheetRefreshTotalSize
									| _AttachSheetRefreshDownloadSize;
		[self downloadSheetRefresh:nil];
	});
}

- (void)downloadDidFinished:(DownloaderResult)result
{
	dispatch_sync(dispatch_get_main_queue(), ^{
		self.attachSheetCancelButton.enabled		= NO;
		self.attachSheetTitleLabel.stringValue		= NSLocalizedString(@"RecvDlg.AttachSheet.Finish", nil);
		self.attachSheetFileNameLabel.stringValue	= @"";
		self.dlSheetRefreshFlags = _AttachSheetRefreshFileNum
									| _AttachSheetRefreshDirNum
									| _AttachSheetRefreshTotalSize
									| _AttachSheetRefreshDownloadSize;
		[self downloadSheetRefresh:nil];
	});
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
		[self.window endSheet:self.attachSheet returnCode:NSModalResponseOK];
		if ((result != DL_SUCCESS) && (result != DL_STOP)) {
			NSString* msg = nil;
			switch (result) {
			case DL_TIMEOUT:				// 通信タイムアウト
				msg = NSLocalizedString(@"RecvDlg.DownloadError.TimeOut", nil);
				break;
			case DL_CONNECT_ERROR:		// 接続セラー
				msg = NSLocalizedString(@"RecvDlg.DownloadError.Connect", nil);
				break;
			case DL_DISCONNECTED:		// ソケット切断
				msg = NSLocalizedString(@"RecvDlg.DownloadError.Disconnected", nil);
				break;
			case DL_SOCKET_ERROR:		// ソケットエラー
				msg = NSLocalizedString(@"RecvDlg.DownloadError.Socket", nil);
				break;
			case DL_COMMUNICATION_ERROR:	// 送受信エラー
				msg = NSLocalizedString(@"RecvDlg.DownloadError.Communication", nil);
				break;
			case DL_FILE_OPEN_ERROR:		// ファイルオープンエラー
				msg = NSLocalizedString(@"RecvDlg.DownloadError.FileOpen", nil);
				break;
			case DL_INVALID_DATA:		// 異常データ受信
				msg = NSLocalizedString(@"RecvDlg.DownloadError.InvalidData", nil);
				break;
			case DL_INTERNAL_ERROR:		// 内部エラー
				msg = NSLocalizedString(@"RecvDlg.DownloadError.Internal", nil);
				break;
			case DL_SIZE_NOT_ENOUGH:		// ファイルサイズ異常
				msg = NSLocalizedString(@"RecvDlg.DownloadError.FileSize", nil);
				break;
			case DL_OTHER_ERROR:			// その他エラー
			default:
				msg = NSLocalizedString(@"RecvDlg.DownloadError.OtherError", nil);
				break;
			}
			NSAlert* alert = [[[NSAlert alloc] init] autorelease];
			alert.alertStyle		= NSAlertStyleCritical;
			alert.messageText		= NSLocalizedString(@"RecvDlg.DownloadError.Title", nil);
			alert.informativeText	= [NSString stringWithFormat:msg, result];
			[alert beginSheetModalForWindow:self.window completionHandler:nil];
		}
	});
}

- (void)downloadFileChanged
{
	self.dlSheetRefreshFlags |= _AttachSheetRefreshFileName;
}

- (void)downloadNumberOfFileChanged
{
	self.dlSheetRefreshFlags |= _AttachSheetRefreshFileNum;
}

- (void)downloadNumberOfDirectoryChanged
{
	self.dlSheetRefreshFlags |= _AttachSheetRefreshDirNum;
}

- (void)downloadIndexOfTargetChanged
{
	self.dlSheetRefreshFlags |= _AttachSheetRefreshTitle;
}

- (void)downloadTotalSizeChanged
{
	self.dlSheetRefreshFlags |= _AttachSheetRefreshTotalSize;
}

- (void)downloadDownloadedSizeChanged
{
	self.dlSheetRefreshFlags |= _AttachSheetRefreshDownloadSize;
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSTableView
/*----------------------------------------------------------------------------*/

- (NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
	if (aTableView == self.attachTable) {
		return self.recvMsg.attachments.count;
	} else {
		ERR(@"Unknown TableView(%@)", aTableView);
	}
	return 0;
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn
			row:(NSInteger)rowIndex
{
	if (aTableView == self.attachTable) {
		if (rowIndex >= self.recvMsg.attachments.count) {
			ERR(@"invalid index(row=%ld)", rowIndex);
			return nil;
		}
		RecvFile* attach = self.recvMsg.attachments[rowIndex];
		if (!attach) {
			ERR(@"no attachments(row=%ld)", rowIndex);
			return nil;
		}
		NSFileWrapper*		fw = [[[NSFileWrapper alloc] initRegularFileWithContents:[NSData data]] autorelease];
		NSTextAttachment*	ta = [[[NSTextAttachment alloc] initWithFileWrapper:fw] autorelease];
		((NSCell*)ta.attachmentCell).image = self.icons[rowIndex];
		NSMutableAttributedString* cellValue = [[[NSMutableAttributedString alloc] initWithString:attach.name] autorelease];
		[cellValue replaceCharactersInRange:NSMakeRange(0, 0)
					   withAttributedString:[NSAttributedString attributedStringWithAttachment:ta]];
		[cellValue addAttribute:NSBaselineOffsetAttributeName
						  value:[NSNumber numberWithFloat:-3.0]
						  range:NSMakeRange(0, 1)];
		return cellValue;
	} else {
		ERR(@"Unknown TableView(%@)", aTableView);
	}
	return nil;
}

// ユーザリストの選択変更
- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
	NSTableView* table = [aNotification object];
	if (table == self.attachTable) {
		NSIndexSet*	selects = self.attachTable.selectedRowIndexes;
		self.attachSaveButton.enabled = (selects.count > 0);
	} else {
		ERR(@"Unknown TableView(%@)", table);
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSWindows
/*----------------------------------------------------------------------------*/

// ウィンドウリサイズ時処理
- (void)windowDidResize:(NSNotification*)notification
{
	// ウィンドウサイズを保存
	Config.sharedConfig.receiveWindowSize = self.window.frame.size;
}

// ウィンドウクローズ判定処理
- (BOOL)windowShouldClose:(id)sender
{
	if (!self.closeConfirmed && !self.replyButton.enabled) {
		// 未開封だがクローズするか確認
		NSAlert* alert = [[[NSAlert alloc] init] autorelease];
		alert.alertStyle		= NSAlertStyleWarning;
		alert.messageText		= NSLocalizedString(@"RecvDlg.CloseWithSeal.Title", nil);
		alert.informativeText	= NSLocalizedString(@"RecvDlg.CloseWithSeal.Msg", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"RecvDlg.CloseWithSeal.OK", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"RecvDlg.CloseWithSeal.Cancel", nil)];
		__weak typeof(self)	weakSelf = self;
		[alert beginSheetModalForWindow:self.window
					  completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSAlertFirstButtonReturn) {
				weakSelf.closeConfirmed = YES;
				dispatch_async(dispatch_get_main_queue(), ^() {
					[weakSelf.window performClose:self];
				});
			}
		}];
		return NO;
	}
	if (!self.closeConfirmed && (self.recvMsg.attachments.count > 0)) {
		// 添付ファイルが残っているがクローズするか確認
		NSAlert* alert = [[[NSAlert alloc] init] autorelease];
		alert.alertStyle		= NSAlertStyleWarning;
		alert.messageText		= NSLocalizedString(@"RecvDlg.CloseWithAttach.Title", nil);
		alert.informativeText	= NSLocalizedString(@"RecvDlg.CloseWithAttach.Msg", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"RecvDlg.CloseWithAttach.OK", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"RecvDlg.CloseWithAttach.Cancel", nil)];
		__weak typeof(self)	weakSelf = self;
		[alert beginSheetModalForWindow:self.window
					  completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSAlertFirstButtonReturn) {
				weakSelf.closeConfirmed = YES;
				dispatch_async(dispatch_get_main_queue(), ^() {
					[weakSelf.window performClose:self];
				});
			}
		}];
		[self.attachDrawer open];
		return NO;
	}

	return YES;
}

// ウィンドウクローズ時処理
- (void)windowWillClose:(NSNotification*)aNotification
{
	if (self.recvMsg.attachments.count > 0) {
		// 添付ファイルが残っている場合破棄通知
		[MessageCenter.sharedCenter sendReleaseAttachmentMessage:self.recvMsg];
	}
	[self release];
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSObject
/*----------------------------------------------------------------------------*/

// Nibファイルロード時処理
- (void)awakeFromNib
{
	Config* config		= Config.sharedConfig;
	NSSize	cfgSize		= config.receiveWindowSize;
	NSSize	screenSize	= NSScreen.mainScreen.visibleFrame.size;
	NSRect	frame		= self.window.frame;

	// ウィンドウ位置、サイズ決定
	int sw	= screenSize.width;
	int sh	= screenSize.height;
	int ww	= frame.size.width;
	int wh	= frame.size.height;
	frame.origin.x = (sw - ww) / 2 + (arc4random_uniform(INT32_MAX) % (sw / 4)) - sw / 8;
	frame.origin.y = (sh - wh) / 2 + (arc4random_uniform(INT32_MAX) % (sh / 4)) - sh / 8;
	if (cfgSize.width != 0) {
		frame.size.width = cfgSize.width;
	}
	if (cfgSize.height != 0) {
		frame.size.height= cfgSize.height;
	}
	[self.window setFrame:frame display:NO];

	// 引用チェックをデフォルト判定
	if (config.quoteCheckDefault) {
		self.quotCheck.state = NSControlStateValueOn;
	}

	// 添付リストの行設定
	self.attachTable.rowHeight = 16.0;

	// 添付テーブルダブルクリック時処理
	self.attachTable.doubleAction = @selector(attachTableDoubleClicked:);

//	attachSheetProgress.usesThreadedAnimation = YES;
}

@end
