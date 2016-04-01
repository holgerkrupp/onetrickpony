//
//  InterfaceGeneratorClass.swift
//  DML
//
//  Created by Holger Krupp on 24/03/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation
import UIKit


extension Int {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}



    func createPlayImageWithColor(color: UIColor, size: CGSize, filled: Bool) -> UIImage {
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





func createSkipWithColor(color: UIColor, width:CGFloat, size: CGSize, filled: Bool, forward: Bool, label: String) -> UIImage {
    // Setup our context
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    let opaque = false
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    let context = UIGraphicsGetCurrentContext()
    
    // Setup sizes to draw
    let pictureHeight = bounds.height
    let pictureWidth = bounds.width
    let arrowHeight = 10.0 as CGFloat
    
    let radius = floor(pictureHeight/2.0 - arrowHeight/4-width)
    let circleCenterY = floor(pictureHeight/2 + arrowHeight/4 - width)
    let circleCenterX = pictureWidth/2
    
    let clockIndexSize = radius / 3
    
    var angleStart = 90
    var angleStop  = 180
    var clockwise:Int32  = 1
    var arrowRotator:CGFloat = 0
    if forward {
        angleStart = 270
        angleStop  = 000
        clockwise  = 1
        arrowRotator = -1
    }else{
        angleStart = 270
        angleStop  = 180
        clockwise  = 0
        arrowRotator = 1
    }
    
    
    // Setup complete, do drawing here
    CGContextSetLineWidth(context, width)
    CGContextSetStrokeColorWithColor(context, color.CGColor)
    CGContextSetFillColorWithColor(context, color.CGColor)
    
    
    CGContextBeginPath(context)
    
    // north - arrows
    
    CGContextMoveToPoint(context,       circleCenterX, CGRectGetMinY(bounds))
    CGContextAddLineToPoint(context,    circleCenterX, CGRectGetMinY(bounds)+arrowHeight)
    CGContextAddLineToPoint(context,    circleCenterX-arrowHeight/2*arrowRotator, CGRectGetMinY(bounds)+arrowHeight/2)
    CGContextAddLineToPoint(context,    circleCenterX, CGRectGetMinY(bounds))
    
    CGContextMoveToPoint(context,       circleCenterX-arrowHeight/2*arrowRotator-1*arrowRotator, CGRectGetMinY(bounds))
    CGContextAddLineToPoint(context,    circleCenterX-arrowHeight/2*arrowRotator-1*arrowRotator, CGRectGetMinY(bounds)+arrowHeight)
    CGContextAddLineToPoint(context,    circleCenterX-arrowHeight/2*arrowRotator-1*arrowRotator-arrowHeight/2*arrowRotator, CGRectGetMinY(bounds)+arrowHeight/2)
    CGContextAddLineToPoint(context,    circleCenterX-arrowHeight/2*arrowRotator-1*arrowRotator, CGRectGetMinY(bounds))
    if filled {
        CGContextFillPath(context)
    }
    
    CGContextAddArc(context, circleCenterX, circleCenterY, radius, angleStart.degreesToRadians, angleStop.degreesToRadians, clockwise)
    
    // west
    CGContextMoveToPoint(context,    circleCenterX-radius-width/2, circleCenterY)
    CGContextAddLineToPoint(context,    circleCenterX-radius+clockIndexSize, circleCenterY)
    // east
    CGContextMoveToPoint(context,    circleCenterX+radius+width/2, circleCenterY)
    CGContextAddLineToPoint(context,    circleCenterX+radius-clockIndexSize, circleCenterY)
    // south
    CGContextMoveToPoint(context,    circleCenterX, circleCenterY+radius+width/2)
    CGContextAddLineToPoint(context,    circleCenterX, circleCenterY+radius-clockIndexSize)
    
    CGContextStrokePath(context)
    
    // flip coordinate system for text
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // add the text
    let aFont = UIFont(name: "Helvetica Neue", size: radius)
    let attr:CFDictionaryRef = [NSFontAttributeName:aFont!,NSForegroundColorAttributeName:color]
    let text = CFAttributedStringCreate(nil, label, attr)
    let line = CTLineCreateWithAttributedString(text)
    let Linebounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.UseOpticalBounds)
    
    let xn = circleCenterX - Linebounds.width/2
    let yn = circleCenterY - Linebounds.height/2+width
    CGContextSetTextPosition(context, xn, yn)
    
    
    CGContextSetTextDrawingMode(context, CGTextDrawingMode.Fill)
    CTLineDraw(line, context!)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

func createCircleWithCross(color: UIColor, width:CGFloat, size: CGSize, filled: Bool) -> UIImage {
    // Setup our context
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    let opaque = false
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    let context = UIGraphicsGetCurrentContext()
    
    // Setup sizes to draw
    let pictureHeight = bounds.height
    let pictureWidth = bounds.width
    
    let circleCenterY = floor(pictureHeight/2)
    let circleCenterX = floor(pictureWidth/2)
    
    let radius = floor(pictureWidth/2 - width)
    
    let x = sqrt(2*radius) + width //+radius
    let Xheight = pictureHeight - 2*x - pictureHeight/4
    let Xwidth = Xheight
    
    let crossY = (pictureHeight - Xheight)/2
    let crossX = (pictureWidth - Xwidth)/2
    
    CGContextSetLineWidth(context, width)
    CGContextSetStrokeColorWithColor(context, color.CGColor)
    CGContextSetFillColorWithColor(context, color.CGColor)
    
    
    CGContextBeginPath(context)
    CGContextAddArc(context, circleCenterX, circleCenterY, radius, 0.degreesToRadians, 360.degreesToRadians, 1)
    
    CGContextMoveToPoint(context, crossX, crossY)
    CGContextAddLineToPoint(context, crossX+Xwidth, crossY+Xheight)
    
    CGContextMoveToPoint(context, crossX+Xwidth, crossY)
    CGContextAddLineToPoint(context, crossX, crossY+Xheight)
    
    
    if filled {
        CGContextFillPath(context)
    }
    CGContextStrokePath(context)
    
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
    
}

func createCircleWithPause(color: UIColor, width:CGFloat, size: CGSize, filled: Bool) -> UIImage {
    // Setup our context
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    let opaque = false
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    let context = UIGraphicsGetCurrentContext()
    
    // Setup sizes to draw
    let pictureHeight = bounds.height
    let pictureWidth = bounds.width
    
    let circleCenterY = floor(pictureHeight/2)
    let circleCenterX = floor(pictureWidth/2)
    
    let radius = floor(pictureWidth/2 - width)
    
    let x = sqrt(2*radius) + width //+radius
    
    CGContextSetLineWidth(context, width)
    CGContextSetStrokeColorWithColor(context, color.CGColor)
    CGContextSetFillColorWithColor(context, color.CGColor)
    
    
    CGContextBeginPath(context)
    CGContextAddArc(context, circleCenterX, circleCenterY, radius, 0.degreesToRadians, 360.degreesToRadians, 1)
    
    let pause = createPauseImageWithColor(color, size: size, filled: filled).CGImage
    let pauseWidth = pictureWidth - 2*x - pictureWidth/4
    let pauseHeight = pictureHeight - 2*x - pictureHeight/4
    let pauseX = (pictureHeight - pauseHeight)/2
    let pauseY = (pictureWidth - pauseWidth)/2
    
    CGContextDrawImage(context, CGRect(origin: CGPoint(x: pauseX, y: pauseY), size: CGSizeMake(pauseWidth, pauseHeight)), pause)
    
    
    CGContextStrokePath(context)
    
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
    
}

func createCircleWithArrow(color: UIColor, width:CGFloat, size: CGSize, filled: Bool) -> UIImage {
    // Setup our context
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    let opaque = false
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    let context = UIGraphicsGetCurrentContext()
    
    // Setup sizes to draw
    let pictureHeight = bounds.height
    let pictureWidth = bounds.width
    
    let circleCenterY = floor(pictureHeight/2)
    let circleCenterX = floor(pictureWidth/2)
    
    let radius = floor(pictureWidth/2 - width)
    
    let x = sqrt(2*radius) + width //+radius
    
    CGContextSetLineWidth(context, width)
    CGContextSetStrokeColorWithColor(context, color.CGColor)
    CGContextSetFillColorWithColor(context, color.CGColor)
    
    
    CGContextBeginPath(context)
    CGContextAddArc(context, circleCenterX, circleCenterY, radius, 0.degreesToRadians, 360.degreesToRadians, 1)
    
    let arrowHeight = pictureHeight - 2*x - pictureHeight/4
    let arrowWidth:CGFloat = 1/3*arrowHeight
    let arrowX = pictureWidth/2
    let arrowY = (pictureHeight - arrowHeight)/2
    
    CGContextMoveToPoint(context, arrowX, arrowY)
    CGContextAddLineToPoint(context, arrowX, arrowY+arrowHeight)
    CGContextAddLineToPoint(context, arrowX-arrowWidth, arrowY+arrowHeight-arrowWidth)
    CGContextMoveToPoint(context, arrowX, arrowY+arrowHeight)
    CGContextAddLineToPoint(context, arrowX+arrowWidth, arrowY+arrowHeight-arrowWidth)
    
    CGContextStrokePath(context)
    
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
    
}