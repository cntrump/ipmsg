/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: PortChangeControl.h
 *	Module		: ポート変更ダイアログコントローラクラス
 *============================================================================*/

#import <Cocoa/Cocoa.h>

@interface PortChangeControl : NSObject <NSWindowDelegate>

@property(retain)	IBOutlet NSPanel*		panel;
@property(weak)		IBOutlet NSTextField*	portNoField;
@property(weak)		IBOutlet NSButton*		okButton;

- (IBAction)buttonPressed:(id)sender;
- (IBAction)textChanged:(id)sender;

@end
