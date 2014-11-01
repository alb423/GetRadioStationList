//
//  AppDelegate.m
//  GetRadioStationList
//
//  Created by Liao KuoHsun on 2014/10/27.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import "AppDelegate.h"
#import "GenerateJson.h"
@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    GenerateJson *pJson = [[GenerateJson alloc] init] ;
    [pJson GetRequest:@"http://hichannel.hinet.net/xml/radioList.jsp"];
 
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}




@end
