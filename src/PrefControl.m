/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: PrefControl.m
 *	Module		: 環境設定パネルコントローラ
 *============================================================================*/

#import "PrefControl.h"
#import "AppControl.h"
#import "Config.h"
#import "RefuseInfo.h"
#import "MessageCenter.h"
#import "UserManager.h"
#import "LogManager.h"
#import "DebugLog.h"

#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/*============================================================================*
 * 定数定義
 *============================================================================*/

#define	_BETA_MODE	(0)				// betaバージョン以外では無効(0)にすること

#define EVERY_DAY	(60 * 60 * 24)
#define EVERY_WEEK	(EVERY_DAY * 7)
#define EVERY_MONTH	(EVERY_DAY * 30)

/*============================================================================*
 * マクロ定義
 *============================================================================*/

#define _Bool2State(val)	((val) ? NSControlStateValueOn : NSControlStateValueOff)
#define _State2Bool(val)	((val) == NSControlStateValueOn)

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation PrefControl

/*----------------------------------------------------------------------------*/
#pragma mark - 公開メソッド
/*----------------------------------------------------------------------------*/

// 表示を最新化する
- (void)update
{
	Config* config = Config.sharedConfig;

	// 全般タブ
	self.baseUserNameField.stringValue		= config.userName;
	self.baseGroupNameField.stringValue		= config.groupName;
	self.receiveStatusBarCheckBox.state		= _Bool2State(config.useStatusBar);

	// 送信タブ
	self.sendQuotField.stringValue			= config.quoteString;
	self.sendSingleClickCheck.state			= _Bool2State(config.openNewOnDockClick);
	self.sendDefaultSealCheck.state			= _Bool2State(config.sealCheckDefault);
	self.sendHideWhenReplyCheck.state		= _Bool2State(config.hideReceiveWindowOnReply);
	self.sendOpenNotifyCheck.state			= _Bool2State(config.noticeSealOpened);
	self.sendMultipleUserCheck.state		= _Bool2State(config.allowSendingToMultiUser);
	// 受信タブ
	if (config.receiveSoundName.length > 0) {
		[self.receiveSoundPopup selectItemWithTitle:config.receiveSoundName];
	} else {
		[self.receiveSoundPopup selectItemAtIndex:0];
	}
	self.receiveDefaultQuotCheck.state		= _Bool2State(config.quoteCheckDefault);
	self.receiveNonPopupCheck.state			= _Bool2State(config.nonPopup);
	self.receiveNonPopupModeMatrix.enabled	= _Bool2State(config.nonPopup);
	self.receiveNonPopupBoundMatrix.enabled	= _Bool2State(config.nonPopup);
	[self.receiveNonPopupBoundMatrix selectCellWithTag:config.iconBoundModeInNonPopup];
	if (config.nonPopupWhenAbsence) {
		[self.receiveNonPopupModeMatrix selectCellAtRow:1 column:0];
	}
	self.receiveClickableURLCheck.state		= _Bool2State(config.useClickableURL);

	// ネットワークタブ
	self.netPortNoField.integerValue		= config.portNo;
	self.netDialupCheck.state				= _Bool2State(config.dialup);

	// ログタブ
	self.logStdEnableCheck.state			= _Bool2State(config.standardLogEnabled);
	self.logStdWhenOpenChainCheck.state		= _Bool2State(config.logChainedWhenOpen);
	self.logStdWhenOpenChainCheck.enabled	= config.standardLogEnabled;
	self.logStdPathField.stringValue		= config.standardLogFile;
	self.logStdPathField.enabled			= config.standardLogEnabled;
	self.logStdPathRefButton.enabled		= config.standardLogEnabled;
	self.logAltEnableCheck.state			= _Bool2State(config.alternateLogEnabled);
	self.logAltSelectionCheck.state			= _Bool2State(config.logWithSelectedRange);
	self.logAltSelectionCheck.enabled		= config.alternateLogEnabled;
	self.logAltPathField.stringValue		= config.alternateLogFile;
	self.logAltPathField.enabled			= config.alternateLogEnabled;
	self.logAltPathRefButton.enabled		= config.alternateLogEnabled;

#if _BETA_MODE
	// 強制的にソフトウェアアップデートを行うように設定する
	config.updateAutomaticCheck	= YES;
	config.updateCheckInterval	= 60 * 60 * 12;
#endif

	// アップデートタブ
	self.updateCheckAutoCheck.state			= _Bool2State(config.updateAutomaticCheck);
	self.updateTypeMatrix.enabled			= config.updateAutomaticCheck;
	if (config.updateCheckInterval == EVERY_MONTH) {
		[self.updateTypeMatrix selectCellWithTag:3];
	} else if (config.updateCheckInterval == EVERY_WEEK) {
		[self.updateTypeMatrix selectCellWithTag:2];
	} else {
		[self.updateTypeMatrix selectCellWithTag:1];
	}
#if _BETA_MODE
	// 変更できないようにする
	self.updateCheckAutoCheck.enabled		= NO;
	self.updateTypeMatrix.enabled			= NO;
#else
	self.updateBetaTestLabel.hidden			= YES;
#endif
}

