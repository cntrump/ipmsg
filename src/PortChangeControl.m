/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: PortChangeControl.m
 *	Module		: ポート変更ダイアログコントローラクラス
 *============================================================================*/

#import "PortChangeControl.h"
#import "Config.h"
#import "DebugLog.h"

@implementation PortChangeControl

// 初期化
- (instancetype)init
{
	self = [super init];
	if (self) {
		// nibファイルロード
		if (![NSBundle.mainBundle loadNibNamed:@"PortChangeDialog"
										 owner:self
							   topLevelObjects:nil]) {
			[self release];
			return nil;
		}

		_portNoField.objectValue = @(Config.sharedConfig.portNo);

		// ダイアログ表示
		[_panel center];
		_panel.excludedFromWindowsMenu = YES;
		[_panel makeKeyAndOrderFront:self];

		// モーダル開始
		[NSApp runModalForWindow:_panel];
	}
	return self;
}

// ボタン押下時処理
- (IBAction)buttonPressed:(id)sender
{
	if (sender == self.okButton) {
		NSInteger newVal = self.portNoField.integerValue;
		if (newVal != 0) {
			// ポート変更／ウィンドウクローズ／モーダル終了
			Config.sharedConfig.portNo = newVal;
			[self.panel close];
			[NSApp stopModal];
		}
	} else {
		ERR(@"Unknown Button Pressed(%@)", sender);
	}
}

// テキスト変更時処理
- (IBAction)textChanged:(id)sender
{
	if (sender == self.portNoField) {
		// NOP
	} else {
		ERR(@"Unknown TextField Changed(%@)", sender);
	}
}

// ウィンドウクローズ時処理
- (void)windowWillClose:(NSNotification*)aNotification
{
	[self release];
}

@end
