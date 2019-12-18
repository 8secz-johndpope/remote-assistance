#pragma once
#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,WAProjectLoadStatus)
{
	LoadSuccess,
	LoadFailed_ProjectFileInvalid,
	LoadFailed_ARCoreNotSupported,
	LoadFailed_UserDeclinedARCoreInstall,
	LoadFailed_ARCoreError,
	LoadFailed_ProjectNotCompatible,
	LoadFailed_ARKitNotSupported,
	LoadPending
};


@protocol WAEngineDelegate<NSObject>
@optional
-(void)onProjectLoaded : (WAProjectLoadStatus)loadStatus : (NSString*)projectName : (NSString*)projectFilepath : (NSString*)trackType;
-(void)onSceneLoaded : (bool)loadSuccessful :(NSData*)targetImageBytes;
-(void)onTrackFound : (NSString*)identifier;
-(void)onTrackLost : (NSString*)identifier;
-(void)onImageSearchResults : (NSArray*)ARCloudSearchResults;
-(void)onFrameCaptured : (UIImage*) frame;

@end

@interface ARViewController : GLKViewController
-(BOOL)isARKitSupported;
-(void)loadProject : (NSString*) filePath : (NSString*) defaultSceneName;
-(void)loadProject : (NSString*) filePath;
-(BOOL)loadCloudVocabulary : (NSString*) folderPath : (NSString*) fileName;
-(void)initCloudScan : (NSString*) serverAddress : (NSUInteger) port : (NSString*) secret : (BOOL)animated;
-(void)startCloudScan;
-(void)stopCloudScan;
-(BOOL)isCloudScanActive;
-(void)unloadCurrentProject;
-(void)captrueFrame;
-(void)setDelegate : (id <WAEngineDelegate>) delegate;
-(void)setFlash : (BOOL)mode : (float) level;
@end

@interface ARCloudSearchResult : NSObject
@property (nonatomic, assign) NSUInteger imageId;
@property (nonatomic, assign) NSUInteger score;
@property (nonatomic, retain) NSString* globalTag;
@property (nonatomic, retain) NSString* localTag;
@end