/*----------------------------------------------------------------------------*/
#pragma mark - イベントハンドラ
/*----------------------------------------------------------------------------*/

- (IBAction)buttonPressed:(id)sender
{
	// パスワード変更ボタン（シートオープン）
	if (sender == self.basePasswordButton) {
		NSString* password = Config.sharedConfig.password;
		// フィールドの内容を最新に
		self.pwdSheetOldPwdField.enabled		= NO;
		self.pwdSheet.initialFirstResponder		= self.pwdSheetNewPwdField1;
		if (password.length > 0) {
			self.pwdSheetOldPwdField.enabled	= YES;
			self.pwdSheet.initialFirstResponder	= self.pwdSheetOldPwdField;
		}
		self.pwdSheetOldPwdField.stringValue	= @"";
		self.pwdSheetNewPwdField1.stringValue	= @"";
		self.pwdSheetNewPwdField2.stringValue	= @"";
		self.pwdSheetErrorLabel.stringValue		= @"";
		// シート表示
		[self.panel beginSheet:self.pwdSheet completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSModalResponseOK) {
				// パスワード値変更
				NSString* newPwd = self.pwdSheetNewPwdField1.stringValue;
				if (newPwd.length > 0) {
					char* encPwd = crypt(newPwd.UTF8String, "IP");
					Config.sharedConfig.password = [NSString stringWithCString:encPwd
																	  encoding:NSUTF8StringEncoding];
				} else {
					Config.sharedConfig.password = @"";
				}
			}
		}];
	}
	// パスワード変更シート変更（OK）ボタン
	else if (sender == self.pwdSheetOKButton) {
		NSString* oldPwd	= self.pwdSheetOldPwdField.stringValue;
		NSString* newPwd1	= self.pwdSheetNewPwdField1.stringValue;
		NSString* newPwd2	= self.pwdSheetNewPwdField2.stringValue;
		NSString* password	= Config.sharedConfig.password;
		self.pwdSheetErrorLabel.stringValue	= @"";
		// 旧パスワードチェック
		if (password) {
			if (password.length > 0) {
				if (oldPwd.length <= 0) {
					self.pwdSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.PwdMod.NoOldPwd", nil);
					return;
				}
				char* encPwd = crypt(oldPwd.UTF8String, "IP");
				if (![password isEqualToString:[NSString stringWithCString:encPwd
																  encoding:NSUTF8StringEncoding]] &&
					![password isEqualToString:oldPwd]) {
					// 平文とも比較するのはv0.4までとの互換性のため
					self.pwdSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.PwdMod.OldPwdErr", nil);
					return;
				}
			}
		}
		// 新パスワード２回入力チェック
		if (![newPwd1 isEqualToString:newPwd2]) {
			self.pwdSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.PwdMod.NewPwdErr", nil);
			return;
		}
		// ここまでくれば正しいのでパスワード値変更
		[self.panel endSheet:self.pwdSheet returnCode:NSModalResponseOK];
	}
	// パスワード変更シートキャンセルボタン
	else if (sender == self.pwdSheetCancelButton) {
		[self.panel endSheet:self.pwdSheet returnCode:NSModalResponseCancel];
	}
	// ブロードキャストアドレス追加ボタン（シートオープン）
	else if (sender == self.netBroadAddButton) {
		// フィールドの内容を初期化
		self.bcastSheetField.stringValue		= @"";
		self.bcastSheetErrorLabel.stringValue	= @"";
		[self.bcastSheetMatrix selectCellAtRow:0 column:0];
		self.bcastSheetResolveCheck.enabled		= NO;
		self.bcastSheet.initialFirstResponder	= self.bcastSheetField;

		// シート表示
		[self.panel beginSheet:self.bcastSheet completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSModalResponseOK) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.netBroadAddressTable reloadData];
				});
			}
		}];
	}
	// ブロードキャストアドレス削除ボタン
	else if (sender == self.netBroadDeleteButton) {
		NSInteger index = self.netBroadAddressTable.selectedRow;
		if (index != -1) {
			[Config.sharedConfig removeBroadcastAtIndex:index];
			[self.netBroadAddressTable reloadData];
			[self.netBroadAddressTable deselectAll:self];
		}
	}
	// ブロードキャストシートOKボタン
	else if (sender == self.bcastSheetOKButton) {
		Config*		config	= [Config sharedConfig];
		NSString*	string	= self.bcastSheetField.stringValue;
		BOOL		ip		= (self.bcastSheetMatrix.selectedColumn == 0);
		// 入力文字列チェック
		if (string.length <= 0) {
			if (ip) {
				self.bcastSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Broadcast.EmptyIP", nil);
			} else {
				self.bcastSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Broadcast.EmptyHost", nil);
			}
			return;
		}
		// IPアドレス設定の場合
		if (ip) {
			in_addr_t	 	inetaddr = inet_addr(string.UTF8String);
			struct in_addr	addr;
			NSString*		strAddr;
			if (inetaddr == INADDR_NONE) {
				self.bcastSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Broadcast.WrongIP", nil);
				return;
			}
			addr.s_addr = inetaddr;
			strAddr		= [NSString stringWithCString:inet_ntoa(addr) encoding:NSUTF8StringEncoding];
			if ([config containsBroadcastWithAddress:strAddr]) {
				self.bcastSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Broadcast.ExistIP", nil);
				return;
			}
			[config addBroadcastWithAddress:strAddr];
		}
		// ホスト名設定の場合
		else {
			// アドレス確認
			if (self.bcastSheetResolveCheck.state == NSControlStateValueOn) {
				if (![[NSHost hostWithName:string] address]) {
					self.bcastSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Broadcast.UnknownHost", nil);
					return;
				}
			}
			if ([config containsBroadcastWithHost:string]) {
				self.bcastSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Broadcast.ExistHost", nil);
				return;
			}
			[config addBroadcastWithHost:string];
		}
		self.bcastSheetErrorLabel.stringValue = @"";
		[self.panel endSheet:self.bcastSheet returnCode:NSModalResponseOK];
	}
	// ブロードキャストシートキャンセルボタン
	else if (sender == self.bcastSheetCancelButton) {
		[self.panel endSheet:self.bcastSheet returnCode:NSModalResponseCancel];
	}
	// 不在追加ボタン／編集ボタン
	else if ((sender == self.absenceAddButton) || (sender == self.absenceEditButton)) {
		NSString* title	= @"";
		NSString* msg	= @"";
		self.absenceEditIndex = -1;
		if (sender == self.absenceEditButton) {
			self.absenceEditIndex = self.absenceTable.selectedRow;
			Config* config	= Config.sharedConfig;
			title			= [config absenceTitleAtIndex:self.absenceEditIndex];
			msg				= [config absenceMessageAtIndex:self.absenceEditIndex];
		}
		// フィールドの内容を初期化
		self.absenceSheetTitleField.stringValue	= title;
		self.absenceSheetMessageArea.string		= msg;
		self.absenceSheetErrorLabel.stringValue	= @"";
		self.absenceSheet.initialFirstResponder	= self.absenceSheetTitleField;

		// シート表示
		[self.panel beginSheet:self.absenceSheet completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSModalResponseOK) {
				// NOP
			}
		}];
	}
	// 不在削除ボタン
	else if (sender == self.absenceDeleteButton) {
		Config*		config	= Config.sharedConfig;
		NSInteger	absIdx	= config.absenceIndex;
		NSInteger	rmvIdx	= self.absenceTable.selectedRow;
		[config removeAbsenceAtIndex:rmvIdx];
		if (rmvIdx == absIdx) {
			config.absenceIndex = -1;
			[MessageCenter.sharedCenter broadcastAbsence];
		} else if (rmvIdx < absIdx) {
			config.absenceIndex = absIdx - 1;
		}
		[self.absenceTable reloadData];
		[self.absenceTable deselectAll:self];
		[(AppControl*)NSApp.delegate buildAbsenceMenu];
	}
	// 不在上へボタン
	else if (sender == self.absenceUpButton) {
		Config*		config	= Config.sharedConfig;
		NSInteger	absIdx	= config.absenceIndex;
		NSInteger	upIdx	= self.absenceTable.selectedRow;
		[config upAbsenceAtIndex:upIdx];
		if (upIdx == absIdx) {
			config.absenceIndex = absIdx - 1;
		} else if (upIdx == absIdx + 1) {
			config.absenceIndex = absIdx + 1;
		}
		[self.absenceTable reloadData];
		[self.absenceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:upIdx-1] byExtendingSelection:NO];
		[(AppControl*)NSApp.delegate buildAbsenceMenu];
	}
	// 不在下へボタン
	else if (sender == self.absenceDownButton) {
		Config*		config	= Config.sharedConfig;
		NSInteger	absIdx	= config.absenceIndex;
		NSInteger	downIdx	= self.absenceTable.selectedRow;
		NSInteger	index	= self.absenceTable.selectedRow;
		[config downAbsenceAtIndex:downIdx];
		if (downIdx == absIdx) {
			config.absenceIndex = absIdx + 1;
		} else if (downIdx == absIdx - 1) {
			config.absenceIndex = absIdx - 1;
		}
		[self.absenceTable reloadData];
		[self.absenceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index+1] byExtendingSelection:NO];
		[(AppControl*)NSApp.delegate buildAbsenceMenu];
	}
	// 不在定義初期化ボタン
	else if (sender == self.absenceResetButton) {
		// 不在定義リセットの確認
		NSAlert* alert = [[[NSAlert alloc] init] autorelease];
		alert.alertStyle		= NSAlertStyleWarning;
		alert.messageText		= NSLocalizedString(@"Pref.AbsenceReset.Title", nil);
		alert.informativeText	= NSLocalizedString(@"Pref.AbsenceReset.Msg", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"Pref.AbsenceReset.OK", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Pref.AbsenceReset.Cancel", nil)];
		[alert beginSheetModalForWindow:self.panel completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSAlertFirstButtonReturn) {
				// 不在定義をリセット
				dispatch_async(dispatch_get_main_queue(), ^() {
					[Config.sharedConfig resetAllAbsences];
					[self.absenceTable reloadData];
					[self.absenceTable deselectAll:self];
					[(AppControl*)NSApp.delegate buildAbsenceMenu];
				});
			}
		}];
	}
	// 不在シートOKボタン
	else if (sender == self.absenceSheetOKButton) {
		Config*		config	= Config.sharedConfig;
		NSString*	title	= self.absenceSheetTitleField.stringValue;
		NSString*	msg		= [NSString stringWithString:self.absenceSheetMessageArea.string];
		NSInteger	index	= self.absenceTable.selectedRow;
		NSInteger	absIdx	= config.absenceIndex;
		self.absenceSheetErrorLabel.stringValue = @"";
		// タイトルチェック
		if (title.length <= 0) {
			self.absenceSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Absence.NoTitle", nil);
			return;
		}
		if (msg.length <= 0) {
			self.absenceSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Absence.NoMessage", nil);
			return;
		}
		if (self.absenceEditIndex == -1) {
			if ([config containsAbsenceTitle:title]) {
				self.absenceSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Absence.ExistTitle", nil);
				return;
			}
			if (index == -1) {
				[config addAbsenceTitle:title message:msg];
			} else {
				[config insertAbsenceTitle:title message:msg atIndex:index];
			}
			if ((index != -1) && (absIdx != -1) && (index <= absIdx)) {
				config.absenceIndex = absIdx + 1;
			}
		} else {
			[config setAbsenceTitle:title message:msg atIndex:index];
			if (absIdx == index) {
				[MessageCenter.sharedCenter broadcastAbsence];
			}
		}
		[self.absenceTable reloadData];
		[self.absenceTable deselectAll:self];
		[self.absenceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:((index == -1) ? 0 : (index))]
					   byExtendingSelection:NO];
		[(AppControl*)NSApp.delegate buildAbsenceMenu];
		[self.panel endSheet:self.absenceSheet returnCode:NSModalResponseOK];
	}
	// 不在シートCancelボタン
	else if (sender == self.absenceSheetCancelButton) {
		[self.panel endSheet:self.absenceSheet returnCode:NSModalResponseCancel];
	}
	// 通知拒否追加ボタン／編集ボタン
	else if ((sender == self.refuseAddButton) || (sender == self.refuseEditButton)) {
		IPRefuseTarget		target		= 0;
		NSString* 			string		= @"";
		IPRefuseCondition	condition	= 0;

		self.refuseEditIndex	= -1;
		if (sender == self.refuseEditButton) {
			self.refuseEditIndex	= self.refuseTable.selectedRow;
			RefuseInfo*	info = [Config.sharedConfig refuseInfoAtIndex:self.refuseEditIndex];
			target		= info.target;
			string		= info.string;
			condition	= info.condition;
		}
		// フィールドの内容を初期化
		self.refuseSheetField.stringValue		= string;
		[self.refuseSheetTargetPopup selectItemAtIndex:target];
		[self.refuseSheetCondPopup selectItemAtIndex:condition];
		self.refuseSheetErrorLabel.stringValue	= @"";
		self.refuseSheet.initialFirstResponder	= self.refuseSheetTargetPopup;

		// シート表示
		[self.panel beginSheet:self.refuseSheet completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSModalResponseOK) {
				// NOP
			}
		}];
	}
	// 通知拒否削除ボタン
	else if (sender == self.refuseDeleteButton) {
		[Config.sharedConfig removeRefuseInfoAtIndex:self.refuseTable.selectedRow];
		[self.refuseTable reloadData];
		[self.refuseTable deselectAll:self];
// broadcast entry?
	}
	// 通知拒否上へボタン
	else if (sender == self.refuseUpButton) {
		NSInteger index = self.refuseTable.selectedRow;
		[Config.sharedConfig upRefuseInfoAtIndex:index];
		[self.refuseTable reloadData];
		[self.refuseTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index-1] byExtendingSelection:NO];
