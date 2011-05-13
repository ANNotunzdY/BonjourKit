//
//  BKSession.m
//  BonjourKit
//
//  Created by あんのたん on 2009/07/27.
//  Copyright 2009 株式会社パンカク. All rights reserved.
//

#import "BKSession.h"

@implementation BKSession

@synthesize sessionID, mode, enabled, delegate;
@dynamic available;

- (id)initWithSessionID:(NSString *)aSessionID displayName:(NSString *)aName sessionMode:(BKSessionMode)aMode {
	self = [super init];
	
	if (self) {
		if (!aName) {
			aName = [[UIDevice currentDevice] name];
		}
		
		sessionID = [aSessionID retain];
		name = [aName retain];
		mode = aMode;
		
		if (mode != BKSessionModeClient) {
			[self startServerThread];
		}
		
		receiveBuffer = [[NSMutableData alloc] init];
		
		receiveThread = [[NSThread alloc] initWithTarget:self selector:@selector(receiveThreadMethod) object:nil];
		[receiveThread start];
		
		
	}
	
	return self;
}

- (void)dealloc {
	[serverThread cancel];
	[serverThread autorelease];
	[inStreamThread cancel];
	[inStreamRunLoop release];
	[inStreamThread release];
	[outStreamThread cancel];
	[outStreamRunLoop release];
	[outStreamThread release];
	[receiveThread cancel];
	[receiveThread autorelease];
	[server release];
	[sessionID release];
	[receiveBuffer release];
	[super dealloc];
}

- (void)startServerThread {
	if (serverThread) {
		[serverThread cancel];
		[serverThread autorelease];
	}
	serverThread = [[NSThread alloc] initWithTarget:self selector:@selector(serverThreadMethod) object:nil];
	[serverThread start];
}

- (void)serverThreadMethod {
	NSAutoreleasePool* aPool = [[NSAutoreleasePool alloc] init];
	NSLog(@"ServerThreadMethod");
	[server release];
	server = nil;
	server = [[BKServer alloc] init];
	server.delegate = self;
	NSError* aError;
	BOOL check = [server startWithRunLoop:[NSRunLoop currentRunLoop] error:&aError];
	if (!check) {
		[aPool release];
		return;
	}
	
	enabled = YES;
	//[delegate performSelectorOnMainThread:@selector(sessionDidEnabled:) withObject:self waitUntilDone:NO];
	[delegate sessionDidEnabled:self];
	
	while (![[NSThread currentThread] isCancelled] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
		NSLog(@"Running.");
	}
	
	NSLog(@"Thread is canceled.");
	[aPool release];	
}

- (BOOL)isAvailable {
	return available;
}

- (void)setAvailable:(BOOL)aBool {
	
	if (aBool == available) {
		return;
	}
	
	if (mode != BKSessionModeServer) {
		if (aBool) {
			[self showPicker];
		} else {
			[self destroyPicker];
		}
	}
	
	
	if (!server || !enabled) {
		return;
	}
	
	if (aBool) {
		//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
		if(![server enableBonjourWithDomain:@"local" applicationProtocol:[BKServer bonjourTypeFromIdentifier:sessionID] name:name]) {
			NSLog(@"Failed advertising server");
			return;
		}
	} else {
		[server disableBonjour];
	}
	
	available = aBool;
}

- (void)showPicker {
	alert = [[BKAlertView alloc] initWithTitle:name];
	alert.delegate = self;
	[alert show];
	[alert searchForServicesOfType:[BKServer bonjourTypeFromIdentifier:sessionID] inDomain:nil];
}

- (void)destroyPicker {
	[alert dismissWithClickedButtonIndex:0 animated:YES];
	[alert release];
	alert = nil;
}
		
- (void)inStreamThreadMethod {
	NSAutoreleasePool* aPool = [[NSAutoreleasePool alloc] init];
	
	inStreamRunLoop = [[NSRunLoop currentRunLoop] retain];
	inStream.delegate = self;
	[inStream scheduleInRunLoop:inStreamRunLoop forMode:NSDefaultRunLoopMode];
	[inStream open];
	while (![[NSThread currentThread] isCancelled] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
		//NSLog(@"Running.");
	}
	
	NSLog(@"Thread is canceled.");
	[aPool release];
}

- (void)outStreamThreadMethod {
	NSAutoreleasePool* aPool = [[NSAutoreleasePool alloc] init];
	
	outStreamRunLoop = [[NSRunLoop currentRunLoop] retain];
	outStream.delegate = self;
	[outStream scheduleInRunLoop:outStreamRunLoop forMode:NSDefaultRunLoopMode];
	[outStream open];
	while (![[NSThread currentThread] isCancelled] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
		//NSLog(@"Running.");
	}
	
	NSLog(@"Thread is canceled.");
	[aPool release];
}

