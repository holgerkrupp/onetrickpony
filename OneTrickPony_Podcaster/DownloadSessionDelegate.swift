//
//  DownloadSessionDelegate.swift
//  OneTrickPony_Podcaster
//
//  Created by Holger Krupp on 28/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation

typealias CompleteHandlerBlock = () -> ()

class DownloadSessionDelegate : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    
    var handlerQueue: [String : CompleteHandlerBlock]!
    
    class var sharedInstance: DownloadSessionDelegate {
        struct Static {
            static var instance : DownloadSessionDelegate?
            static var token : dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = DownloadSessionDelegate()
            Static.instance!.handlerQueue = [String : CompleteHandlerBlock]()
        }
        
        return Static.instance!
    }
    
    //MARK: session delegate
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("session error: \(error?.localizedDescription).")
    }
    

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print("session \(session) has finished the download task \(downloadTask) of URL \(location).")
        
        
        //HERE MOVE FILE TO DOCUMENTS FOLDER
        
        //Get documents directory URL
        
        
        let tempUrl = location
        
        var originalUrl = downloadTask.originalRequest?.URL
        
        //Get the file name and create a destination URL
            
        if originalUrl!.pathExtension == "" {
            print("empty")
            originalUrl = originalUrl?.URLByAppendingPathComponent("feed.xml")
        }
        
        
        let fileName = originalUrl!.lastPathComponent!
        let documentsDirectoryUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let destinationURL = documentsDirectoryUrl!.URLByAppendingPathComponent(fileName)
        
        print("the file will be moved to \(destinationURL).")
        //Hold this file as an NSData and write it to the new location
        if let fileData = NSData(contentsOfURL: tempUrl) {
            fileData.writeToURL(destinationURL, atomically: false)   // true
        }
        
        
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes.")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("session \(session) download task \(downloadTask) resumed at offset \(fileOffset) bytes out of an expected \(expectedTotalBytes) bytes.")
    }
    
    
    func indexfordownloadtask(downloadTask: NSURLSessionDownloadTask) -> Int? {
        
        if let url = downloadTask.originalRequest?.URL?.absoluteString {
            
            print(globals.episodes)
            for (index, episode) in globals.episodes.enumerate() {
                print("\(index) - \(episode.episodeTitle)")
                if url == episode.episodeUrl {
                    return index
                }
            }
        }
        return nil
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error == nil {
            print("session \(session) download completed")
        } else {
            print("session \(session) download failed with error \(error?.localizedDescription)")
        }
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("background session \(session) finished events.")
        
        if !session.configuration.identifier!.isEmpty {
     //       callCompletionHandlerForSession(session.configuration.identifier)
        }
    }

}