//
//  GenerateJson.m
//  GetRadioStationList
//  A demo to retrieve XML data from network, and then save it into Json format and SQLlite DB.
//
//
//  Created by Liao KuoHsun on 2014/10/27.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import "GenerateJson.h"
#import "MyUtilities.h"
#import <sqlite3.h>

#define DB_STATIION_NAME @"Station.sqlite"

#define GLOBAL_QUEUE dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@implementation RadioStationItem
{

}
@synthesize radioId, title, myTitle, myUrl;
@end


@implementation GenerateJson {
    NSMutableArray   *pStations;
    
    RadioStationItem *pItem;
    NSString *pTitle;
    
    NSString *DB_StationUrl;
}
@synthesize URLListData, URLListData_Full;


- (void) GetRequest: (NSString *)URL {
    dispatch_async(GLOBAL_QUEUE, ^{
        @autoreleasepool {
            NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString:URL]];
            [self performSelectorOnMainThread:@selector(fetchedDataFromHttpGet:) withObject:data waitUntilDone:YES];
        }
    });
}


- (void)fetchedDataFromHttpGet:(NSData *)responseData {
    
    //parse out the json data
    NSError *error;
    
    uint8_t *pBuffer = malloc(responseData.length+1);
    [responseData getBytes:pBuffer length:responseData.length];
    //NSLog(@"responseData=%@\n", responseData);
    //fprintf(stderr,"pBuffer=%s\n", pBuffer);

    // 1. Parse xml and save data in pStations
    NSXMLParser *pXmlParser = [[NSXMLParser alloc] initWithData:responseData];
    [pXmlParser setDelegate:self];
    [pXmlParser parse];
    
    NSLog(@"count=%ld",pStations.count);

    
    // 2. Generate Json from pStations, so that we can use the list easily later
    id objectInstance;
    NSMutableArray*      jsonArray = [[NSMutableArray alloc]init];
    
    for (objectInstance in pStations)
    {
        RadioStationItem *pTmpItem = objectInstance;
        NSMutableDictionary* jsonDictionary =  [[NSMutableDictionary alloc] init];
        
        [jsonDictionary setObject:pTmpItem.radioId forKey:@"id"];
        [jsonDictionary setObject:pTmpItem.title forKey:@"title"];
        [jsonDictionary setObject:pTmpItem.myTitle forKey:@"myTitle"];
        [jsonDictionary setObject:pTmpItem.myUrl forKey:@"myUrl"];
        
        [jsonArray addObject:jsonDictionary];

    }
    
    if([NSJSONSerialization isValidJSONObject:jsonArray])
    {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSString *pFilePath = [[NSString alloc] initWithFormat:@"%@/Documents/%@", NSHomeDirectory() , @"radio_station.json"];
        NSLog(@"pFilePath=%@",pFilePath);
        [jsonString writeToFile:pFilePath atomically:NO encoding:NSUTF8StringEncoding error:&error];
        
        NSLog(@"valid json");
    }
    else
    {
        NSLog(@"invalid json");
    }

    
    // 3. save data into database
    // 3.1. If database is already exist, we update the url data from database
    //DB_StationUrl = [[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:DB_STATIION_NAME];
    DB_StationUrl = [[MyUtilities applicationDocumentsDirectory] stringByAppendingPathComponent:DB_STATIION_NAME];
    if([self DB_exist:DB_StationUrl])
    {
        URLListData_Full = [self DB_Station_GetAllData:DB_STATIION_NAME];
        URLListData = [self GetFavoriteStationList:URLListData_Full];
    }
    // 3.2. If database is not exist,
    else
    {
        //URLListData_Full = [NSMutableArray arrayWithArray:[MyUtilities ProcessJsonData:pJsonData]];
        URLListData_Full = jsonArray;
        
        // Set the default station list to database
        [self DB_Station_Init:URLListData_Full];
        [self DB_Station_DumpData];
        
        // Set the default play list
        [self DB_Station_UpdateField_Favorite:@"177" VALUES:@"1"];
        [self DB_Station_UpdateField_Favorite:@"205" VALUES:@"1"];
        [self DB_Station_UpdateField_Favorite:@"232" VALUES:@"1"];
        [self DB_Station_DumpData];
        
        // Reload the data to URLListData_Full
        URLListData_Full = [self DB_Station_GetAllData:DB_STATIION_NAME];
        
        URLListData = [self GetFavoriteStationList:URLListData_Full];
        
    }
    
    
    // Test
    // a. Dump the station list
    int i = 0;
    NSString *pHLSURL;

    pHLSURL = [self getUrlByRadioStationId: @"177"];
    pHLSURL = [self getUrlByRadioStationId: @"205"];
    //NSLog(@"%@", pHLSURL);
    
//    for(i=0; i<pStations.count; i++)
//    {
//        RadioStationItem *pItem1 = [pStations objectAtIndex:i] ;
//        pHLSURL = [self getUrlByRadioStationId: pItem1.radioId];
//        NSLog(@"%@ %@ %@\n%@", pItem1.radioId, pItem1.title, pItem1.myTitle, pItem1.myUrl);
//    }
//
//
//    for(i=0; i<pStations.count; i++)
//    {
//        RadioStationItem *pItem2 = [pStations objectAtIndex:i] ;
//        pHLSURL = [self getUrlByRadioStationId: pItem2.radioId];
//        pItem2.myUrl = pHLSURL;
//        NSLog(@"%@ %@ %@\n%@", pItem2.radioId, pItem2.title, pItem2.myTitle, pHLSURL);
//    }

    NSLog(@"Done!!");
}


