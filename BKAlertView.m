//
//  BKAlertView.m
//  BonjourKit
//
//  Created by あんのたん on 2009/07/27.
//  Copyright 2009 株式会社パンカク. All rights reserved.
//

#import "BKAlertView.h"


@implementation BKAlertView

@dynamic delegate;

- (id)initWithTitle:(NSString *)aTitle {
	
	if (aTitle == nil) {
		aTitle = [[UIDevice currentDevice] name];
	}
	
	self = [super initWithTitle:aTitle message:@"\n\n\n\n\n\n" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
	
	if (self) {
		browser = [[BKBrowserViewController alloc] initWithTitle:nil showDisclosureIndicators:NO showCancelButton:NO frame:CGRectMake(11, 50, 261, 120)];
		browser.ownName = aTitle; 
		
		//UILabel *bodyTextLabel;
		//object_getInstanceVariable(self, "_bodyTextLabel", (void **)&bodyTextLabel);
		//[browser.view setFrame:[bodyTextLabel bounds]];
		//[bodyTextLabel addSubview:[browser view]];
		
		[self addSubview:browser.tableView];
		
	}
	
	return self;
}

- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain {
	return [browser searchForServicesOfType:type inDomain:domain];
}

- (id<BKBrowserViewControllerDelegate>)delegate {
	return [browser delegate];
}

- (void)setDelegate:(id<BKBrowserViewControllerDelegate>)aDelegate {
	[super setDelegate:aDelegate];
	[browser setDelegate:aDelegate];
}

@end
