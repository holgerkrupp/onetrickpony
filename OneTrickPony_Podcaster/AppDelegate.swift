//
//  AppDelegate.swift
//  OneTrickPony_Podcaster
//
//  Created by Holger Krupp on 24/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import UIKit

import Foundation
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundSessionCompletionHandler: (() -> Void)?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // the Custom-Agent is set to identify the App within the Statistics of the podcast
        let defaults = NSUserDefaults.standardUserDefaults()
        let customUserAgent = getValueForKeyFromPodcastSettings("UserAgent") as! String
        defaults.registerDefaults([customUserAgent : "Custom-Agent"])
        
        
        // the time interval to regularly check for new content is set (UIApplicationBackgroundFetchIntervalMinimum is about every 10 minutes. Remember that this is a MINIMUM - not a Maximum)
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        //request for the right to send notifications
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)


        
        return true
    }
    
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        if let EpisodesTableViewController = window?.rootViewController as? EpisodesTableViewController
        {
            EpisodesTableViewController.refreshfeed()
            print("Background refresh started")
            
        }
    }
    
    
    
    //function to present the localNotification if received.
    func application(application: UIApplication, didReceiveLocalNotification localNotification:UILocalNotification){
       // UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
    }

    
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        backgroundSessionCompletionHandler = completionHandler
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        let rc = event!.subtype
        
        print("Remote Controll Received with SubType \(rc.rawValue)")
    }


}

