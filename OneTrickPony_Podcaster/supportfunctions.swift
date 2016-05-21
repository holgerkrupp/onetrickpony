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


func checkUsedDiskSpace() -> Int? {
    let manager = NSFileManager.defaultManager()
    let documentsDirectoryURL =  try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
    
    var bool: ObjCBool = false
    if manager.fileExistsAtPath(documentsDirectoryURL.path!, isDirectory: &bool) {
        if bool.boolValue {
            // lets get the folder files
            let fileManager =  NSFileManager.defaultManager()
            let files = try! fileManager.contentsOfDirectoryAtURL(documentsDirectoryURL, includingPropertiesForKeys: nil, options: [])
            var folderFileSizeInBytes = 0
            for file in files {
                folderFileSizeInBytes +=  try! (fileManager.attributesOfItemAtPath(file.path!) as NSDictionary).fileSize().hashValue
            }

            return folderFileSizeInBytes
        }
    }
    return nil
}


func getListOfFiles() -> [NSURL]? {
    let directory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    let properties = [NSURLLocalizedNameKey, NSURLCreationDateKey, NSURLContentModificationDateKey, NSURLLocalizedTypeDescriptionKey]
    if let urlArray = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(directory,
        includingPropertiesForKeys: properties, options:.SkipsHiddenFiles) {
        
        return urlArray.map { url -> (NSURL, NSTimeInterval) in
            var lastModified : AnyObject?
            _ = try? url.getResourceValue(&lastModified, forKey: NSURLContentModificationDateKey)
                return (url, lastModified?.timeIntervalSinceReferenceDate ?? 0)
            }
            .sort({ $0.1 < $1.1 }) // sort modification dates
            .map { $0.0 } // extract files
        
        
    } else {
        return nil
    }
}


func filterFiles(fileList: [NSURL], filterList: [String]) -> [NSURL]?{
    var outputList = [NSURL]()
    for item in fileList {
        let fileextension = item.pathExtension! as String
        if !filterList.contains(fileextension) {
            outputList.append(item)
        }
    }
    return outputList
}

func cleanUpSpace(){
    var UsedSpace = checkUsedDiskSpace()
    let cacheSize = getObjectForKeyFromPodcastSettings("cacheSize (MB)") as! Int * 1024 * 1024 // convert from MB to Byte
    
    if (UsedSpace != nil){
        // format it using NSByteCountFormatter to display it properly
        let  byteCountFormatter =  NSByteCountFormatter()
        byteCountFormatter.allowedUnits = .UseMB
        byteCountFormatter.countStyle = .File
        let folderSizeToDisplay = byteCountFormatter.stringFromByteCount(Int64(UsedSpace!))
        let cacheSizeToDisplay = byteCountFormatter.stringFromByteCount(Int64(cacheSize))
        NSLog("used space: \(folderSizeToDisplay) cache Size: \(cacheSizeToDisplay)")
        
        while UsedSpace > cacheSize {
            NSLog("Need to delete files")
            let filter = ["jpg","png","xml"] // elements to be filtered out / not included
            var files = filterFiles(getListOfFiles()!,filterList: filter)
          //  NSLog("Files in Folder: \(files)")
            
            
            // delete first element in list
            if files?.count > 1 { // delete only if there are more than one file in the filtered list
                let manager = NSFileManager.defaultManager()
                do {
                    let filename = files![0].lastPathComponent
                    
                    let documentsDirectoryUrl =  NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                    let localFeedFile = documentsDirectoryUrl + "/" + filename!
                    
                    
                    NSLog("filename to be deleted: \(filename)")
                    try manager.removeItemAtPath(localFeedFile)
                    files?.removeFirst()
                    NSLog("deleted")
                }catch{
                    NSLog("no file to delete")
                    
                }
            }
            UsedSpace = checkUsedDiskSpace()
            
        }
        
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