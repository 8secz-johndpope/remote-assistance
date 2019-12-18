

#ifndef WANetworkManager_h
#define WANetworkManager_h
@protocol WADownloadDelegate
- (void)downloadStarted: (NSString*)url;
- (void)downloadProgress: (NSString*)url : (float)progress;
- (void)downloadComplete: (NSString*)url : (NSString*)localPath : (BOOL)fromCache;
- (void)searchComplete: (NSArray*)results;
- (void)downloadError: (NSString*)url : (NSString*)errorMessage;
@end

@interface WAPublishServerManager: NSObject <NSURLSessionDownloadDelegate>
+ (id) instance;
- (void) setDelegate: (id<WADownloadDelegate>) delegate;
- (id) init;
- (void) downloadOrLoadProject: (NSString*)projectURL;
- (BOOL) deleteCache;
- (NSMutableDictionary*) getDownloadsDictionary;
- (void) searchProjects : (NSString*)publishServerURL : (NSString*)organizationId : (NSString*)searchTerm;

//TODO: implement the following functions
- (BOOL) stopDownload: (NSURLSessionDataTask*)task;
- (BOOL) stopAllDownloads;
@end
#endif /* WANetworkManager_h */
