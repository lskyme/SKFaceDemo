//
//  UIAlertController+Extension.h
//  SKFaceDemo
//
//  Created by DFSX on 2018/5/4.
//  Copyright © 2018年 Lskyme. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Extension)

+ (void)showOneActionWithViewController:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle handler:(void (^ __nullable)(UIAlertAction *action))handler;

@end
