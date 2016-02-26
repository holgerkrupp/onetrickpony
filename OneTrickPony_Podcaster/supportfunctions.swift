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


func getValueForKeyFromPodcastSettings(key:String) -> String{
    if let path = NSBundle.mainBundle().pathForResource("PodcastSettings", ofType: "plist") {
        let myDict = NSDictionary(contentsOfFile: path)

        return myDict!.valueForKey("feedurl") as! String
    }else{

        return "plist error"
    }
}

func getHeaderFromUrl(inputurl:String,headerfield:String) -> String {
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
}

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