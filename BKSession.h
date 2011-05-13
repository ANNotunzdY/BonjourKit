//
//  BKSession.h
//  BonjourKit
//
//  Created by あんのたん on 2009/07/27.
//  Copyright 2009 株式会社パンカク. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BKServer.h"
#import "BKAlertView.h"

typedef enum {
	BKSessionModeServer,
	BKSessionModeClient,
	BKSessionModePeer,
} BKSessionMode;

@class BKSession;

@protocol BKSessionDelegate
- (void)sessionDidEnabled:(BKSession *)session;
- (void)session:(BKSession *)session didReceiveData:(NSData *)aData;
- (void)sessionDidCanceled:(BKSession *)session;
- (void)sessionDidOpenStream:(BKSession *)session;
@end


@interface BKSession : NSObject <BKServerDelegate, BKBrowserViewControllerDelegate, UIAlertViewDelegate> {
	BKSessionMode mode;
	NSString* sessionID;
	BKServer* server;
	BOOL available;
	BOOL enabled;
	NSThread* serverThread;
	NSThread* inStreamThread;
	NSThread* outStreamThread;
	NSThread* receiveThread;
	NSRunLoop* inStreamRunLoop;
	NSRunLoop* outStreamRunLoop;
	BKAlertView* alert;
	NSInputStream* inStream;
	NSOutputStream* outStream;
	BOOL inReady;
	BOOL outReady;
	NSString* name;
	id<BKSessionDelegate> delegate;
	NSMutableData* receiveBuffer;
}
@property(readonly) NSString *sessionID;
@property(readonly) BKSessionMode mode;
@property(getter=isEnabled) BOOL enabled;
@property(getter=isAvailable) BOOL available;
@property(retain, nonatomic) id<BKSessionDelegate> delegate;

- (id)initWithSessionID:(NSString *)aSessionID displayName:(NSString *)aName sessionMode:(BKSessionMode)aMode;
- (void)startServerThread;
- (void)openStreams;
- (void)showPicker;
- (void)destroyPicker;
- (void)showAlertWithMessage:(NSString *)message retryButton:(BOOL)aBool;
- (void)sendData:(NSData *)aData;
@end
