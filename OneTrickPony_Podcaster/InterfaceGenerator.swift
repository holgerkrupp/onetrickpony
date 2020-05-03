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
        return CGFloat(self) * CGFloat(Double.pi) / 180.0
    }
}



    func createPlayImageWithColor(_ color: UIColor, size: CGSize, filled: Bool) -> UIImage {
        // Setup our context
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        
        // Setup complete, do drawing here
        context?.setLineWidth(2.0)
        context?.setStrokeColor(color.cgColor)
        context?.setFillColor(color.cgColor)
        
        
        // draw the triangle for the play button
        context?.beginPath()
        context?.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
        context?.addLine(to: CGPoint(x: bounds.maxX, y: bounds.height/2))
        context?.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        context?.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY))
        context?.closePath()
        
        if filled {
            context?.fillPath()
        }
        context?.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

func createPauseImageWithColor(_ color: UIColor, size: CGSize, filled: Bool) -> UIImage {
    // Setup our context
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    let opaque = false
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    let context = UIGraphicsGetCurrentContext()
    
    // Setup complete, do drawing here
    context?.setLineWidth(2.0)
    context?.setStrokeColor(color.cgColor)
    context?.setFillColor(color.cgColor)
    
    
    // draw the left bar for the pause button
    context?.beginPath()
    context?.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
    context?.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
    context?.addLine(to: CGPoint(x: bounds.width/3, y: bounds.maxY))
    context?.addLine(to: CGPoint(x: bounds.width/3, y: bounds.minY))
    context?.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY))
    
    
    // draw the right bar for the pause button
    context?.move(to: CGPoint(x: bounds.width/3*2, y: bounds.minY))
    context?.addLine(to: CGPoint(x: bounds.width/3*2, y: bounds.maxY))
    context?.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
    context?.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
    context?.addLine(to: CGPoint(x: bounds.width/3*2, y: bounds.minY))
    context?.closePath()
    
    if filled {
        context?.fillPath()
    }
    context?.strokePath()
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}





func createSkipWithColor(_ color: UIColor, width:CGFloat, size: CGSize, filled: Bool, forward: Bool, label: String) -> UIImage {
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
    var clockwise:Bool  = true
    var arrowRotator:CGFloat = 0
    if forward {
        angleStart = 270
        angleStop  = 000
        clockwise  = true
        arrowRotator = -1
    }else{
        angleStart = 270
        angleStop  = 180
        clockwise  = false
        arrowRotator = 1
    }
    
    
    // Setup complete, do drawing here
    context?.setLineWidth(width)
    context?.setStrokeColor(color.cgColor)
    context?.setFillColor(color.cgColor)
    
    
    context?.beginPath()
    
    // north - arrows
    
    context?.move(to: CGPoint(x: circleCenterX, y: bounds.minY))
    context?.addLine(to: CGPoint(x: circleCenterX, y: bounds.minY+arrowHeight))
    context?.addLine(to: CGPoint(x: circleCenterX-arrowHeight/2*arrowRotator, y: bounds.minY+arrowHeight/2))
    context?.addLine(to: CGPoint(x: circleCenterX, y: bounds.minY))
    
    context?.move(to: CGPoint(x: circleCenterX-arrowHeight/2*arrowRotator-1*arrowRotator, y: bounds.minY))
    context?.addLine(to: CGPoint(x: circleCenterX-arrowHeight/2*arrowRotator-1*arrowRotator, y: bounds.minY+arrowHeight))
    context?.addLine(to: CGPoint(x: circleCenterX-arrowHeight/2*arrowRotator-1*arrowRotator-arrowHeight/2*arrowRotator, y: bounds.minY+arrowHeight/2))
    context?.addLine(to: CGPoint(x: circleCenterX-arrowHeight/2*arrowRotator-1*arrowRotator, y: bounds.minY))
    if filled {
        context?.fillPath()
    }
    
    context?.addArc(center: CGPoint(x: circleCenterX, y: circleCenterY), radius: radius, startAngle: angleStart.degreesToRadians, endAngle: angleStop.degreesToRadians, clockwise: clockwise)
    
    
    // west
    context?.move(to: CGPoint(x: circleCenterX-radius-width/2, y: circleCenterY))
    context?.addLine(to: CGPoint(x: circleCenterX-radius+clockIndexSize, y: circleCenterY))
    // east
    context?.move(to: CGPoint(x: circleCenterX+radius+width/2, y: circleCenterY))
    context?.addLine(to: CGPoint(x: circleCenterX+radius-clockIndexSize, y: circleCenterY))
    // south
    context?.move(to: CGPoint(x: circleCenterX, y: circleCenterY+radius+width/2))
    context?.addLine(to: CGPoint(x: circleCenterX, y: circleCenterY+radius-clockIndexSize))
    
    context?.strokePath()
    
    // flip coordinate system for text
    context?.translateBy(x: 0, y: bounds.size.height);
    context?.scaleBy(x: 1.0, y: -1.0);
    
    // add the text
    let aFont = UIFont(name: "Helvetica Neue", size: radius)
    //let attr:CFDictionary = [NSFontAttributeName:aFont!,NSForegroundColorAttributeName:color]
  //  let attr = CFAttributedStringCreate(nil,  [NSFontAttributeName:aFont! as AnyObject,NSForegroundColorAttributeName:color as AnyObject], nil)
    //let attr = [NSFontAttributeName:aFont]
    
    
    let attributes: [String: AnyObject] = [
        NSAttributedString.Key.foregroundColor.rawValue : color,
        NSAttributedString.Key.font.rawValue : aFont!
    ]
    
    
    

    
    let text = CFAttributedStringCreate(nil, label as CFString?, attributes as CFDictionary?)
    
    
    
    
    let line = CTLineCreateWithAttributedString(text!)
    let Linebounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.useOpticalBounds)
    
    let xn = circleCenterX - Linebounds.width/2
    let yn = circleCenterY - Linebounds.height/2+width
    context?.textPosition = CGPoint(x:xn, y: yn)
    
    
    
    
    context?.setTextDrawingMode(CGTextDrawingMode.fill)
    CTLineDraw(line, context!)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}

