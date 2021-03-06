//
//  SwitchCell.h
//  Yelp
//
//  Created by Florian Jourda on 2/11/15.
//  Copyright (c) 2015 codepath. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SwitchCell;

@protocol SwitchCellDelegate <NSObject>

- (void)switchCell:(SwitchCell *)switchCell didUpdateValue:(Boolean) value;

@end

@interface SwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) BOOL on;
@property (nonatomic, weak) id<SwitchCellDelegate> delegate;


- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end
