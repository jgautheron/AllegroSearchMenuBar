//
//  AllegroApi.h
//  Popup
//
//  Created by Jonathan Gautheron on 03/01/14.
//
//

@interface AllegroApi : NSObject<NSURLConnectionDelegate>

@property (nonatomic, retain) NSMutableData *_responseData;
@property (nonatomic, retain) NSString *_sessionHandle;
@property (nonatomic, retain) NSMutableArray *_products;

- (void)doSoapRequest:(NSString *)soapMessage soapMethodName:(NSString *)soapMethodName;

- (void)login;
- (void)search:(NSString *)searchString;

- (NSMutableArray *)getProducts;

+ (id)sharedManager;

@end