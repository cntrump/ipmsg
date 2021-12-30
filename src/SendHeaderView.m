/*============================================================================*
 * (C) 2011-2019 G.Ishiwata, All Rights Reserved.
 *
 *	Project		: IP Messenger for macOS
 *	File		: SendHeaderView.m
 *	Module		: 送信ウィンドウヘッダ部View
 *============================================================================*/

#import "SendHeaderView.h"

@implementation SendHeaderView

- (void)drawRect:(NSRect)dirtyRect
{
	// 下線描画
	NSRect			rect	= self.bounds;
	NSBezierPath*	path	= [NSBezierPath bezierPath];
	NSPoint			point1	= NSMakePoint(rect.origin.x, rect.origin.y + 0.5);
	NSPoint			point2	= point1;
	point2.x += rect.size.width;

	[NSColor.gridColor set];
	path.lineWidth	= 1.0;
	[path moveToPoint:point1];
	[path lineToPoint:point2];
	[path stroke];
}

@end