// broadcast entry?
	}
	// 通知拒否下へボタン
	else if (sender == self.refuseDownButton) {
		NSInteger index = self.refuseTable.selectedRow;
		[Config.sharedConfig downRefuseInfoAtIndex:index];
		[self.refuseTable reloadData];
		[self.refuseTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index+1] byExtendingSelection:NO];
// broadcast entry?
	}
	// 通知拒否シートOKボタン
	else if (sender == self.refuseSheetOKButton) {
		Config*				cfg			= Config.sharedConfig;
		IPRefuseTarget		target		= self.refuseSheetTargetPopup.indexOfSelectedItem;
		NSString*			string		= self.refuseSheetField.stringValue;
		IPRefuseCondition	condition	= self.refuseSheetCondPopup.indexOfSelectedItem;
		NSInteger			index		= self.refuseTable.selectedRow;
		// 入力文字チェック
		if (string.length <= 0) {
			self.refuseSheetErrorLabel.stringValue = NSLocalizedString(@"Pref.Refuse.Error.NoInput", nil);
			return;
		}

		RefuseInfo* info = [[[RefuseInfo alloc] initWithTarget:target string:string condition:condition] autorelease];
		if (self.refuseEditIndex == -1) {
			// 新規
			if (index == -1) {
				[cfg addRefuseInfo:info];
			} else {
				[cfg insertRefuseInfo:info atIndex:index];
			}
			[self.refuseTable deselectAll:self];
		} else {
			// 変更
			[cfg setRefuseInfo:info atIndex:self.refuseEditIndex];
		}
		[self.refuseTable reloadData];
		[self.panel endSheet:self.refuseSheet returnCode:NSModalResponseOK];
	}
	// 通知拒否シートCancelボタン
	else if (sender == self.refuseSheetCancelButton) {
		[self.panel endSheet:self.refuseSheet returnCode:NSModalResponseCancel];
	}
	// 標準ログファイル参照ボタン／重要ログファイル参照ボタン
	else if ((sender == self.logStdPathRefButton) || (sender == self.logAltPathRefButton)) {
		NSSavePanel*	sp = NSSavePanel.savePanel;
		NSString*		orgPath;
		// SavePanel 設定
		if (sender == self.logStdPathRefButton) {
			orgPath = Config.sharedConfig.standardLogFile;
		} else {
			orgPath = Config.sharedConfig.alternateLogFile;
		}
		sp.prompt				= NSLocalizedString(@"Log.File.SaveSheet.OK", nil);
		sp.directoryURL			= [NSURL fileURLWithPath:orgPath.stringByDeletingLastPathComponent];
		sp.nameFieldStringValue = orgPath.lastPathComponent;
		// シート表示
		[sp beginSheetModalForWindow:self.panel completionHandler:^(NSInteger result) {
			if (result == NSModalResponseOK) {
				NSString* fn = [sp.URL.path stringByAbbreviatingWithTildeInPath];
				// 標準ログ選択
				if (sender == self.logStdPathRefButton) {
					Config.sharedConfig.standardLogFile	= fn;
					self.logStdPathField.stringValue	= fn;
				}
				// 重要ログ選択
				else {
					Config.sharedConfig.alternateLogFile	= fn;
					self.logAltPathField.stringValue		= fn;
				}
			}
		}];
	}
	// その他（バグ）
	else {
		ERR(@"unknwon button pressed. %@", sender);
	}
}

