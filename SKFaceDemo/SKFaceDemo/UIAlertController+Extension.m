//
//  UIAlertController+Extension.m
//  SKFaceDemo
//
//  Created by DFSX on 2018/5/4.
//  Copyright © 2018年 Lskyme. All rights reserved.
//

#import "UIAlertController+Extension.h"

@implementation UIAlertController (Extension)

+(void)showOneActionWithViewController:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle handler:(void (^)(UIAlertAction *))handler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:handler];
    [alertController addAction:action];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

@end
