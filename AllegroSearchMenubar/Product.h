//
//  Product.h
//  Popup
//
//  Created by Jonathan Gautheron on 04/01/14.
//
//

#import <Foundation/Foundation.h>

@interface Product : NSObject

@property (strong) NSString *title;
@property (strong) NSImage *thumbImage;

- (id)initWithTitle:(NSString*)title thumbImage:(NSImage *)thumbImage;

@end
