/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: AttachStatusControl.h
 *	Module		: 添付ファイル状況表示パネルコントローラ
 *============================================================================*/

#import <Cocoa/Cocoa.h>

@interface AttachStatusControl : NSObject <NSWindowDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>

@property(retain)	IBOutlet NSPanel*		panel;
@property(weak)		IBOutlet NSOutlineView*	attachTable;
@property(weak)		IBOutlet NSButton*		dispAlwaysCheck;
@property(weak)		IBOutlet NSButton*		deleteButton;

- (IBAction)buttonPressed:(id)sender;
- (IBAction)checkboxChanged:(id)sender;

@end
