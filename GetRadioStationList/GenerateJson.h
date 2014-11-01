//
//  GenerateJson.h
//  GetRadioStationList
//
//  Created by Liao KuoHsun on 2014/10/27.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadioStationItem: NSObject
{

}

@property (nonatomic, retain) NSString *radioId;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *myTitle;
@property (nonatomic, retain) NSString *myUrl;

@end



@interface GenerateJson : NSObject<NSURLConnectionDelegate, NSXMLParserDelegate>
{

}

@property (strong, nonatomic) NSMutableArray *URLListData;
@property (strong, nonatomic) NSMutableArray *URLListData_Full;

- (void) GetRequest: (NSString *)URL;
@end