- (NSString *) getUrlByRadioStationId: (NSString *) pRadioStationId {
    
    NSString *pTemplate = @"http://hichannel.hinet.net/player/radio/silverlight.jsp?radio_id=";
    
    NSString *pURL = [pTemplate stringByAppendingFormat:@"%@", pRadioStationId];
    NSData   *pData = [NSData dataWithContentsOfURL: [NSURL URLWithString:pURL]];
    NSString *pStr = [[NSString alloc]initWithData:pData encoding:NSUTF8StringEncoding];
    NSString *pHLSURL;
    
    // http://stackoverflow.com/questions/342577/how-do-i-get-each-line-from-an-nsstring
    unsigned long length = [pStr length];
    unsigned long paraStart = 0, paraEnd = 0, contentsEnd = 0;
    NSMutableArray *array = [NSMutableArray array];
    NSRange currentRange;
    while (paraEnd < length)
    {
        [pStr getParagraphStart:&paraStart end:&paraEnd
                    contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
        currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
        [array addObject:[pStr substringWithRange:currentRange]];
    }
    
    for(id string in array)
    {
        NSRange range1 = [string rangeOfString:@"src: escape(\""];
        if(range1.length!=0)
        {
            //NSLog(@"%ld %ld",range1.location, range1.length);
            NSRange range2 = [string rangeOfString:@"\")"];
            NSRange range3;
            range3.length = range2.location - (range1.location+range1.length);
            range3.location = range1.location+range1.length;
            
            pHLSURL = [string substringWithRange:range3];
            //NSLog(@"%@",string);
            NSLog(@"%@",pHLSURL);
            break;
        }
    }
    
    return pHLSURL;
}



#pragma mark - XML parser
-(void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"elementName %@", elementName);
    if([elementName isEqualToString:@"list"])
    {
        pStations = [[NSMutableArray alloc]init];
    }
    else if([elementName isEqualToString:@"tag"])
    {
        pTitle = [[NSString alloc] initWithString:[attributeDict objectForKey:@"_title"]];
    }
    else if([elementName isEqualToString:@"item"])
    {
        pItem = [[RadioStationItem alloc]init];
        pItem.radioId = [attributeDict objectForKey:@"id"];
        pItem.title = pTitle;
        pItem.myTitle = [[NSString alloc] initWithString:[attributeDict objectForKey:@"myTitle"]];
        pItem.myUrl = [[NSString alloc] initWithString:[attributeDict objectForKey:@"myUrl"]];
        NSLog(@"Id:%@ title:%@ myTitle:%@, myUrl:%@", pItem.radioId, pItem.title, pItem.myTitle, pItem.myUrl);
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if([elementName isEqualToString:@"item"])
    {
        [pStations addObject:pItem];
        pItem = nil;
    }
}


#pragma mark - sqlite Database
// Reference http://furnacedigital.blogspot.tw/2013/06/sqlite3.html

- (BOOL)DB_exist:(NSString *) pDBName
{
    //NSString *url = [[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:pDBName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:pDBName];
    
    // if DB is exist, check if the schema is consistence
    // if schema is different, update the database with new schema
    if(fileExists)
    {
        // old
        //      (SID text primary key, TITLE text, URL text, FAVORITE text)
        // 20141029 update
        //      (SID text primary key, TITLE text, MYTITLE text, MYURL text, FAVORITE text)
        
        sqlite3 *pSqlHandle;
        
        if (sqlite3_open([DB_StationUrl UTF8String], &pSqlHandle) == SQLITE_OK) {
            //查閱所有資料內容
            //建立 Sqlite 語法
            char pQuerySql[1024]={0};
            sprintf(pQuerySql, "select * from STATION where MYTITLE = \"ICRT\";") ;
            //sprintf(pQuerySql, "select * from STATION") ;
            //stm將存放查詢結果
            sqlite3_stmt *statement =nil;
            
            if (sqlite3_prepare_v2(pSqlHandle, pQuerySql, -1, &statement, NULL) == SQLITE_OK) {
                int vCount=0;
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    vCount++;
                }
                
                //使用完畢後將statement清空
                sqlite3_finalize(statement);
            }
            else
            {
                // For database with old schema, error messages "no such column: MYTITLE"
                NSLog(@"%@ error \"%s\"", DB_StationUrl , sqlite3_errmsg(pSqlHandle));
                fileExists = NO;
            }
            //使用完畢後關閉資料庫聯繫
            sqlite3_close(pSqlHandle);
            
            if(fileExists == NO)
            {
                // delete the old database
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error;
                BOOL success = [fileManager removeItemAtPath:DB_StationUrl error:&error];
                
                if (success) {
                    NSLog(@"remove database =%@",DB_StationUrl);
                    // do nothing
                }
                else
                {
                    NSLog(@"%@ ",[error localizedDescription]);
                }
            }
        }
    }
    return fileExists;
}


