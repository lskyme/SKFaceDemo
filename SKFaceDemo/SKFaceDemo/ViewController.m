//
//  ViewController.m
//  SKFaceDemo
//
//  Created by DFSX on 2018/4/26.
//  Copyright © 2018年 Lskyme. All rights reserved.
//

#import "ViewController.h"
#import "ProgramsTableViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *faceDetectionButton;
@property (weak, nonatomic) IBOutlet UIButton *faceTrackingButton;
    
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[ProgramsTableViewController class]]) {
        ProgramsTableViewController *selectController = (ProgramsTableViewController *)segue.destinationViewController;
        if ([sender isKindOfClass:[UIButton class]]) {
            UIButton *tmpButton = (UIButton *)sender;
            if ([tmpButton isEqual:_faceDetectionButton]) {
                selectController.type = kProgramDetection;
            } else if ([tmpButton isEqual:_faceTrackingButton]) {
                selectController.type = kProgramTracking;
            }
        }
    }
}

@end