- (void)receiveThreadMethod {
	NSAutoreleasePool* aPool = [[NSAutoreleasePool alloc] init];
	//[NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(receiveBuffer) userInfo:nil repeats:YES];
	[NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(checkBuffer) userInfo:nil repeats:YES];
	while (![[NSThread currentThread] isCancelled] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
	}
	
	NSLog(@"Thread is canceled.");
	[aPool release];
}


- (void)openStreams {
	if (inStreamThread) {
		[inStreamThread cancel];
		[inStreamThread release];
		inStreamThread = nil;
	}
	
	if (outStreamThread) {
		[outStreamThread cancel];
		[outStreamThread release];
		outStreamThread = nil;
	}
	
	inStreamThread = [[NSThread alloc] initWithTarget:self selector:@selector(inStreamThreadMethod) object:nil];
	[inStreamThread start];
	
	outStreamThread = [[NSThread alloc] initWithTarget:self selector:@selector(outStreamThreadMethod) object:nil];
	[outStreamThread start];
	
	[delegate sessionDidOpenStream:self];
	
}

- (void) serverDidEnableBonjour:(BKServer*)server withName:(NSString*)name {
	NSLog(@"Enable Bonjour.");
}

- (void) server:(BKServer*)server didNotEnableBonjour:(NSDictionary *)errorDict {
	NSLog(@"Bonjour Did Not Enabled.");
}

- (void) didAcceptConnectionForServer:(BKServer*)aServer inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
	
	NSLog(@"Accept Connection.");
	
	if (server != aServer) {
		NSLog(@"Server is different.");
		return;
	}
	
	[self setAvailable:NO];
	
	[server release];
	server = nil;
	
	if (inStreamRunLoop) {
		[inStream removeFromRunLoop:inStreamRunLoop forMode:NSDefaultRunLoopMode];
		[inStream release];
		inStream = nil;
		inReady = NO;
	}
	
	if (outStreamRunLoop) {
		[outStream removeFromRunLoop:outStreamRunLoop forMode:NSDefaultRunLoopMode];
		[outStream release];
		outStream = nil;
		outReady = NO;
		[outStreamRunLoop release];
	}
	
	[inStream autorelease];
	inStream = istr;
	[inStream retain];
	[outStream autorelease];
	outStream = ostr;
	[outStream retain];
	
	[self openStreams];	
	
}

- (void) browserViewController:(BKBrowserViewController *)bvc didResolveInstance:(NSNetService *)ref {
	
	NSLog(@"didResolveInstance");
	[self destroyPicker];
	[self setAvailable:NO];
	
	if (!ref) {
		NSLog(@"netService is nil.");
		[self showAlertWithMessage:@"Net service is not found." retryButton:YES];
		return;
	}
	
	if (inStreamRunLoop) {
		NSLog(@"Release old streams.");
		[inStream removeFromRunLoop:inStreamRunLoop forMode:NSDefaultRunLoopMode];
		[inStream release];
		inStream = nil;
		inReady = NO;
	}
	
	if (outStreamRunLoop) {
		[outStream removeFromRunLoop:outStreamRunLoop forMode:NSDefaultRunLoopMode];
		[outStream release];
		outStream = nil;
		outReady = NO;
		
		[outStreamRunLoop release];
	}
	
	// note the following method returns _inStream and _outStream with a retain count that the caller must eventually release
	if (![ref getInputStream:&inStream outputStream:&outStream]) {
		NSLog(@"Stream Get Error.");
		[self showAlertWithMessage:@"Stream getting is failed." retryButton:YES];
		return;
	}
	
	[self openStreams];
	
	
}

