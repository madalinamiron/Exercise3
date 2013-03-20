//
//  DownloadMenuViewController.m
//  Exercise3
//
//  Created by Madalina Miron on 1/21/13.
//  Copyright (c) 2013 Madalina Miron. All rights reserved.
//

#import "DownloadMenuViewController.h"
#import "ScrollDownloadImagesViewController.h"

@interface DownloadMenuViewController ()

@property (nonatomic, strong) NSDictionary *downloadTypesDictionary;

@end

@implementation DownloadMenuViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.downloadTypesDictionary = @{@"NSURLConnection" : [NSNumber numberWithInt:DownloadTypeNSURLConnection], @"GCD" : [NSNumber numberWithInt:DownloadTypeGCD], @"NSOperationQueue" : [NSNumber numberWithInt:DownloadTypeNSOperationQueue], @"NSThread" : [NSNumber numberWithInt:DownloadTypeNSThread]};    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue destinationViewController] isKindOfClass:[ScrollDownloadImagesViewController class]]) {
        ScrollDownloadImagesViewController *ctrl = (ScrollDownloadImagesViewController *)[segue destinationViewController];
        id selectedDownloadType = [self.downloadTypesDictionary objectForKey:segue.identifier];
        ctrl.downloadType = [((NSNumber *)selectedDownloadType) intValue];
    }
}
@end