/*----------------------------------------------------------------------------*
 *  Matrix変更時処理
 *----------------------------------------------------------------------------*/

- (IBAction)matrixChanged:(id)sender
{
	Config* config = Config.sharedConfig;
	// 受信：ノンポップアップ受信モード
	if (sender == self.receiveNonPopupModeMatrix) {
		config.nonPopupWhenAbsence = (self.receiveNonPopupModeMatrix.selectedRow == 1);
	}
	// 受信：ノンポップアップ時アイコンバウンド設定
	else if (sender == self.receiveNonPopupBoundMatrix) {
		config.iconBoundModeInNonPopup = self.receiveNonPopupBoundMatrix.selectedCell.tag;
	}
	// ブロードキャスト種別
	else if (sender == self.bcastSheetMatrix) {
		self.bcastSheetResolveCheck.enabled	= (self.bcastSheetMatrix.selectedColumn == 1);
	}
	// アップデートチェック種別
	else if (sender == self.updateTypeMatrix) {
		switch (self.updateTypeMatrix.selectedCell.tag) {
		case 1:
			config.updateCheckInterval = EVERY_DAY;
			break;
		case 2:
			config.updateCheckInterval = EVERY_WEEK;
			break;
		case 3:
			config.updateCheckInterval = EVERY_MONTH;
			break;
		}
	}
	// その他
	else {
		ERR(@"unknown matrix changed. %@", sender);
	}
}