- (void)showAlertWithMessage:(NSString *)message retryButton:(BOOL)aBool {
	UIAlertView* aAlert;
	if (aBool) {
		aAlert = [[UIAlertView alloc] initWithTitle:@"Network error." message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
	} else {
		aAlert = [[UIAlertView alloc] initWithTitle:@"Network error." message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
	}
	[aAlert show];
	[aAlert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	NSLog(@"Click Alert:%d", buttonIndex);
	switch (buttonIndex) {
		case 1:
			[self setAvailable:YES];
			break;
		case 0:
			[self setAvailable:NO];
			[delegate sessionDidCanceled:self];
			break;
	}
	
	if (alertView == alert) {
		[alert release];
		alert = nil;
	}
	
}

- (void) receiveBuffer {
	
	NSAutoreleasePool* aPool = [[NSAutoreleasePool alloc] init];
	
	if (![inStream hasBytesAvailable]) return;
	
	//NSLog(@"receiveBuffer");
	uint8_t buf[16 * 1024];
	uint8_t* buffer = NULL;
	unsigned int len = 0;
	int amount = 0;
	
	if (![inStream getBuffer:(uint8_t **)&buffer length:(NSUInteger *)&len]) {
		amount = 0;
		amount = [inStream read:buf maxLength:sizeof(buf)];
		buffer = buf;
		len += amount;
	} else {
		NSLog(@"getBuffer");
	}
	
	if (0 < len) {
		@synchronized (receiveBuffer) {
			[receiveBuffer appendBytes:buffer length:len];
		}
		
		//[NSThread detachNewThreadSelector:@selector(checkBuffer) toTarget:self withObject:nil];
	}
	
	[aPool release];
	
}

- (void) checkBuffer {
	
	NSAutoreleasePool* aPool = [[NSAutoreleasePool alloc] init];
	
	//NSLog(@"Check Buffer.");
	if ([receiveBuffer length] != 0) {
		@synchronized (receiveBuffer) {
			NSData* headerData = [receiveBuffer subdataWithRange:NSMakeRange(0, 4)];
			unsigned int *__dataSize = (unsigned int *)[headerData bytes];
			unsigned int dataSize = *__dataSize;
			//NSLog(@"dataSize:%u", dataSize);
			
			if ([receiveBuffer length] < dataSize + 4) {
				//NSLog(@"data is imperfect.");
				[aPool release];
				return;
			}
			
			NSData* body;
			
			body = [receiveBuffer subdataWithRange:NSMakeRange(4, dataSize)];
			NSUInteger bufferLength = [receiveBuffer length];
			[receiveBuffer autorelease];
			receiveBuffer = [[receiveBuffer subdataWithRange:NSMakeRange(dataSize + 4, bufferLength - (dataSize + 4))] mutableCopy];
			
			[delegate session:self didReceiveData:body];
		}
	}
	
	[aPool release];
	
}		

- (void) sendData:(NSData *)aData {
	
	NSAutoreleasePool* aPool = [[NSAutoreleasePool alloc] init];
	
	if (!outStream && ![outStream hasSpaceAvailable]) {
		NSLog(@"Stream is not enabled.");
		[aPool release];
		return;
	}
	
	unsigned int dataSize = [aData length];
	//NSLog(@"dataSize:%u", dataSize);
	NSMutableData* mutableData = [NSMutableData dataWithBytes:&dataSize length:sizeof(dataSize)];
	//unsigned int* aBytes = (unsigned int *) [mutableData bytes];
	//NSLog(@"mutableData:%u (%u)", *aBytes, [mutableData length]);
	[mutableData appendData:aData];
	const void *bytes = [mutableData bytes];
	
	int complete = 0;
	
	while (complete < [mutableData length]) {
		int len = [outStream write:(const uint8_t *)bytes maxLength:[mutableData length] - complete];
		if(len == -1) {
			//[self showAlertWithMessage:@"Failed sending data to peer" retryButton:NO];
			break;
		}
		
		complete += len;
		
	}
	
	//NSLog(@"Send Complete.");
	[aPool release];
}



- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	//NSLog(@"Handle Event:%d", eventCode);
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			
			if (stream == inStream)
				inReady = YES;
			else
				outReady = YES;
			
			if (inReady && outReady) {
				NSLog(@"Stream Opened.");
			}
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == inStream) {
				[self receiveBuffer];
			}
			break;
		}
			
		case NSStreamEventHasSpaceAvailable:
		{
			//NSLog(@"NSStreamEventHasSpaceAvailable");
			//[self performSelectorInBackground:@selector(sendLoop) withObject:nil];
			break;
		}
			
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"%s", _cmd);
			//[self showAlertWithMessage:@"Error encountered on stream!" retryButton:NO];		
			break;
		}
			
		case NSStreamEventEndEncountered:
		{
			//NSArray		*array = [window subviews];
			//TapView		*view;
			//UIAlertView	*alertView;
			
			NSLog(@"%s", _cmd);
			
			//Notify all tap views
			//for(view in array)
			//	[view touchUp:YES];
			
			//alertView = [[UIAlertView alloc] initWithTitle:@"Peer Disconnected!" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			//[alertView show];
			//[alertView release];
			if (stream == inStream) {
				if (mode == BKSessionModeServer) {
					[self setAvailable:YES];
				} else {
					[self showAlertWithMessage:@"Peer Disconnected!" retryButton:YES];
				}
			}
			
			break;
		}
	}
}


@end
