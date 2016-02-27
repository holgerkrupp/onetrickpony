//
//  supportfunctions.swift
//  DML
//
//  Created by Holger Krupp on 18/02/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation
import UIKit

func getvalueforkeyfrompersistentstrrage(key:String) -> AnyObject{

    if let value = NSUserDefaults.standardUserDefaults().objectForKey(key){
        return value
    }else{
        return "_EMPTY_"
    }
}

func setvalueforkeytopersistentstorrage(key:String, value:AnyObject){
    NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
}


func getValueForKeyFromPodcastSettings(key:String) -> AnyObject{
    if let path = NSBundle.mainBundle().pathForResource("PodcastSettings", ofType: "plist") {
        let myDict = NSDictionary(contentsOfFile: path)

        return myDict!.objectForKey(key)!
    }else{

        return "plist error"
    }
}


func getColorFromPodcastSettings(key: String) -> UIColor {
    let colorComponents = getValueForKeyFromPodcastSettings(key) as! NSDictionary
    let color = UIColor(
        red: colorComponents.objectForKey("red") as! CGFloat,
        green: colorComponents.objectForKey("green") as! CGFloat,
        blue: colorComponents.objectForKey("blue") as! CGFloat,
        alpha: colorComponents.objectForKey("alpha") as! CGFloat)
    return color
}


func getHeaderFromUrl(inputurl:String,headerfield:String) -> String {
    let url = NSURL(string: inputurl)!
    var responseHeader = ""
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "HEAD"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    let config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    let session: NSURLSession = NSURLSession(configuration: config)
    
    let dataTask: NSURLSessionDataTask = session.dataTaskWithRequest(request,completionHandler:{(data: NSData?, response: NSURLResponse?,error: NSError?) -> Void in
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if let headerfieldresponse = httpResponse.allHeaderFields[headerfield] as? String {
                print("Header resp\(headerfieldresponse)")
                responseHeader = headerfieldresponse
            }
        }
    })
    dataTask.resume()
    return responseHeader
}


/*func getHeaderFromUrl(inputurl:String,headerfield:String) -> String {
    let url = NSURL(string: inputurl)!
    var responseHeader = ""
    let task = NSURLSession.sharedSession().dataTaskWithURL(url) {
        data, response, error in
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if let headerfieldresponse = httpResponse.allHeaderFields[headerfield] as? String {
                print(headerfieldresponse)
               responseHeader = headerfieldresponse
            }
        }
    }
    task.resume()
    return responseHeader
}*/

func existslocally(checkurl: String) -> (existlocal : Bool, localURL : String) {
    let manager = NSFileManager.defaultManager()
    let url: NSURL = NSURL(string: checkurl)!
    let documentsDirectoryUrl =  NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    let fileName = url.lastPathComponent! as String
    let localFeedFile = documentsDirectoryUrl + "/" + fileName
    
    if manager.fileExistsAtPath(localFeedFile){
        //print("\(localFeedFile) is available")
        return (true, localFeedFile)
    } else {
        //print("\(localFeedFile) is not available")
        return (false, localFeedFile)
    }
}