/*----------------------------------------------------------------------------*
 *  テキストフィールド変更時処理
 *----------------------------------------------------------------------------*/

- (BOOL)control:(NSControl*)control textShouldEndEditing:(NSText*)fieldEditor
{
	// 全般：ユーザ名
	if (control == self.baseUserNameField) {
		NSRange r = [fieldEditor.string rangeOfString:@":"];
		if (r.location != NSNotFound) {
			return NO;
		}
	}
	// 全般：グループ名
	else if (control == self.baseGroupNameField) {
		NSRange r = [fieldEditor.string rangeOfString:@":"];
		if (r.location != NSNotFound) {
			return NO;
		}
	}
	return YES;
}

- (void)controlTextDidEndEditing:(NSNotification*)aNotification
{
	Config* config	= Config.sharedConfig;
	id		obj		= aNotification.object;
	// 全般：ユーザ名
	if (obj == self.baseUserNameField) {
		config.userName	= self.baseUserNameField.stringValue;
		[MessageCenter.sharedCenter broadcastAbsence];
	}
	// 全般：グループ名
	else if (obj == self.baseGroupNameField) {
		config.groupName = self.baseGroupNameField.stringValue;
		[MessageCenter.sharedCenter broadcastAbsence];
	}
	// 全般：ポート番号
	else if (obj == self.netPortNoField) {
		config.portNo = self.netPortNoField.integerValue;
	}
	// 送信：引用文字列
	else if (obj == self.sendQuotField) {
		config.quoteString = self.sendQuotField.stringValue;
	}
	// ログ：標準ログ
	else if (obj == self.logStdPathField) {
		NSString* path = self.logStdPathField.stringValue;
		config.standardLogFile			= path;
		LogManager.standardLog.filePath	= path;
	}
	// ログ：重要ログ
	else if (obj == self.logAltPathField) {
		NSString* path = self.logAltPathField.stringValue;
		config.alternateLogFile				= path;
		LogManager.alternateLog.filePath	= path;
	}
	// その他（バグ）
	else {
		ERR(@"unknwon text end edit. %@", obj);
	}
}

