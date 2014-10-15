//
//  HKDataRequestSender.m
//  DataHandlerDemo
//
//  Created by Hai Kieu on 10/14/14.
//  Copyright (c) 2014 haikieu2907@gmail.com. All rights reserved.
//

#import "HKDataRequestSender.h"
#import <UIKit/UIKit.h>
@implementation HKDataRequestSender
{
    HKDataRequestStatus _requestStatus;
}

@synthesize requestTag=_requestTag;

-(HKDataRequestStatus)requestStatus
{
    return _requestStatus;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestStatus = HKDataRequestStatusDoing;
    }
    return self;
}

-(instancetype)initSender:(id<HKDataRequestDelegate>)sender withRoot:(HKDataRequestSender *)root
{
    self = [super init];
    if (self) {
        root.roofSender = self;
        self.rootSender = root;
        _sender = sender;
        root.requestStatus = self.requestStatus = root ? root.requestStatus : HKDataRequestStatusDoing;
    }
    return self;
}

#pragma node body

-(NSString *)requestTag
{
    if([self isFinalRoot])
        return _requestTag;
    else
        return [[self finalRoot] requestTag];
}

-(void)setRequestTag:(NSString *)requestTag
{
    if([self isFinalRoot])
        _requestTag = requestTag;
    else
        return [[self finalRoot] setRequestTag:requestTag];
}

#pragma request business

-(void)cancel
{
    [[self finalRoot] cancelRequest];
}

-(void)cancelRequest
{
    _requestStatus |= HKDataRequestStatusCancel;
    [[self roofSender] cancelRequest];
}

-(void)dataRequestComplete:(id<HKDataRequestResult>)result
{
    //TODO - need verify this condition
    if([self requestStatus]==HKDataRequestStatusCancel)
        return;
    
    _requestStatus = HKDataRequestStatusCompleted;
    
    if([_sender respondsToSelector:@selector(dataRequestPreComplete:)])
    {
        [_sender dataRequestPreComplete:result];
    }

    [_sender dataRequestComplete:result];
    
    if([_sender respondsToSelector:@selector(dataRequestPostComplete:)])
    {
        [_sender dataRequestPostComplete:result];
    }
    
    //forward the result to original sender
    [[self rootSender] dataRequestComplete:result];
    
    //decouple node linking by set all properties by weak
    [self decoupleRequestLinking];
}

#pragma memory management

- (void) tightRequestLinking
{
    
}

- (void) decoupleRequestLinking
{
    //TODO
}

- (void) neutrilizeRequestLinking
{
    //TODO
}


-(void)dealloc
{
    [self neutrilizeRequestLinking];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma node linking algorithm

-(HKDataRequestSender *)finalRoot
{
    if([self isFinalRoot])
        return self;
    else
        return [self rootSender];
}

-(HKDataRequestSender *)finalRoof
{
    if([self isFinalRoof])
        return self;
    else
        return [self roofSender];
}

-(BOOL)isFinalRoot
{
    return [self rootSender] == nil;
}

-(BOOL)isMediator
{
    return ![self isFinalRoot];
}

-(BOOL)isFinalRoof
{
    return [self roofSender] == nil;
}

-(NSUInteger)totalLevel
{
    return [self currentLevel] + [self upLevel];
}

-(NSUInteger)currentLevel
{
    return [self downLevel] + 1;
}

-(NSUInteger)upLevel
{
    return (self.roofSender != nil) + [self.roofSender upLevel];
}

-(NSUInteger)downLevel
{
    return (self.rootSender != nil) + [self.rootSender downLevel];
}

#ifdef DEBUG

#pragma stack trace

-(void)stackTrace
{
    [[self finalRoot] printTraceInfo];
}

-(void)printTraceInfo
{
    NSLog(@"%@", [self traceInfo]);
    [[self roofSender] printTraceInfo];
}

-(NSString *)statusInfo
{
    switch (_requestStatus) {
        case HKDataRequestStatusCancel:
            return @"Cancel";
        case HKDataRequestStatusCompleted:
            return @"Completed";
        case HKDataRequestStatusDoing:
            return @"Doing";
        case HKDataRequestStatusUnknown:
            return @"N/A";
    }
}

-(NSString *)traceInfo
{
    NSUInteger requestOrder = [self currentLevel];
    NSString * statusInfo = [self statusInfo];
    NSString * senderClass = NSStringFromClass([self.sender class]);

    return [NSString stringWithFormat:@"[%lu]%@ status:%@",requestOrder, senderClass,statusInfo];
}

#endif

@end
