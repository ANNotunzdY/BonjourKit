//
//  BKAlertView.h
//  BonjourKit
//
//  Created by Takayoshi Sato on 2009/07/27.
//  Copyright 2009 Takayoshi Sato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BKBrowserViewController.h"

@interface BKAlertView : UIAlertView {
	BKBrowserViewController* browser;
}
@property (nonatomic, assign) id<BKBrowserViewControllerDelegate> delegate;

- (id)initWithTitle:(NSString *)aTitle;
- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain;
@end
