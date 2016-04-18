//
//  EpisodesClass.swift
//  OneTrickPony_Podcaster
//
//  Created by Holger Krupp on 24/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//
import UIKit
import Foundation
import CoreMedia


class Episode {
    
    var episodeTitle:       String = String()
    var episodeLink:        String = String()
    var episodeUrl:         String = String()
    var episodeDuration:    String? = String()
    var episodePubDate:     NSDate = NSDate()
    var episodeFilename:    String = String()
    var episodeFilesize:    Int = Int()
    var episodeImage:       String = String()
    var episodeChapter      = [Chapter]()
    var episodeDescription: String = String()
    
    
    var episodeLocal:       Bool = false
    var episodeIndex:       Int = Int()
    
    /*
     
     Further implementation to be done: To mark the current chapter playing and showing the chapter title within the player
     
     
     func getChapterForSeconds(progress: Double) -> Chapter {
        
    }*/
    
    
    func getprogressinCMTime(progress: Double) -> CMTime {
        let seconds = progress //* stringtodouble(episodeDuration)
        let time = CMTimeMake(Int64(seconds), 1)
        return time
    }
    
    func getDurationFromEpisode() -> String{
        if episodeDuration != "", let Duration = episodeDuration {
            return Duration
        }else{
            NSLog("no duration")
            return "0000"
        }
    }
    
    func getDurationinCMTime() -> CMTime {
        let time = CMTimeMake(Int64(stringtodouble(getDurationFromEpisode())), 1)
        return time
    }
    
    
    func getDurationInSeconds() -> Double{
        return CMTimeGetSeconds(getDurationinCMTime())
    }
    
    func setDuration(duration: CMTime) {
    let seconds = CMTimeGetSeconds(duration)
        episodeDuration = secondsToHoursMinutesSeconds(seconds)
    }
    

    
    func remaining() -> CMTime{
        let played = readplayed()
        let duration = stringtodouble(getDurationFromEpisode())
        let remainingtime = CMTimeSubtract(DoubleToCMTime(duration), played)
        return remainingtime
    }
    
    func saveplayed(playtime: Double){
        //in seconds
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(episodeTitle, forKey: "LastEpisodePlayed")
        defaults.setValue(playtime, forKey: episodeTitle)
        defaults.synchronize()
    }
    
    func readplayed() -> CMTime{
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var playedtime:CMTime = CMTimeMakeWithSeconds(0,Int32(0))
        
        if  let episodeplayedtime = defaults.valueForKey(episodeTitle){
            playedtime = DoubleToCMTime(episodeplayedtime as! Double)
        } else{
            playedtime = CMTimeMake(0, 1)
        }
        return playedtime
    }
    
    func deleteEpisodeFromDocumentsFolder(){
        let manager = NSFileManager.defaultManager()
        let existence = existsLocally(episodeFilename)
        if (existence.existlocal){
            let localFeedFile = existence.localURL
            do {
                try manager.removeItemAtPath(localFeedFile)
                NSLog("deleted")
                episodeLocal = false
            }catch{
                NSLog("no file to delete")
                
            }
        }
    }
    
    
}

func DoubleToCMTime(seconds: Double) -> CMTime{
    let secondsInt = Int64(seconds)
    return CMTimeMake(secondsInt ,1)
}





func getEpisodeImage(episode: Episode) -> UIImage{
    
    if (episode.episodeImage != ""){
        let existence = existsLocally(episode.episodeImage)
        if (existence.existlocal){
            return UIImage(named: existence.localURL)!
        }else{
 
            EpisodesTableViewController().downloadurl(episode.episodeImage)
            
            return UIImage(named: "StandardCover")!
        }
    }else {
        return UIImage(named: "StandardCover")!
    }
}


func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
    let rect = CGRectMake(0, 0, size.width, size.height)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    color.setFill()
    UIRectFill(rect)
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

func stringtodouble(input :String) -> Double{
    let timeArray = input.componentsSeparatedByString(":")
    var seconds = 0.0

    for element in timeArray{
        seconds = (seconds + Double(element)!) * 60
    }
    seconds = seconds / 60
    return seconds
}

func secondsToHoursMinutesSeconds (seconds : Double) -> (String) {
    let (hr,  minf) = modf (seconds / 3600)
    let (min, secf) = modf (60 * minf)
    let rh = hr
    let rm = min
    let rs = 60 * secf
    
    let returnstring = NSString(format: "%02.0f:%02.0f:%02.0f", rh,rm,rs) as String
    return returnstring
}



class Chapter {
    var chapterTitle: String = String()
    var chapterStart: String = String()
    var chapterImage: String = String()
    var chapterLink : String = String()
}