func createCircleWithCross(_ color: UIColor, width:CGFloat, size: CGSize, filled: Bool) -> UIImage {
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
    
    context?.setLineWidth(width)
    context?.setStrokeColor(color.cgColor)
    context?.setFillColor(color.cgColor)
    
    
    context?.beginPath()
    context?.addArc(center: CGPoint(x: circleCenterX, y: circleCenterY), radius: radius, startAngle: 0.degreesToRadians, endAngle: 360.degreesToRadians, clockwise: true)
    
    
    context?.move(to: CGPoint(x: crossX, y: crossY))
    context?.addLine(to: CGPoint(x: crossX+Xwidth, y: crossY+Xheight))
    
    context?.move(to: CGPoint(x: crossX+Xwidth, y: crossY))
    context?.addLine(to: CGPoint(x: crossX, y: crossY+Xheight))
    
    
    if filled {
        context?.fillPath()
    }
    context?.strokePath()
    
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
    
}

func createCircleWithPause(_ color: UIColor, width:CGFloat, size: CGSize, filled: Bool) -> UIImage {
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
    
    context?.setLineWidth(width)
    context?.setStrokeColor(color.cgColor)
    context?.setFillColor(color.cgColor)
    
    
    context?.beginPath()
        context?.addArc(center: CGPoint(x: circleCenterX, y: circleCenterY), radius: radius, startAngle: 0.degreesToRadians, endAngle: 360.degreesToRadians, clockwise: true)
    
    let pause = createPauseImageWithColor(color, size: size, filled: filled).cgImage
    let pauseWidth = pictureWidth - 2*x - pictureWidth/4
    let pauseHeight = pictureHeight - 2*x - pictureHeight/4
    let pauseX = (pictureHeight - pauseHeight)/2
    let pauseY = (pictureWidth - pauseWidth)/2
    
    context?.draw(pause!, in: CGRect(origin: CGPoint(x: pauseX, y: pauseY), size: CGSize(width: pauseWidth, height: pauseHeight)))
    
    
    context?.strokePath()
    
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
    
}

func createCircleWithArrow(_ color: UIColor, width:CGFloat, size: CGSize, filled: Bool) -> UIImage {
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
    
    context?.setLineWidth(width)
    context?.setStrokeColor(color.cgColor)
    context?.setFillColor(color.cgColor)
    
    
    context?.beginPath()
        context?.addArc(center: CGPoint(x: circleCenterX, y: circleCenterY), radius: radius, startAngle: 0.degreesToRadians, endAngle: 360.degreesToRadians, clockwise: true)
    
    let arrowHeight = pictureHeight - 2*x - pictureHeight/4
    let arrowWidth:CGFloat = 1/3*arrowHeight
    let arrowX = pictureWidth/2
    let arrowY = (pictureHeight - arrowHeight)/2
    
    context?.move(to: CGPoint(x: arrowX, y: arrowY))
    context?.addLine(to: CGPoint(x: arrowX, y: arrowY+arrowHeight))
    context?.addLine(to: CGPoint(x: arrowX-arrowWidth, y: arrowY+arrowHeight-arrowWidth))
    context?.move(to: CGPoint(x: arrowX, y: arrowY+arrowHeight))
    context?.addLine(to: CGPoint(x: arrowX+arrowWidth, y: arrowY+arrowHeight-arrowWidth))
    
    context?.strokePath()
    
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
    
}