- (void)DB_Station_Init:(NSArray *) pList
{
    //設定資料庫檔案的路徑
    //NSArray *documentsPath=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *databaseFilePath=[[documentsPath objectAtIndex:0] stringByAppendingPathComponent:@"Exam"];
    
    sqlite3 *pSqlHandle;
    
    NSLog(@"DB STATIION NAME URL=%@", DB_StationUrl);
    
    if (sqlite3_open([DB_StationUrl UTF8String], &pSqlHandle) == SQLITE_OK) {
        NSLog(@"DB OK");
        //這裡寫入要對資料庫操作的程式碼
        //建立表格
        char *errorMsg;
        // {"id": "228", "title": "E-Classical 台北愛樂", "url": "mms://bcr.media.hinet.net/RA000018"},
        const char *createSql="create table if not exists STATION (SID text primary key, TITLE text, MYTITLE text, MYURL text, FAVORITE text)";
        
        if (sqlite3_exec(pSqlHandle, createSql, NULL, NULL, &errorMsg)==SQLITE_OK) {
            NSLog(@"Create STATION table Ok");
            //建立成功之後要對資料庫操作的程式碼
            if(pList!=nil)
            {
                NSInteger i, vCount = [pList count];
                for(i=0;i<vCount;i++)
                {
                    char *insertErrorMsg;
                    char pInsertSql[1024]={0};
                    
                    NSDictionary *URLDict = [pList objectAtIndex:i];
                    NSString *pRaidoId = [URLDict valueForKey:@"id"];
                    NSString *pRaidoTitle = [URLDict valueForKey:@"title"];
                    NSString *pRaidoMyTitle = [URLDict valueForKey:@"myTitle"];
                    NSString *pRaidoMyUrl = [URLDict valueForKey:@"myUrl"];
                    
                    sprintf(pInsertSql,
                            "insert into STATION values ('%s','%s','%s','%s','0')",
                            pRaidoId.UTF8String,
                            pRaidoTitle.UTF8String,
                            pRaidoMyTitle.UTF8String,
                            pRaidoMyUrl.UTF8String
                            );
                    
                    if (sqlite3_exec(pSqlHandle, pInsertSql, NULL, NULL, &insertErrorMsg)==SQLITE_OK) {
                        NSLog(@"INSERT OK");
                    }
                    else
                    {
                        //建立失敗時的處理
                        NSLog(@"error: %s",errorMsg);
                        
                        //清空錯誤訊息
                        sqlite3_free(errorMsg);
                    }
                }
            }
        }
        
        //使用完畢後關閉資料庫聯繫
        sqlite3_close(pSqlHandle);
    }
    else
    {
        NSLog(@"Failed to open database at %@ with error %s", DB_StationUrl , sqlite3_errmsg(pSqlHandle));
        sqlite3_close (pSqlHandle);
    }
}

