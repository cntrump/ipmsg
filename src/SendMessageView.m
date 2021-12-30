/*============================================================================*
 * (C) 2001-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: SendMessageView.m
 *	Module		: 送信メッセージ表示View
 *============================================================================*/

#import "SendMessageView.h"
#import "MessageCenter.h"
#import "SendControl.h"
#import "DebugLog.h"

@interface SendMessageView()

@property(assign)	BOOL	duringDragging;

@end

@implementation SendMessageView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		[self setRichText:NO];
		// ファイルのドラッグを受け付ける
		if (MessageCenter.isAttachmentAvailable) {
			[self registerForDraggedTypes:@[NSFilenamesPboardType]];
		}
	}
	return self;
}

/*----------------------------------------------------------------------------*
 * ファイルドロップ処理（添付ファイル）
 *----------------------------------------------------------------------------*/

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
	if (!MessageCenter.isAttachmentAvailable) {
		return NSDragOperationNone;
	}
	self.duringDragging = YES;
	self.needsDisplay	= YES;

	return NSDragOperationGeneric;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
	if (!MessageCenter.isAttachmentAvailable) {
		return NSDragOperationNone;
	}
	return NSDragOperationGeneric;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
	if (!MessageCenter.isAttachmentAvailable) {
		return;
	}
	self.duringDragging = NO;
	self.needsDisplay	= YES;
}

- (void)drawRect:(NSRect)aRect
{
	[super drawRect:aRect];
	if (self.duringDragging) {
		[NSColor.selectedControlColor set];
		NSFrameRectWithWidth(self.visibleRect, 4.0);
	}
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
	return MessageCenter.isAttachmentAvailable;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	return MessageCenter.isAttachmentAvailable;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
	NSPasteboard* 		pBoard	= [sender draggingPasteboard];
	NSArray<NSString*>*	files	= [pBoard propertyListForType:NSFilenamesPboardType];
	SendControl*		control	= (SendControl*)self.window.delegate;
	for (NSString* file in files) {
		[control appendAttachmentByPath:file];
	}
	self.duringDragging = NO;
	self.needsDisplay	= YES;
}

@end
