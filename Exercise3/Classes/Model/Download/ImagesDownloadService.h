//
//  DownloadImages.h
//  Exercise3
//
//  Created by Madalina Miron on 12/19/12.
//  Copyright (c) 2012 Madalina Miron. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol ImagesDownloadServiceDelegate

@required
- (void)finishedDownloadingImage:(NSData *)imageData fromPath:(NSString *)urlToImage;

@end
@interface ImagesDownloadService : NSObject

+ (id)sharedService;

@property (nonatomic, weak) id<ImagesDownloadServiceDelegate> delegate;

- (void)downloadImageUsingNSURLConnection:(NSArray *)urlsArray;
- (void)downloadImageUsingNSOperationQueue:(NSArray *)urlsArray;
- (void)downloadImageUsingGCD:(NSArray *)urlsArray;
- (void)downloadImageUsingNSThread:(NSArray *)urlsArray;
- (void)cancelAllOperations;

@end
