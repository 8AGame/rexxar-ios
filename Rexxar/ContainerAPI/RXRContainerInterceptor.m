//
//  RXRContainerInterceptor.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRContainerInterceptor.h"
#import "NSHTTPURLResponse+Rexxar.h"
#import "RXRContainerAPI.h"

static NSArray<id<RXRContainerAPI>> *_containerAPIs;

@implementation RXRContainerInterceptor

+ (void)setContainerAPIs:(NSArray<id<RXRContainerAPI>> *)containerAPIs
{
  _containerAPIs = [containerAPIs copy];
}

+ (NSArray<id<RXRContainerAPI>> *)containerAPIs
{
  return _containerAPIs;
}

#pragma mark - Implement NSURLProtocol methods

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
  // 请求不是来自浏览器，不处理
  if (![request.allHTTPHeaderFields[@"User-Agent"] hasPrefix:@"Mozilla"]) {
    return NO;
  }

  for (id<RXRContainerAPI> containerAPI in _containerAPIs) {
    if ([containerAPI shouldInterceptRequest:request]) {
      return YES;
    }
  }

  return NO;
}

- (void)startLoading
{
  for (id<RXRContainerAPI> containerAPI in _containerAPIs) {
    if ([containerAPI shouldInterceptRequest:self.request]) {

      if ([containerAPI respondsToSelector:@selector(prepareWithRequest:)]) {
        [containerAPI prepareWithRequest:self.request];
      }

      if ([containerAPI respondsToSelector:@selector(performWithRequest:)]) {
        [containerAPI performWithRequest:self.request];
      }

      NSData *data = [containerAPI responseData];
      NSURLResponse *response = [containerAPI responseWithRequest:self.request];
      [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
      [self.client URLProtocol:self didLoadData:data];
      [self.client URLProtocolDidFinishLoading:self];
      break;
    }
  }
}

@end
