//
//  ViewController.m
//  Exercise3
//
//  Created by Madalina Miron on 12/18/12.
//  Copyright (c) 2012 Madalina Miron. All rights reserved.
//

#import "ScrollDownloadImagesViewController.h"
#import "ImagesDownloadService.h"

@interface ScrollDownloadImagesViewController () <ImagesDownloadServiceDelegate, UIScrollViewDelegate >

@property (nonatomic, strong) IBOutlet UIScrollView *imagesScrollView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *downloadIndicator;
@property (nonatomic, strong) UIImageView *postedImageView;
@property (nonatomic, strong) NSArray *imageURLArray;
@property (nonatomic, strong) NSString *imagesPath;

@end

@implementation ScrollDownloadImagesViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageURLArray = @[@"http://farm1.staticflickr.com/239/521008124_85ec64f28f.jpg",
    @"http://1.bp.blogspot.com/-z4EUTdCvXUE/UDaL3ZthTRI/AAAAAAAAAjY/KWoI7I1o1lY/s1600/yellow+crayon.png" ,
    @"http://www.clker.com/cliparts/h/F/z/P/V/e/crayon-md.png",
    @"https://twimg0-a.akamaihd.net/profile_images/752349976/Carolina-crayon-PNG.png",
    @"http://www.clipartpal.com/_thumbs/pd/education/crayon_orange.png"];
    
    self.imagesScrollView.contentSize = CGSizeMake(self.imagesScrollView.frame.size.width * self.imageURLArray.count, self.imagesScrollView.frame.size.height);
    self.pageControl.numberOfPages = self.imageURLArray.count;
    
    [self downloadUsingDownloadType:self.downloadType];
    
    self.downloadIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.imagesScrollView addSubview:self.downloadIndicator];
    ((ImagesDownloadService *)[ImagesDownloadService sharedService]).delegate = self ;
}

#pragma mark - IB Actions

- (IBAction)changePage
{
    CGRect frame;
    frame.origin.x = self.imagesScrollView.frame.size.width * self.pageControl.currentPage;
    frame.origin.y = 0;
    frame.size = self.imagesScrollView.frame.size;
    [self.imagesScrollView scrollRectToVisible:frame animated:YES];
}

#pragma mark - ImagesDownloadServiceDelegate

- (void)finishedDownloadingImage:(NSData *)receivedData fromPath:(NSString *)urlToImage
{
    UIImage *downloadedImage = [[UIImage alloc] initWithData:receivedData];
    
    NSString *imageSavePath = [[self imagesFolder] stringByAppendingPathComponent:[urlToImage lastPathComponent]];
    [self saveImage:downloadedImage atPath:imageSavePath];
    
    [self setImage:downloadedImage fromPath:urlToImage];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGFloat pageWidth = self.imagesScrollView.frame.size.width;
    int page = floor((self.imagesScrollView.contentOffset.x - pageWidth / 2) / pageWidth)+1;
    self.pageControl.currentPage = page;
}

#pragma mark - Private Methods

- (void)downloadUsingDownloadType:(DownloadTypes)type;
{
    [self.downloadIndicator startAnimating];
    
    NSMutableArray *imageToDownloadArray = [[NSMutableArray alloc] init];
    NSString *docDirectory = [self applicationDocumentsDirectory];
    self.imagesPath = [docDirectory stringByAppendingPathComponent:@"Images"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.imagesPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.imagesPath withIntermediateDirectories:YES attributes:nil error:nil];
    } else {
        [[NSFileManager defaultManager ] removeItemAtPath:self.imagesPath error:nil];
    }
    
    for (NSString* string in self.imageURLArray) {
        
        NSString *imageName = [string lastPathComponent];
        
        NSString *imagePath = [self.imagesPath stringByAppendingPathComponent:imageName];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            [imageToDownloadArray addObject:string];
        } else {
            [self setImage:[UIImage imageWithContentsOfFile:imagePath] fromPath:string];
        }
    }
    
    if ([imageToDownloadArray count] <= 0) {
        return;
    }
    
    switch (type) {
        case DownloadTypeNSURLConnection:
            [[ImagesDownloadService sharedService] downloadImageUsingNSURLConnection:imageToDownloadArray];
            break;
        case DownloadTypeGCD:
            [[ImagesDownloadService sharedService] downloadImageUsingGCD:imageToDownloadArray];
            break;
        case DownloadTypeNSOperationQueue:
            [[ImagesDownloadService sharedService] downloadImageUsingNSOperationQueue:imageToDownloadArray];
            break;
        case DownloadTypeNSThread:
            [[ImagesDownloadService sharedService] downloadImageUsingNSThread:imageToDownloadArray];
            break;
        default:
            break;
    }
}

- (void)setImage:(UIImage*)image fromPath:(NSString *)urlToImage
{
    [self.downloadIndicator stopAnimating];
    self.downloadIndicator.hidesWhenStopped = YES;
    
    for (NSString *urlString in self.imageURLArray) {
        if (urlToImage == urlString) {
            NSUInteger indexOfURL = [self.imageURLArray indexOfObject:urlString];
            CGFloat xOrigin = indexOfURL++ * 320;
            self.postedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(xOrigin, 0, 320, 370)];
        }
    }
    [self.postedImageView setImage:image];
    [self.imagesScrollView addSubview:self.postedImageView];
}

- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString *)imagesFolder
{
    NSString *docDirectory = [self applicationDocumentsDirectory];
    NSString *imagesPath = [docDirectory stringByAppendingPathComponent:@"Images"];
    return imagesPath;
}

- (void)saveImage:(UIImage*)image atPath:(NSString*)path
{
    NSData *myImageData = nil;
    
    if ([[path pathExtension] isEqualToString:@"png"]) {
        myImageData = UIImagePNGRepresentation(image);
    } else if ([[path pathExtension] isEqualToString:@"jpg"]) {
        myImageData = UIImageJPEGRepresentation(image, 1.0);
    }
    
    if (myImageData) {
        BOOL written = [myImageData writeToFile:path atomically:YES];
        if (written) {
            NSLog(@"wrote file");
        } else {
            NSLog(@"did not write file");
        }
    }
}

@end
