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

protocol EpisodesTableViewControllerDelegate{
    func checkFeedDateIsNew(_ completion:(_ result: Bool) -> Void)
    func refreshfeed()
    func downloadurl(_ urlstring: String)
}

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundSessionCompletionHandler: (() -> Void)?
   // var EpisodesTableViewController: EpisodesTableViewControllerDelegate?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        
        
        // the Custom-Agent is set to identify the App within the Statistics of the podcast
        let defaults = UserDefaults.standard
        let customUserAgent = getObjectForKeyFromPodcastSettings("UserAgent") as! String
        defaults.register(defaults: [customUserAgent : "Custom-Agent"])
        
        
        // the time interval to regularly check for new content is set (UIApplicationBackgroundFetchIntervalMinimum is about every 10 minutes. Remember that this is a MINIMUM - not a Maximum)
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        //request for the right to send notifications
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)

        
        return true
    }
    
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            NSLog("Background refresh started")
            EpisodesTableViewController().refreshfeed()
            let url = getObjectForKeyFromPodcastSettings("feedurl")  as! String
            EpisodesTableViewController().checkFeedDateIsNew{
                (result: Bool) in
                if result {
                    // the file on the server has been update, start downloading a new feed file
                    EpisodesTableViewController().downloadurl(url)
                    completionHandler(UIBackgroundFetchResult.newData)
                }else{
                    NSLog("server feed same date or older")
                    completionHandler(UIBackgroundFetchResult.noData)
                }
            }
       // completionHandler(UIBackgroundFetchResult.Failed)
        NSLog("Background refresh finished")
    }
    
    
    
    func application(_ application: UIApplication, didReceive localNotification:UILocalNotification){
    }

    
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundSessionCompletionHandler = completionHandler
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        NSLog("Going to background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
        // when the App is coming back (from background mode for example), the appIcon badge shall be cleared
        UIApplication.shared.applicationIconBadgeNumber = 0

        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.

    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        let rc = event!.subtype
        
        NSLog("Remote Controll Received with SubType \(rc.rawValue)")
    }


}

