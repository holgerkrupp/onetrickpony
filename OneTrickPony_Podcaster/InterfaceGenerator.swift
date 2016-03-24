//
//  InterfaceGeneratorClass.swift
//  DML
//
//  Created by Holger Krupp on 24/03/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation
import UIKit

    
    func createPlayImageWithColor(color: UIColor, size: CGSize, filled: Bool) -> UIImage {
        // Setup our context
        
        print("le color:\(color)")
        
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        
        // Setup complete, do drawing here
        CGContextSetLineWidth(context, 2.0)
        CGContextSetStrokeColorWithColor(context, color.CGColor)
        CGContextSetFillColorWithColor(context, color.CGColor)
        
        
        // draw the triangle for the play button
        CGContextBeginPath(context)
        CGContextMoveToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds))
        CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), bounds.height/2)
        CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMaxY(bounds))
        CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds))
        CGContextClosePath(context)
        
        if filled {
            CGContextFillPath(context)
        }
        CGContextStrokePath(context)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

func createPauseImageWithColor(color: UIColor, size: CGSize, filled: Bool) -> UIImage {
    // Setup our context
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    let opaque = false
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    let context = UIGraphicsGetCurrentContext()
    
    // Setup complete, do drawing here
    CGContextSetLineWidth(context, 2.0)
    CGContextSetStrokeColorWithColor(context, color.CGColor)
    CGContextSetFillColorWithColor(context, color.CGColor)
    
    
    // draw the left bar for the pause button
    CGContextBeginPath(context)
    CGContextMoveToPoint(context,    CGRectGetMinX(bounds), CGRectGetMinY(bounds))
    CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMaxY(bounds))
    CGContextAddLineToPoint(context, bounds.width/3, CGRectGetMaxY(bounds))
    CGContextAddLineToPoint(context, bounds.width/3, CGRectGetMinY(bounds))
    CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds))
    
    
    // draw the right bar for the pause button
    CGContextMoveToPoint(context,    bounds.width/3*2, CGRectGetMinY(bounds))
    CGContextAddLineToPoint(context, bounds.width/3*2, CGRectGetMaxY(bounds))
    CGContextAddLineToPoint(context,  CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))
    CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), CGRectGetMinY(bounds))
    CGContextAddLineToPoint(context, bounds.width/3*2, CGRectGetMinY(bounds))
    CGContextClosePath(context)
    
    if filled {
        CGContextFillPath(context)
    }
    CGContextStrokePath(context)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}