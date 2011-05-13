/*
 <codex>
 <abstract>A TCP server that listens on an arbitrary port.</abstract>
 </codex>
 */

#import <Foundation/Foundation.h>

@class BKServer;

//NSString * const BKServerErrorDomain;

typedef enum {
    kBKServerCouldNotBindToIPv4Address = 1,
    kBKServerCouldNotBindToIPv6Address = 2,
    kBKServerNoSocketsAvailable = 3,
} BKServerErrorCode;


@protocol BKServerDelegate <NSObject>
@optional
- (void) serverDidEnableBonjour:(BKServer*)server withName:(NSString*)name;
- (void) server:(BKServer*)server didNotEnableBonjour:(NSDictionary *)errorDict;
- (void) didAcceptConnectionForServer:(BKServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
@end


@interface BKServer : NSObject {
@private
	id _delegate;
    uint16_t _port;
	CFSocketRef _ipv4socket;
	NSNetService* _netService;
	NSRunLoop* _runLoop;
}
	
- (BOOL)startWithRunLoop:(NSRunLoop *)aRunLoop error:(NSError **)error;
- (BOOL)stop;
- (BOOL) enableBonjourWithDomain:(NSString*)domain applicationProtocol:(NSString*)protocol name:(NSString*)name; //Pass "nil" for the default local domain - Pass only the application protocol for "protocol" e.g. "myApp"
- (void) disableBonjour;

@property(assign) id<BKServerDelegate> delegate;

+ (NSString*) bonjourTypeFromIdentifier:(NSString*)identifier;

@end
