/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: PrefControl.h
 *	Module		: 環境設定パネルコントローラ
 *============================================================================*/

#import <Cocoa/Cocoa.h>

/*============================================================================*
 * クラス定義
 *============================================================================*/

@interface PrefControl : NSObject <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property(weak)		IBOutlet NSPanel*			panel;
// 全般
@property(weak)		IBOutlet NSTextField*		baseUserNameField;
@property(weak)		IBOutlet NSTextField*		baseGroupNameField;
@property(weak)		IBOutlet NSButton*			basePasswordButton;
@property(weak)		IBOutlet NSPanel*			pwdSheet;
@property(weak)		IBOutlet NSSecureTextField*	pwdSheetOldPwdField;
@property(weak)		IBOutlet NSSecureTextField*	pwdSheetNewPwdField1;
@property(weak)		IBOutlet NSSecureTextField*	pwdSheetNewPwdField2;
@property(weak)		IBOutlet NSTextField*		pwdSheetErrorLabel;
@property(weak)		IBOutlet NSButton*			pwdSheetOKButton;
@property(weak)		IBOutlet NSButton*			pwdSheetCancelButton;
@property(weak)		IBOutlet NSButton*			receiveStatusBarCheckBox;
// 送信
@property(weak)		IBOutlet NSTextField*		sendQuotField;
@property(weak)		IBOutlet NSButton*			sendSingleClickCheck;
@property(weak)		IBOutlet NSButton*			sendDefaultSealCheck;
@property(weak)		IBOutlet NSButton*			sendHideWhenReplyCheck;
@property(weak)		IBOutlet NSButton*			sendOpenNotifyCheck;
@property(weak)		IBOutlet NSButton*			sendMultipleUserCheck;
// 受信
@property(weak)		IBOutlet NSPopUpButton*		receiveSoundPopup;
@property(weak)		IBOutlet NSButton*			receiveDefaultQuotCheck;
@property(weak)		IBOutlet NSButton*			receiveNonPopupCheck;
@property(weak)		IBOutlet NSMatrix*			receiveNonPopupModeMatrix;
@property(weak)		IBOutlet NSMatrix*			receiveNonPopupBoundMatrix;
@property(weak)		IBOutlet NSButton*			receiveClickableURLCheck;
// ネットワーク
@property(weak)		IBOutlet NSTextField*		netPortNoField;
@property(weak)		IBOutlet NSButton*			netDialupCheck;
@property(weak)		IBOutlet NSTableView*		netBroadAddressTable;
@property(weak)		IBOutlet NSButton*			netBroadAddButton;
@property(weak)		IBOutlet NSButton*			netBroadDeleteButton;
@property(weak)		IBOutlet NSPanel*			bcastSheet;
@property(weak)		IBOutlet NSMatrix*			bcastSheetMatrix;
@property(weak)		IBOutlet NSButton*			bcastSheetResolveCheck;
@property(weak)		IBOutlet NSTextField*		bcastSheetField;
@property(weak)		IBOutlet NSTextField*		bcastSheetErrorLabel;
@property(weak)		IBOutlet NSButton*			bcastSheetOKButton;
@property(weak)		IBOutlet NSButton*			bcastSheetCancelButton;
// 不在
@property(weak)		IBOutlet NSTableView*		absenceTable;
@property(weak)		IBOutlet NSButton*			absenceAddButton;
@property(weak)		IBOutlet NSButton*			absenceEditButton;
@property(weak)		IBOutlet NSButton*			absenceDeleteButton;
@property(weak)		IBOutlet NSButton*			absenceUpButton;
@property(weak)		IBOutlet NSButton*			absenceDownButton;
@property(weak)		IBOutlet NSButton*			absenceResetButton;
@property(weak)		IBOutlet NSPanel*			absenceSheet;
@property(weak)		IBOutlet NSTextField*		absenceSheetTitleField;
@property(weak)		IBOutlet NSTextView*		absenceSheetMessageArea;
@property(weak)		IBOutlet NSTextField*		absenceSheetErrorLabel;
@property(weak)		IBOutlet NSButton*			absenceSheetOKButton;
@property(weak)		IBOutlet NSButton*			absenceSheetCancelButton;
@property(assign)	NSInteger					absenceEditIndex;
// 通知拒否
@property(weak)		IBOutlet NSTableView*		refuseTable;
@property(weak)		IBOutlet NSButton*			refuseAddButton;
@property(weak)		IBOutlet NSButton*			refuseEditButton;
@property(weak)		IBOutlet NSButton*			refuseDeleteButton;
@property(weak)		IBOutlet NSButton*			refuseUpButton;
@property(weak)		IBOutlet NSButton*			refuseDownButton;
@property(retain)	IBOutlet NSPanel*			refuseSheet;
@property(weak)		IBOutlet NSTextField*		refuseSheetField;
@property(weak)		IBOutlet NSPopUpButton*		refuseSheetTargetPopup;
@property(weak)		IBOutlet NSPopUpButton*		refuseSheetCondPopup;
@property(weak)		IBOutlet NSTextField*		refuseSheetErrorLabel;
@property(weak)		IBOutlet NSButton*			refuseSheetOKButton;
@property(weak)		IBOutlet NSButton*			refuseSheetCancelButton;
@property(assign)	NSInteger					refuseEditIndex;
// ログ
@property(weak)		IBOutlet NSButton*			logStdEnableCheck;
@property(weak)		IBOutlet NSButton*			logStdWhenOpenChainCheck;
@property(weak)		IBOutlet NSTextField*		logStdPathField;
@property(weak)		IBOutlet NSButton*			logStdPathRefButton;
@property(weak)		IBOutlet NSButton*			logAltEnableCheck;
@property(weak)		IBOutlet NSButton*			logAltSelectionCheck;
@property(weak)		IBOutlet NSTextField*		logAltPathField;
@property(weak)		IBOutlet NSButton*			logAltPathRefButton;
// アップデート
@property(weak)		IBOutlet NSButton*			updateCheckAutoCheck;
@property(weak)		IBOutlet NSMatrix*			updateTypeMatrix;
@property(weak)		IBOutlet NSTextField*		updateBetaTestLabel;

// 最新状態に更新
- (void)update;

// イベントハンドラ
- (IBAction)buttonPressed:(id)sender;
- (IBAction)checkboxChanged:(id)sender;
- (IBAction)popupChanged:(id)sender;
- (IBAction)matrixChanged:(id)sender;

@end