- (void)DB_Station_DumpData
{
    sqlite3 *pSqlHandle;
    
    if (sqlite3_open([DB_StationUrl UTF8String], &pSqlHandle) == SQLITE_OK)
    {
        //查閱所有資料內容
        //建立 Sqlite 語法
        char pQuerySql[1024]={0};
        sprintf(pQuerySql, "select * from STATION") ;
        
        //stm將存放查詢結果
        sqlite3_stmt *statement =nil;
        
        if (sqlite3_prepare_v2(pSqlHandle, pQuerySql, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                
                // {"id": "228", "title": "E-Classical 台北愛樂", "url": "mms://bcr.media.hinet.net/RA000018"},
                
                NSString *sid, *title, *myTitle, *myUrl, *favorite;
                
                sid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                myTitle = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
                myUrl = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
                favorite = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)];
                
                NSLog(@"SID: %@ ,TITLE: %@ %@, F: %@, URL: %@", sid, title, myTitle, favorite,  myUrl);
            }
            
            //使用完畢後將statement清空
            sqlite3_finalize(statement);
        }
        
        //使用完畢後關閉資料庫聯繫
        sqlite3_close(pSqlHandle);
    }
}



- (NSMutableArray *) GetFavoriteStationList:(NSMutableArray *) pStationList
{
    NSMutableArray *pList = [[NSMutableArray alloc] init];
    NSInteger i, vCount = [pStationList count];
    for(i=0;i<vCount;i++)
    {
        NSDictionary *pDict = [pStationList objectAtIndex:i];
        NSString *pFavorite = [pDict objectForKey:@"favorite"];
        if([pFavorite isEqualToString:@"1"])
        {
            [pList addObject:pDict];
        }
    }
    
    return pList;
}


- (NSMutableArray *)DB_Station_GetAllData:(NSString *) pDBName
{
    sqlite3 *pSqlHandle;
    NSMutableArray *pList = [[NSMutableArray alloc] init];
    
    if (sqlite3_open([DB_StationUrl UTF8String], &pSqlHandle) == SQLITE_OK)
    {
        //查閱所有資料內容
        //建立 Sqlite 語法
        char pQuerySql[1024]={0};
        
        if( [pDBName isEqualToString:DB_STATIION_NAME])
        {
            sprintf(pQuerySql, "select * from STATION") ;
            
            //stm將存放查詢結果
            sqlite3_stmt *statement =nil;
            
            if (sqlite3_prepare_v2(pSqlHandle, pQuerySql, -1, &statement, NULL) == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    
                    NSString *sid, *title, *myTitle, *myUrl, *favorite;
                    
                    sid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                    title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                    myTitle = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
                    myUrl = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
                    favorite = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)];
                    
                    //NSLog(@"SID: %@ ,TITLE: %@, F: %@, URL: %@", sid, title, favorite, url);
                    
                    // NOTE: The keys should be the same as the values defined hinet_radio_json.json
                    NSDictionary *pDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                           sid, @"id",
                                           title, @"title",
                                           myTitle, @"myTitle",
                                           myUrl, @"myUrl",
                                           favorite, @"favorite",
                                           nil];
                    
                    [pList addObject:pDict];
                }
                
                //使用完畢後將statement清空
                sqlite3_finalize(statement);
            }
        }
        
        //使用完畢後關閉資料庫聯繫
        sqlite3_close(pSqlHandle);
        
        return pList;
    }
    else
    {
        return nil;
    }
}


- (void)DB_Station_UpdateField_Favorite:(NSString *) pSID VALUES:(NSString *) pFavoriateSet
{
    sqlite3 *pSqlHandle;
    char *updateErrorMsg;
    char pInsertSql[1024]={0};
    
    if (sqlite3_open([DB_StationUrl UTF8String], &pSqlHandle) == SQLITE_OK) {
        sprintf(pInsertSql,
                "update STATION set FAVORITE='%s' where SID = '%s'",
                pFavoriateSet.UTF8String,
                pSID.UTF8String
                );
        
        if (sqlite3_exec(pSqlHandle, pInsertSql, NULL, NULL, &updateErrorMsg)==SQLITE_OK) {
            NSLog(@"UPDATE OK");
        } else {
            //建立失敗時的處理
            NSLog(@"UPDATE Err: %s",updateErrorMsg);
            
            //清空錯誤訊息
            sqlite3_free(updateErrorMsg);
        }
        
        sqlite3_close(pSqlHandle);
    }
}


@end
