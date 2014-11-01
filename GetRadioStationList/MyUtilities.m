//
//  MyUtilities.m
//  FFmpegAudioPlayer
//
//  Created by Liao KuoHsun on 2013/11/11.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#import "MyUtilities.h"

@implementation MyUtilities

+ (NSArray *)ProcessJsonData:(NSData *)pJsonData
{
    //parse out the json data
    NSError* error;
    
    NSMutableDictionary* jsonDictionary = [NSJSONSerialization JSONObjectWithData:pJsonData //1
                                                                          options:NSJSONReadingAllowFragments
                                                                            error:&error];
    if(error!=nil)
    {
        //NSString* aStr;
        //aStr = [[NSString alloc] initWithData:pJsonData encoding:NSUTF8StringEncoding];
        //NSLog(@"str=%@",aStr);
        
        NSLog(@"json transfer error %@", error);
        return nil;
        
    }
    
    
#if 0
    // 1) retrieve the URL list into NSArray
    //    URLListData = [jsonDictionary objectForKey:@"url_list"];
    //    if(URLListData==nil)
    //    {
    //        NSLog(@"URLListData load error!!");
    //        return;
    //    }
    //    NSLog(@"URLListData=%@",URLListData);
    
#else
    
    NSSortDescriptor *lastDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"title"
                                ascending:YES
                                 selector:@selector(compare:)];
    //localizedCaseInsensitiveCompare
    
    // TODO: change NSMutableArray to NSArray
    NSMutableArray *anArray = [jsonDictionary objectForKey:@"url_list"];
    
    
    NSArray *descriptors = [NSArray arrayWithObjects:lastDescriptor, nil];
    
    NSArray *pTemp = [anArray sortedArrayUsingDescriptors:descriptors];
    
    // Get Program list
    //    int i;
    //    for (i=0;i<[pTemp count];i++)
    //    {
    //        NSLog(@"%@",[[pTemp objectAtIndex:i] valueForKey:@"title"]);
    //    }
    
    return pTemp;
    
    
    
#endif
}



#pragma mark - Get System information

vm_size_t usedMemory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

vm_size_t freeMemory(void) {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}


#pragma mark - File Processing

+ (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


+ (NSString *) getAbsoluteFilepath:(NSString *) pFilename
{
    NSString *pURLString = [[NSString alloc] initWithFormat:@"%@/Documents/%@", NSHomeDirectory() , pFilename ];
    return pURLString;
}

+ (BOOL)removeAudioFile:(NSString *)pFilename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:pFilename];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    
    if (success) {
        NSLog(@"remove Audio File, filePath=%@",filePath);
        // do nothing
        
        //UIAlertView *removeSuccessFulAlert=[[UIAlertView alloc]initWithTitle:@"Congratulation:" message:@"Successfully removed" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
    }
    else
    {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
    
    return success;
}

+ (BOOL)renameAudioFile:(NSString *)pFilename toNewFilename:(NSString *)pNewFilename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:pFilename];
    
    // Rename the file, by moving the file
    NSString *filePath2 = [documentsPath stringByAppendingPathComponent:pNewFilename];
    
    NSError *error;
    
    // Attempt the move
    BOOL success = [fileManager moveItemAtPath:filePath toPath:filePath2 error:&error];
    //NSLog(@"rename Audio File from %@ to %@",pFilename, pNewFilename);
    NSLog(@"rename Audio File from %@ to %@",filePath, filePath2);
    if (success) {
        NSLog(@"rename Success");
        //UIAlertView *removeSuccessFulAlert=[[UIAlertView alloc]initWithTitle:@"Congratulation:" message:@"Successfully removed" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
    }
    else
    {
        NSLog(@"Could not rename file -:%@ ",[error localizedDescription]);
    }
    
    return success;
}


@end