/*----------------------------------------------------------------------------*
 *  チェックボックス変更時処理
 *----------------------------------------------------------------------------*/

- (IBAction)checkboxChanged:(id)sender
{
	Config* config = Config.sharedConfig;
	// 全般：ステータスバーを使用するか
	if (sender == self.receiveStatusBarCheckBox) {
		AppControl* appCtl = (AppControl*)NSApp.delegate;
		config.useStatusBar = _State2Bool(self.receiveStatusBarCheckBox.state);
		if (config.useStatusBar) {
			[appCtl initStatusBar];
		} else {
			[appCtl removeStatusBar];
		}
	}
	// 送信：DOCKのシングルクリックで新規送信ウィンドウ
	else if (sender == self.sendSingleClickCheck) {
		config.openNewOnDockClick = _State2Bool(self.sendSingleClickCheck.state);
	}
	// 送信：引用チェックをデフォルト
	else if (sender == self.sendDefaultSealCheck) {
		config.sealCheckDefault = _State2Bool(self.sendDefaultSealCheck.state);
	}
	// 送信：返信時に受信ウィンドウをクローズ
	else if (sender == self.sendHideWhenReplyCheck) {
		config.hideReceiveWindowOnReply = _State2Bool(self.sendHideWhenReplyCheck.state);
	}
	// 送信：開封通知を行う
	else if (sender == self.sendOpenNotifyCheck) {
		config.noticeSealOpened = _State2Bool(self.sendOpenNotifyCheck.state);
	}
	// 送信：複数ユーザ宛送信を許可
	else if (sender == self.sendMultipleUserCheck) {
		config.allowSendingToMultiUser = _State2Bool(self.sendMultipleUserCheck.state);
	}
	// 受信：引用チェックをデフォルト
	else if (sender == self.receiveDefaultQuotCheck) {
		config.quoteCheckDefault = _State2Bool(self.receiveDefaultQuotCheck.state);
	}
	// 受信：ノンポップアップ受信
	else if (sender == self.receiveNonPopupCheck) {
		config.nonPopup = _State2Bool(self.receiveNonPopupCheck.state);
		self.receiveNonPopupModeMatrix.enabled	= _State2Bool(self.receiveNonPopupCheck.state);
		self.receiveNonPopupBoundMatrix.enabled	= _State2Bool(self.receiveNonPopupCheck.state);
	}
	// 受信：クリッカブルURL
	else if (sender == self.receiveClickableURLCheck) {
		config.useClickableURL = _State2Bool(self.receiveClickableURLCheck.state);
	}
	// ネットワーク：ダイアルアップ接続
	else if (sender == self.netDialupCheck) {
		config.dialup = _State2Bool(self.netDialupCheck.state);
	}
	// ログ：標準ログを使用する
	else if (sender == self.logStdEnableCheck) {
		BOOL enable = _State2Bool(self.logStdEnableCheck.state);
		config.standardLogEnabled				= enable;
		self.logStdPathField.enabled			= enable;
		self.logStdWhenOpenChainCheck.enabled	= enable;
		self.logStdPathRefButton.enabled		= enable;
	}
	// ログ：錠前付きは開封後にログ
	else if (sender == self.logStdWhenOpenChainCheck) {
		config.logChainedWhenOpen = _State2Bool(self.logStdWhenOpenChainCheck.state);
	}
	// ログ：重要ログを使用する
	else if (sender == self.logAltEnableCheck) {
		BOOL enable = _State2Bool(self.logAltEnableCheck.state);
		config.alternateLogEnabled			= enable;
		self.logAltPathField.enabled		= enable;
		self.logAltSelectionCheck.enabled	= enable;
		self.logAltPathRefButton.enabled	= enable;
	}
	// ログ：選択範囲を記録
	else if (sender == self.logAltSelectionCheck) {
		config.logWithSelectedRange = _State2Bool(self.logAltSelectionCheck.state);
	}
	// アップデート：自動チェック
	else if (sender == self.updateCheckAutoCheck) {
		BOOL check = _State2Bool(self.updateCheckAutoCheck.state);
		config.updateAutomaticCheck		= check;
		self.updateTypeMatrix.enabled	= check;
	}
	// 不明（バグ）
	else {
		ERR(@"unknwon chackbox changed. %@", sender);
	}
}

