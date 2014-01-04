//
//  AllegroApi.m
//  Popup
//
//  Created by Jonathan Gautheron on 03/01/14.
//
//

#import "AllegroApi.h"
#import "TouchXML.h"

#define ALLEGRO_API_URL "https://webapi.allegro.pl/service.php"
#define ALLEGRO_API_KEY "815120a7"

static NSString *const eventProductsLoaded = @"productsLoaded";

@implementation AllegroApi {
    NSMutableData *responseData;
    NSString *sessionHandle;
    NSMutableArray *products;
}


#pragma mark Singleton Methods

+ (id)sharedManager {
    static AllegroApi *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        [self login];
    }
    return self;
}

- (void)dealloc
{
    // Should never be called, but just here for clarity really.
}

- (void)login
{
    NSString *soapMessage = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                             "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns1=\"https://webapi.allegro.pl/service.php\">"
                             "<SOAP-ENV:Body>"
                             "<ns1:DoLoginEncRequest>"
                                "<ns1:userLogin>%@</ns1:userLogin>"
                                "<ns1:userHashPassword>%@</ns1:userHashPassword>"
                                "<ns1:countryCode>%@</ns1:countryCode>"
                                "<ns1:webapiKey>%@</ns1:webapiKey>"
                                "<ns1:localVersion>%@</ns1:localVersion>"
                             "</ns1:DoLoginEncRequest>"
                             "</SOAP-ENV:Body>"
                             "</SOAP-ENV:Envelope>\n", @"jgautheron", @"OYdv16+Le1e4slLVSrK+7aCkRImnnAGPh7/xqWVD3Cc=", @"1", @ALLEGRO_API_KEY, @"1387797084"];
    
    [self doSoapRequest:soapMessage soapMethodName:@"DoLoginEnc"];
}

- (void)search:(NSString *)searchString
{
    NSLog(@"search for %@", searchString);
    
    NSString *soapMessage = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                             "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns1=\"https://webapi.allegro.pl/service.php\">"
                             "<SOAP-ENV:Body>"
                             "<ns1:DoSearchRequest>"
                             "<ns1:sessionHandle>%@</ns1:sessionHandle>"
                             "<ns1:searchQuery>"
                             "<ns1:searchString>%@</ns1:searchString>"
                             "<ns1:searchOptions>%@</ns1:searchOptions>"
                             "<ns1:searchOrder>%@</ns1:searchOrder>"
                             "<ns1:searchOrderType>%@</ns1:searchOrderType>"
                             "<ns1:searchOffset>%@</ns1:searchOffset>"
                             "<ns1:searchLimit>%@</ns1:searchLimit>"
                             "</ns1:searchQuery>"
                             "</ns1:DoSearchRequest>"
                             "</SOAP-ENV:Body>"
                             "</SOAP-ENV:Envelope>\n", sessionHandle, searchString, @"136", @"4", @"0", @"0", @"5"];
    
    
    [self doSoapRequest:soapMessage soapMethodName:@"DoSearch"];
}

- (void)doSoapRequest:(NSString *)soapMessage soapMethodName:(NSString *)soapMethodName;
{
    NSString *apiUrl = @ALLEGRO_API_URL;
    
    NSURL *url = [NSURL URLWithString:apiUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapMessage length]];
    
    soapMethodName = [NSString stringWithFormat:@"#%@", soapMethodName];
    
    [request addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue: soapMethodName forHTTPHeaderField:@"SOAPAction"];
    [request addValue: msgLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (!connection) {
        // couldn't query
        NSLog(@"no connection");
    }
}

-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    responseData = [[NSMutableData alloc] init]; // _data being an ivar
}
-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [responseData appendData:data];
}
-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    // Handle the error properly
    NSLog(@"error");
}
-(void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    NSString *xml = [[NSString alloc] initWithBytes:[responseData mutableBytes] length:[responseData length] encoding:NSUTF8StringEncoding];
    CXMLDocument *xmlParser = [[CXMLDocument alloc] initWithXMLString:xml options:0 error:nil];

    // in order for TouchXML to be able to parse namespaces it is necessary to create a dictionary
    NSDictionary *mappings = [NSDictionary dictionaryWithObject:@"https://webapi.allegro.pl/service.php" forKey:@"ns1"];
    
    // which response is it?
    NSURLRequest *request = [connection currentRequest];
    NSDictionary *headers = [request allHTTPHeaderFields];
    NSString *soapAction  = [headers objectForKey:@"SOAPAction"];
    
    // @todo handle empty results (faultcode)
    
    void (^selectedCase)() = @{
        @"#DoLoginEnc" : ^{
            NSArray *nodes = [xmlParser nodesForXPath:@"//ns1:sessionHandlePart" namespaceMappings:mappings error:nil];
            sessionHandle  = [[nodes objectAtIndex:0] stringValue];
            NSLog(@"session = %@", sessionHandle);
        },
        @"#DoSearch" : ^{
            // reinit the array
            products = [NSMutableArray new];
            
            NSArray *nodes = [xmlParser nodesForXPath:@"//ns1:searchArray/ns1:item" namespaceMappings:mappings error:nil];
            for (CXMLElement *node in nodes) {
                NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
                
                int counter;
                for (counter = 0; counter < [node childCount]; counter++) {
                    [item setObject:[[node childAtIndex:counter] stringValue] forKey:[[node childAtIndex:counter] name]];
                }
                
                [products addObject:item];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:eventProductsLoaded object: self];
        }
    }[soapAction];
    
    if (selectedCase != nil) {
        selectedCase();
    }
    
}

- (NSMutableArray *) getProducts {
    return products;
}

@end
