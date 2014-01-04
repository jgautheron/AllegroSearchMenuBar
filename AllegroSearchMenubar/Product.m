//
//  Product.m
//  Popup
//
//  Created by Jonathan Gautheron on 04/01/14.
//
//

#import "Product.h"

@implementation Product

- (id)initWithTitle:(NSString*)title thumbImage:(NSImage *)thumbImage {
    if ((self = [super init])) {
        self.title = title;
        self.thumbImage = thumbImage;
    }
    return self;
}

@end