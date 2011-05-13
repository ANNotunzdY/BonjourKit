/*
 <codex>
 <abstract>View controller for the service instance list.
 This object manages a NSNetServiceBrowser configured to look for Bonjour services.
 It has an array of NSNetService objects that are displayed in a table view.
 When the service browser reports that it has discovered a service, the corresponding NSNetService is added to the array.
 When a service goes away, the corresponding NSNetService is removed from the array.
 Selecting an item in the table view asynchronously resolves the corresponding net service.
 When that resolution completes, the delegate is called with the corresponding NSNetService.</abstract>
 </codex>
 */

#import <UIKit/UIKit.h>
#import <Foundation/NSNetServices.h>

@class BKBrowserViewController;

@protocol BKBrowserViewControllerDelegate <NSObject>
@required
// This method will be invoked when the user selects one of the service instances from the list.
// The ref parameter will be the selected (already resolved) instance or nil if the user taps the 'Cancel' button (if shown).
- (void) browserViewController:(BKBrowserViewController *)bvc didResolveInstance:(NSNetService *)ref;
@end

@interface BKBrowserViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {

@private
	id<BKBrowserViewControllerDelegate> _delegate;
	NSString *_searchingForServicesString;
	NSString *_ownName;
	NSNetService *_ownEntry;
	BOOL _showDisclosureIndicators;
	NSMutableArray *_services;
	NSNetServiceBrowser *_netServiceBrowser;
	NSNetService *_currentResolve;
	NSTimer *_timer;
	BOOL _needsActivityIndicator;
	BOOL _initialWaitOver;
	UITableView* tableView;
}

@property (nonatomic, assign) id<BKBrowserViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *searchingForServicesString;
@property (nonatomic, copy) NSString *ownName;
@property (nonatomic, readonly) UITableView* tableView;

- (id)initWithTitle:(NSString *)title showDisclosureIndicators:(BOOL)show showCancelButton:(BOOL)showCancelButton frame:(CGRect)frame;
- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain;
- (void)stop;
@end
