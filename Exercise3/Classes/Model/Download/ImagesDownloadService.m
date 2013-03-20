//
//  DownloadImages.m
//  Exercise3
//
//  Created by Madalina Miron on 12/19/12.
//  Copyright (c) 2012 Madalina Miron. All rights reserved.
//

#import "ImagesDownloadService.h"

@interface ImagesDownloadService ()

@property (nonatomic, strong) NSMutableDictionary *receivedDataDictionary;
@property (nonatomic, strong) NSOperationQueue *operationsQueue;

@end

@implementation ImagesDownloadService

+ (id)sharedService
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [self new];
    });
    return _sharedObject;
}

#pragma mark - Init

- (id)init
{
	self = [super init];
	
	if (self) {
        _operationsQueue = [NSOperationQueue new];
        _receivedDataDictionary = [NSMutableDictionary new];
	}
	return self;
}

#pragma mark - Public Methods

- (void)downloadImageUsingNSURLConnection:(NSArray *)urlsArray
{
    for (NSString *urlString in urlsArray) {
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                              timeoutInterval:20.0];
        NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        [theConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
        
        if (theConnection) {
            NSLog(@"Succeeded! Connection is done");
            
            if (![self.receivedDataDictionary objectForKey:urlString]) {
                [self.receivedDataDictionary setObject:[NSMutableData new] forKey:urlString];
            }
        } else {
            NSLog(@"Failed! Connection is not done");
        }
    }
}

- (void)downloadImageUsingNSOperationQueue:(NSArray *)urlsArray
{
    for (NSString *urlString in urlsArray) {
        [self.operationsQueue addOperationWithBlock:^{
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
            
            [self finishedDownload:imageData fromPath:urlString];
        }];
    }
}

- (void)downloadImageUsingGCD:(NSArray *)urlsArray
{
    __block ImagesDownloadService *blockSelf = self;
    for (NSString *urlString in urlsArray) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
            [blockSelf finishedDownload:imageData fromPath:urlString];
        });
    }
}

- (void)downloadImageUsingNSThread:(NSArray *)urlsArray
{
    for (NSString *urlString in urlsArray) {
        [NSThread detachNewThreadSelector:@selector(downloadImageFromURL:) toTarget:self withObject:urlString];
    }
}

- (void)cancelAllOperations
{
    [self.operationsQueue cancelAllOperations];
}

#pragma mark - Private Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSMutableData *receivedData = [self.receivedDataDictionary objectForKey:[[connection currentRequest].URL absoluteString]];
    if (receivedData) {
        [receivedData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSMutableData *receivedData = [self.receivedDataDictionary objectForKey:[[connection currentRequest].URL absoluteString]];
    if (receivedData) {
        [receivedData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *urlString = [[connection currentRequest].URL absoluteString];
	dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableData *receivedData = [self.receivedDataDictionary objectForKey:[[connection currentRequest].URL absoluteString]];
        [self.delegate finishedDownloadingImage:receivedData fromPath:urlString];
        [self.receivedDataDictionary removeObjectForKey:urlString];
    });
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    NSCachedURLResponse *newCachedResponse = cachedResponse;
    
    if ([[[[cachedResponse response] URL] scheme] isEqual:@"https"]) {
        newCachedResponse = nil;
    } else {
        NSDictionary *newUserInfo = [NSDictionary dictionaryWithObject:[NSDate date]
                                                                forKey:@"Cached Date"];
        newCachedResponse = [[NSCachedURLResponse alloc]
                             initWithResponse:[cachedResponse response]
                             data:[cachedResponse data]
                             userInfo:newUserInfo
                             storagePolicy:[cachedResponse storagePolicy]];
    }
    return newCachedResponse;
}

- (void)downloadImageFromURL:(NSString *)urlStringToImage
{
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlStringToImage]];
    [self finishedDownload:imageData fromPath:urlStringToImage];
}

- (void)finishedDownload:(NSData *)downloadData fromPath:(NSString *)dataPath
{
    //move to main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate finishedDownloadingImage:downloadData fromPath:dataPath];
    });
}

@end
