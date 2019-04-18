//
//  ProgramsTableViewController.h
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kProgramDetection,
    kProgramTracking,
} ProgramType;

@interface ProgramsTableViewController : UITableViewController
    
@property (nonatomic, assign) ProgramType type;

@end

