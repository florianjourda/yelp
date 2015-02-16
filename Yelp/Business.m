
//
//  Business.m
//  Yelp
//
//  Created by Florian Jourda on 2/10/15.
//  Copyright (c) 2015 codepath. All rights reserved.
//

#import "Business.h"


@implementation Business

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];

    if (self) {
        NSArray *categories = dictionary[@"categories"];
        NSMutableArray *categoryNames = [NSMutableArray array];
        [categories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [categoryNames addObject:obj[0]];
        }];
        self.categories = [categoryNames componentsJoinedByString:@", "];

        self.name = dictionary[@"name"];
        self.imageUrl = dictionary[@"image_url"];
        NSArray *addressParts = [dictionary valueForKeyPath:@"location.address"];
        NSString *street = (addressParts.count > 0) ? addressParts[0] : @"";
        NSString *neighborhood = [dictionary valueForKeyPath:@"location.neighborhoods"][0];
        self.address = [NSString stringWithFormat:@"%@, %@", street, neighborhood];


        CGFloat latitude = [[dictionary valueForKeyPath:@"location.coordinate.latitude"] floatValue];
        CGFloat longitude = [[dictionary valueForKeyPath:@"location.coordinate.longitude"] floatValue];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude;
        coordinate.longitude = longitude;
        self.coordinate = coordinate;

        self.numReviews = [dictionary[@"review_count"] integerValue];
        self.ratingImageUrl = dictionary[@"rating_img_url"];
        float milesPerMeter = 0.000621371;
        self.distance = [dictionary[@"distance"] integerValue] * milesPerMeter;
    }


    return self;
}

+ (NSArray *)businessesWithDictionaries:(NSArray *)dictionaries {
    NSMutableArray *businesses = [NSMutableArray array];
    for (NSDictionary *dictonary in dictionaries) {
        Business *business = [[Business alloc] initWithDictionary:dictonary];
        [businesses addObject:business];
    }

    return businesses;
}

@end
