//
//  supportfunctions.swift
//  DML
//
//  Created by Holger Krupp on 18/02/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation
import UIKit

func getObjectForKeyFromPersistentStorrage(key:String) -> AnyObject?{
    if let object = NSUserDefaults.standardUserDefaults().objectForKey(key){
        return object
    }else{
        return nil
    }
}

func setObjectForKeyToPersistentStorrage(key:String, object:AnyObject){
    NSUserDefaults.standardUserDefaults().setObject(object, forKey: key)
}

func removePersistentStorrage(){
    let appdomain = NSBundle.mainBundle().bundleIdentifier
    NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appdomain!)
}

func getObjectForKeyFromPodcastSettings(key:String) -> AnyObject{
    if let path = NSBundle.mainBundle().pathForResource("PodcastSettings", ofType: "plist") {
        let myDict = NSDictionary(contentsOfFile: path)

        return myDict!.objectForKey(key)!
    }else{

        return "plist error"
    }
}


func getColorFromPodcastSettings(key: String) -> UIColor {
    var color:UIColor
    let PodcastColor = getObjectForKeyFromPodcastSettings(key)
    if let colorComponents = PodcastColor as? NSDictionary{
        color = UIColor(
        red: colorComponents.objectForKey("red") as! CGFloat,
        green: colorComponents.objectForKey("green") as! CGFloat,
        blue: colorComponents.objectForKey("blue") as! CGFloat,
        alpha: colorComponents.objectForKey("alpha") as! CGFloat)
       // return color
    }else{
        let colorcode = UInt32(PodcastColor as! String, radix: 16)
        color = UIColor(hex6: colorcode!)

    }
    return color
}


func showErrorMessage(title: String, message: String, viewController : UIViewController){
    let refreshAlert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    
    refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
       // NSLog("Handle Ok logic here")
    }))
    viewController.presentViewController(refreshAlert, animated: true, completion: nil)
}



func getHeaderFromUrl(inputurl:String,headerfield:String) -> String {
    let url = NSURL(string: inputurl)!
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "HEAD"
    var header = String()
    var response : NSURLResponse?
    do{
        try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        if let httpResp: NSHTTPURLResponse = response as? NSHTTPURLResponse {
            if let headercontent = httpResp.allHeaderFields[headerfield]{
                
                header = headercontent as! String
                return header
            }
        }
        } catch {
        }
    return header
}

func dateStringToNSDate(date:String,format:String="EEE, dd MMM yyyy HH:mm:ss z") -> NSDate?{
    let locale = NSLocale(localeIdentifier: "en_US_POSIX")
    let dateFormatter = NSDateFormatter()
    dateFormatter.locale = locale
    dateFormatter.dateFormat = format
    if let formatedDate = dateFormatter.dateFromString(date) {
        return formatedDate
    }
    return nil
}

func dateOfFile(checkurl:String) -> NSDate? {
    let manager = NSFileManager.defaultManager()
    let url: NSURL = NSURL(string: checkurl)!
    let documentsDirectoryUrl =  NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    let fileName = url.lastPathComponent! as String
    let localFeedFile = documentsDirectoryUrl + "/" + fileName
    
    do {
        let fileAttributes = try manager.attributesOfItemAtPath(localFeedFile)
        let date = fileAttributes[NSFileModificationDate] as! NSDate
        return date
    } catch {
        print("Error: \(error)")
        return nil
    }
}

func existsLocally(checkurl: String) -> (existlocal : Bool, localURL : String) {
    let manager = NSFileManager.defaultManager()
    let url: NSURL = NSURL(string: checkurl)!
    let documentsDirectoryUrl =  NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    let fileName = url.lastPathComponent! as String
    let localFeedFile = documentsDirectoryUrl + "/" + fileName
    
    if manager.fileExistsAtPath(localFeedFile){
        return (true, localFeedFile)
    } else {
        return (false, localFeedFile)
    }
}