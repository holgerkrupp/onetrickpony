//
//  supportfunctions.swift
//  DML
//
//  Created by Holger Krupp on 18/02/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


func getObjectForKeyFromPersistentStorrage(_ key:String) -> Any?{
    if let object = UserDefaults.standard.object(forKey: key){
        return object as AnyObject?
    }else{
        return nil
    }
}

func setObjectForKeyToPersistentStorrage(_ key:String, object:Any){
    UserDefaults.standard.set(object, forKey: key)
}

func removePersistentStorrage(){
    let appdomain = Bundle.main.bundleIdentifier
    UserDefaults.standard.removePersistentDomain(forName: appdomain!)
}

func getObjectForKeyFromPodcastSettings(_ key:String) -> Any{
    if let path = Bundle.main.path(forResource: "PodcastSettings", ofType: "plist") {
        let myDict = NSDictionary(contentsOfFile: path)

        return myDict!.object(forKey: key)! as AnyObject
    }else{

        return "plist error" as AnyObject
    }
}


func getColorFromPodcastSettings(_ key: String) -> UIColor {
    var color:UIColor
    let PodcastColor = getObjectForKeyFromPodcastSettings(key)
    if let colorComponents = PodcastColor as? NSDictionary{
        color = UIColor(
        red: colorComponents.object(forKey: "red") as! CGFloat,
        green: colorComponents.object(forKey: "green") as! CGFloat,
        blue: colorComponents.object(forKey: "blue") as! CGFloat,
        alpha: colorComponents.object(forKey: "alpha") as! CGFloat)
       // return color
    }else{
        let colorcode = UInt32(PodcastColor as! String, radix: 16)
        color = UIColor(hex6: colorcode!)

    }
    return color
}


func showErrorMessage(_ title: String, message: String, viewController : UIViewController){
    let refreshAlert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    
    refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
       // NSLog("Handle Ok logic here")
    }))
    viewController.present(refreshAlert, animated: true, completion: nil)
}



func getHeaderFromUrl(_ inputurl:String,headerfield:String) -> String {
    let url = URL(string: inputurl)!
    let request = NSMutableURLRequest(url: url)
    request.httpMethod = "HEAD"
    var header = String()
    var response : URLResponse?
    do{
        try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
        if let httpResp: HTTPURLResponse = response as? HTTPURLResponse {
            if let headercontent = httpResp.allHeaderFields[headerfield]{
                
                header = headercontent as! String
                return header
            }
        }
        } catch {
        }
    return header
}

func dateStringToNSDate(_ date:String,format:String="EEE, dd MMM yyyy HH:mm:ss z") -> Date?{
    let locale = Locale(identifier: "en_US_POSIX")
    let dateFormatter = DateFormatter()
    dateFormatter.locale = locale
    dateFormatter.dateFormat = format
    if let formatedDate = dateFormatter.date(from: date) {
        return formatedDate
    }
    return nil
}

func dateOfFile(_ checkurl:String) -> Date? {
    let manager = FileManager.default
    let url: URL = URL(string: checkurl)!
    let documentsDirectoryUrl =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let fileName = url.lastPathComponent as String
    let localFeedFile = documentsDirectoryUrl + "/" + fileName
    
    do {
        let fileAttributes = try manager.attributesOfItem(atPath: localFeedFile)
        let date = fileAttributes[FileAttributeKey.modificationDate] as! Date
        return date
    } catch {
        print("Error: \(error)")
        return nil
    }
}


func checkUsedDiskSpace() -> Int? {
    let manager = FileManager.default
    let documentsDirectoryURL =  try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    
    var bool: ObjCBool = false
    if manager.fileExists(atPath: documentsDirectoryURL.path, isDirectory: &bool) {
        if bool.boolValue {
            // lets get the folder files
            let fileManager =  FileManager.default
            let files = try! fileManager.contentsOfDirectory(at: documentsDirectoryURL, includingPropertiesForKeys: nil, options: [])
            var folderFileSizeInBytes = 0
            for file in files {
              //  folderFileSizeInBytes +=  try! (fileManager.attributesOfItem(atPath: file.path) as NSDictionary).fileSize().hashValue
            }

            return folderFileSizeInBytes
        }
    }
    return nil
}


func getListOfFiles() -> [URL]? {
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let properties = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.contentModificationDateKey, URLResourceKey.localizedTypeDescriptionKey]
    if let urlArray = try? FileManager.default.contentsOfDirectory(at: directory,
        includingPropertiesForKeys: properties, options:.skipsHiddenFiles) {
        
        return urlArray.map { url -> (URL, TimeInterval) in
            var lastModified : AnyObject?
            _ = try? (url as NSURL).getResourceValue(&lastModified, forKey: URLResourceKey.contentModificationDateKey)
                return (url, lastModified?.timeIntervalSinceReferenceDate ?? 0)
            }
            .sorted(by: { $0.1 < $1.1 }) // sort modification dates
            .map { $0.0 } // extract files
        
        
    } else {
        return nil
    }
}


func filterFiles(_ fileList: [URL], filterList: [String]) -> [URL]?{
    var outputList = [URL]()
    for item in fileList {
        let fileextension = item.pathExtension as String
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
        let  byteCountFormatter =  ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useMB
        byteCountFormatter.countStyle = .file
        let folderSizeToDisplay = byteCountFormatter.string(fromByteCount: Int64(UsedSpace!))
        let cacheSizeToDisplay = byteCountFormatter.string(fromByteCount: Int64(cacheSize))
        NSLog("used space: \(folderSizeToDisplay) cache Size: \(cacheSizeToDisplay)")
        let filter = ["jpg","png","xml"] // elements to be filtered out / not included
        var files = filterFiles(getListOfFiles()!,filterList: filter)

        if files?.count > 1 {  // delete only if there are more than one file in the filtered list

        while UsedSpace > cacheSize {
            NSLog("Need to delete files")
          //  NSLog("Files in Folder: \(files)")
            
            //files = filterFiles(getListOfFiles()!,filterList: filter)
                let manager = FileManager.default
                do {
                    let filename = files![0].lastPathComponent
                    
                    let documentsDirectoryUrl =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                    let localFeedFile = documentsDirectoryUrl + "/" + filename
                    
                    
                    NSLog("filename to be deleted: \(filename)")
                    try manager.removeItem(atPath: localFeedFile)
                    files?.removeFirst()
                    NSLog("deleted")
                }catch{
                    NSLog("no file to delete")
                    
                }
            UsedSpace = checkUsedDiskSpace()
            NSLog("new used space: \(byteCountFormatter.string(fromByteCount: Int64(UsedSpace!)))")
            }
            
            
        }
        
    }
}

func existsLocally(_ checkurl: String) -> (existlocal : Bool, localURL : String) {
    let manager = FileManager.default
    if let url: URL = URL(string: checkurl){
        let documentsDirectoryUrl =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let fileName = url.lastPathComponent as String
        let localFeedFile = documentsDirectoryUrl + "/" + fileName
    
        if manager.fileExists(atPath: localFeedFile){
            return (true, localFeedFile)
        } else {
            return (false, localFeedFile)
        }
    }else{
        return (false, "")
    }
}
