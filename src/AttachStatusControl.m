/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: AttachStatusControl.m
 *	Module		: 添付ファイル状況表示パネルコントローラ
 *============================================================================*/

#import "AttachStatusControl.h"
#import "UserInfo.h"
#import "SendAttachment.h"
#import "RecvFile.h"
#import "MessageCenter.h"
#import "DebugLog.h"

/*============================================================================*
 * 定数定義
 *============================================================================*/

static NSString* ATTACHPNL_SIZE_W	= @"AttachStatusPanelWidth";
static NSString* ATTACHPNL_SIZE_H	= @"AttachStatusPanelHeight";
static NSString* ATTACHPNL_POS_X	= @"AttachStatusPanelOriginX";
static NSString* ATTACHPNL_POS_Y	= @"AttachStatusPanelOriginY";

/*============================================================================*
 * クラス実装
 *============================================================================*/

@implementation AttachStatusControl

/*----------------------------------------------------------------------------*/
#pragma mark - 初期化/解放
/*----------------------------------------------------------------------------*/

- (instancetype)init
{
	self = [super init];
	if (self) {
		// データのロード
		[_attachTable reloadData];

		// 添付リスト変更の通知登録
		NSNotificationCenter* nc = NSNotificationCenter.defaultCenter;
		[nc addObserver:self
			   selector:@selector(attachListChanged:)
				   name:kIPMsgAttachmentListChangedNotification
				 object:nil];
	}
	return self;
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
	[super dealloc];
}

/*----------------------------------------------------------------------------*/
#pragma mark - イベントハンドラ
/*----------------------------------------------------------------------------*/

- (IBAction)buttonPressed:(id)sender
{
	if (sender == self.deleteButton) {
		id item = [self.attachTable itemAtRow:self.attachTable.selectedRow];
		if ([item isKindOfClass:SendAttachment.class]) {
			if (MessageCenter.isAttachmentAvailable) {
				SendAttachment* attach = item;
				[MessageCenter.sharedCenter removeAttachment:attach];
				[self.attachTable deselectAll:self];
			}
		} else {
			ERR(@"Unsupported deletion(item=%@)", item);
		}
	} else {
		ERR(@"Unknown Button Pressed(%@)", sender);
	}
}

- (IBAction)checkboxChanged:(id)sender
{
	if (sender == self.dispAlwaysCheck) {
		self.panel.hidesOnDeactivate = (self.dispAlwaysCheck.state == NSControlStateValueOff);
	} else {
		ERR(@"Unknown Checkbox Changed(%@)", sender);
	}
}

- (void)attachListChanged:(NSNotification*)aNotification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.attachTable reloadData];
	});
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSOutlineView
/*----------------------------------------------------------------------------*/

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item) {
		if (MessageCenter.isAttachmentAvailable) {
			return MessageCenter.sharedCenter.sentAttachments.count;
		}
	} else if ([item isKindOfClass:SendAttachment.class]) {
		SendAttachment* attach = item;
		return attach.remainUsers.count;
	} else {
		WRN(@"not yet(number of children of %@)", item);
	}
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (!item) {
		if (MessageCenter.isAttachmentAvailable) {
			return MessageCenter.sharedCenter.sentAttachments[index];
		}
	} else if ([item isKindOfClass:SendAttachment.class]) {
		SendAttachment* attach = item;
		return attach.remainUsers[index];
	} else {
		WRN(@"not yet(#%ld child of %@)", index, item);
	}
	return nil;
}

- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item
{
	if (!item) {
		return (MessageCenter.sharedCenter.sentAttachments.count > 0);
	} else if ([item isKindOfClass:SendAttachment.class]) {
		return YES;
	} else if ([item isKindOfClass:UserInfo.class]) {
		return NO;
	} else {
		WRN(@"not yet(isExpandable %@)", item);
	}
	return NO;
}

- (id)outlineView:(NSOutlineView*)outlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
	if ([item isKindOfClass:SendAttachment.class]) {
		SendAttachment*	sendAttach = item;
		return [NSString stringWithFormat:@"%@ (Remain Users:%ld)", sendAttach.name, sendAttach.remainUsers.count];
	} else if ([item isKindOfClass:UserInfo.class]) {
		UserInfo* user = item;
		return user.summaryString;
	}
	return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return [item isKindOfClass:SendAttachment.class];
}

- (void)outlineViewSelectionDidChange:(NSNotification*)notification
{
	self.deleteButton.enabled = (self.attachTable.selectedRow != -1);
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSWindow
/*----------------------------------------------------------------------------*/

- (void)windowDidMove:(NSNotification*)aNotification
{
	if (self.panel.visible) {
		NSUserDefaults*	ud		= NSUserDefaults.standardUserDefaults;
		NSPoint			origin	= self.panel.frame.origin;
		[ud setObject:@(origin.x) forKey:ATTACHPNL_POS_X];
		[ud setObject:@(origin.y) forKey:ATTACHPNL_POS_Y];
	}
}

- (void)windowDidResize:(NSNotification*)aNotification
{
	if (self.panel.visible) {
		NSUserDefaults*	ud		= NSUserDefaults.standardUserDefaults;
		NSSize			size	= self.panel.frame.size;
		[ud setObject:@(size.width) forKey:ATTACHPNL_SIZE_W];
		[ud setObject:@(size.height) forKey:ATTACHPNL_SIZE_H];
	}
}

/*----------------------------------------------------------------------------*/
#pragma mark - NSObject
/*----------------------------------------------------------------------------*/

// 初期化
- (void)awakeFromNib
{
	NSUserDefaults*	ud			= NSUserDefaults.standardUserDefaults;
	NSNumber*		originX		= [ud objectForKey:ATTACHPNL_POS_X];
	NSNumber*		originY		= [ud objectForKey:ATTACHPNL_POS_Y];
	NSNumber*		sizeWidth	= [ud objectForKey:ATTACHPNL_SIZE_W];
	NSNumber*		sizeHeight	= [ud objectForKey:ATTACHPNL_SIZE_H];
	NSRect			windowFrame;
	if (originX && originY && sizeWidth && sizeHeight) {
		windowFrame.origin.x	= originX.floatValue;
		windowFrame.origin.y	= originY.floatValue;
		windowFrame.size.width	= sizeWidth.floatValue;
		windowFrame.size.height	= sizeHeight.floatValue;
	} else {
		NSRect screenFrame		= NSScreen.mainScreen.frame;
		windowFrame				= self.panel.frame;
		windowFrame.origin.x	= screenFrame.size.width - windowFrame.size.width - 5;
		windowFrame.origin.y	= screenFrame.size.height - windowFrame.size.height
											- NSStatusBar.systemStatusBar.thickness - 5;
	}
	[self.panel setFrame:windowFrame display:NO];
	self.panel.floatingPanel = NO;
}

@end
