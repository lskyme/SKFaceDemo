//
//  ProgramsTableViewController.m
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import "ProgramsTableViewController.h"
#import "ArcsoftVideoViewController.h"
#import "ArcsoftImageViewController.h"
#import "OpenCVImageViewController.h"
#import "OpenCVVideoViewController.h"

@interface ProgramsTableViewController ()

@end

@implementation ProgramsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (_type) {
        case kProgramDetection:
        switch (indexPath.row) {
            case 0: {
                OpenCVImageViewController *openCVImageVC = [[UIStoryboard storyboardWithName:@"Details" bundle:NSBundle.mainBundle] instantiateViewControllerWithIdentifier:@"OpenCVImageViewController"];
                [self.navigationController pushViewController:openCVImageVC animated:YES];
            }
            break;
            case 1: {
                ArcsoftImageViewController *ArcsoftImageVC = [[UIStoryboard storyboardWithName:@"Details" bundle:NSBundle.mainBundle] instantiateViewControllerWithIdentifier:@"ArcsoftImageViewController"];
                [self.navigationController pushViewController:ArcsoftImageVC animated:YES];
            }
            default:
            break;
        }
        break;
        case kProgramTracking:
        switch (indexPath.row) {
            case 0: {
                OpenCVVideoViewController *openCVVideoVC = [[UIStoryboard storyboardWithName:@"Details" bundle:NSBundle.mainBundle] instantiateViewControllerWithIdentifier:@"OpenCVVideoViewController"];
                [self.navigationController pushViewController:openCVVideoVC animated:YES];
            }
            break;
            case 1: {
                ArcsoftVideoViewController *ArcsoftVideoVC = [[UIStoryboard storyboardWithName:@"Details" bundle:NSBundle.mainBundle] instantiateViewControllerWithIdentifier:@"ArcsoftVideoViewController"];
                [self.navigationController pushViewController:ArcsoftVideoVC animated:YES];
            }
            default:
            break;
        }
        default:
        break;
    }
}

@end