/*----------------------------------------------------------------------------*
 *  プルダウン変更時処理
 *----------------------------------------------------------------------------*/

- (IBAction)popupChanged:(id)sender
{
	Config* config = Config.sharedConfig;
	// 受信音
	if (sender == self.receiveSoundPopup) {
		if (self.receiveSoundPopup.indexOfSelectedItem > 0) {
			config.receiveSoundName = self.receiveSoundPopup.titleOfSelectedItem;
			[config.receiveSound play];
		} else {
			config.receiveSoundName = nil;
		}
	}
	// その他（バグ）
	else {
		ERR(@"unknown popup changed. %@", sender);
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSTableView
/*----------------------------------------------------------------------------*/

- (NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
	// ブロードキャスト
	if (aTableView == self.netBroadAddressTable) {
		return Config.sharedConfig.numberOfBroadcasts;
	}
	// 不在
	else if (aTableView == self.absenceTable) {
		return Config.sharedConfig.numberOfAbsences;
	}
	// 通知拒否
	else if (aTableView == self.refuseTable) {
		return Config.sharedConfig.numberOfRefuseInfo;
	}
	// その他（バグ）
	else {
		ERR(@"number of rows in unknown table (%@)", aTableView);
	}
	return 0;
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn
			row:(NSInteger)rowIndex
{
	// ブロードキャスト
	if (aTableView == self.netBroadAddressTable) {
		return [Config.sharedConfig broadcastAtIndex:rowIndex];
	}
	// 不在
	else if (aTableView == self.absenceTable) {
		return [Config.sharedConfig absenceTitleAtIndex:rowIndex];
	}
	// 通知拒否リスト
	else if (aTableView == self.refuseTable) {
		return [Config.sharedConfig refuseInfoAtIndex:rowIndex];
	}
	// その他（バグ）
	else {
		ERR(@"object in unknown table (%@)", aTableView);
	}
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
	id tbl = [aNotification object];
	// ブロードキャストリスト
	if (tbl == self.netBroadAddressTable) {
		// １つ以上のアドレスが選択されていない場合は削除ボタンが押下不可
		self.netBroadDeleteButton.enabled = (self.netBroadAddressTable.numberOfSelectedRows > 0);
	}
	// 不在リスト
	else if (tbl == self.absenceTable) {
		NSInteger index = self.absenceTable.selectedRow;
		self.absenceEditButton.enabled		= (index != -1);
		self.absenceDeleteButton.enabled	= (index != -1);
		self.absenceUpButton.enabled		= (index > 0);
		self.absenceDownButton.enabled		= ((index >= 0) && (index < self.absenceTable.numberOfRows - 1));
	}
	// 通知拒否リスト
	else if (tbl == self.refuseTable) {
		NSInteger index = self.refuseTable.selectedRow;
		self.refuseEditButton.enabled	= (index != -1);
		self.refuseDeleteButton.enabled	= (index != -1);
		self.refuseUpButton.enabled		= (index > 0);
		self.refuseDownButton.enabled	= ((index >= 0) && (index < self.refuseTable.numberOfRows - 1));
	}
	// その他（バグ）
	else {
		ERR(@"unknown table selection changed (%@)", tbl);
	}
}

// テーブルダブルクリック時処理
- (void)tableDoubleClicked:(id)sender
{
	NSInteger index = [sender selectedRow];
	// 不在定義リスト
	if (sender == self.absenceTable) {
		if (index >= 0) {
			[self.absenceEditButton performClick:self];
		}
	}
	// 通知拒否条件リスト
	else if (sender == self.refuseTable) {
		if (index >= 0) {
			[self.refuseEditButton performClick:self];
		}
	}
	// その他（バグ）
	else {
		ERR(@"unknown table double clicked (%@)", sender);
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSWindow
/*----------------------------------------------------------------------------*/

// ウィンドウ表示時
- (void)windowDidBecomeKey:(NSNotification*)aNotification
{
	[self update];
}

// ウィンドウクローズ時
- (void)windowWillClose:(NSNotification*)aNotification
{
	// 設定を保存
	[Config.sharedConfig save];
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSObject
/*----------------------------------------------------------------------------*/

// 初期化
- (void)awakeFromNib
{
	// 拒否条件パネルをロード（英語と日本語でレイアウトが異なるため外だし）
	if (self.refuseSheet != nil) {
		// 追加のxib読み込みでawakeFromNibが呼ばれてしまうので無限ループにならないように
		return;
	}
	if (![NSBundle.mainBundle loadNibNamed:@"RefusePanel" owner:self topLevelObjects:nil]) {
		self.refuseSheet = nil;
	}

	// サウンドプルダウンを準備
	NSFileManager*		fm		= NSFileManager.defaultManager;
	NSArray<NSString*>*	dirs	= NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
	for (NSString* dirBase in dirs) {
		NSString*			dir		= [dirBase stringByAppendingPathComponent:@"Sounds"];
		NSArray<NSString*>*	files	= [fm contentsOfDirectoryAtPath:dir error:NULL];
		for (NSString* file in files) {
			[self.receiveSoundPopup addItemWithTitle:[file stringByDeletingPathExtension]];
		}
	}

	// テーブルダブルクリック時設定
	self.absenceTable.doubleAction	= @selector(tableDoubleClicked:);
	self.refuseTable.doubleAction	= @selector(tableDoubleClicked:);

	// コントロールの設定値を最新状態に
	[self update];

	// 画面中央に移動
	[self.panel center];
}

@end
