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
    var episodePubDate:     Date = Date()
    var episodeFilename:    String = String()
    var episodeFilesize:    Int = Int()
    var episodeImage:       String = String()
    var episodePicture:     UIImage?
    var episodeChapter      = [Chapter]()
    var episodeDescription: String = String()
    
    
    //var episodeLocal:       Bool = false
    var episodeIndex:       Int = Int()
    
    
     
    
     
     func getChapterForSeconds(_ progress: Double) -> Chapter? {
  
        
     for (chapter) in episodeChapter.reversed() {
        if (stringtodouble(chapter.chapterStart) < progress) {
            return chapter
        }
     }
        return nil
    }
    
    
    func getprogressinCMTime(_ progress: Double) -> CMTime {
        let seconds = progress //* stringtodouble(episodeDuration)
        let time = CMTimeMake(value: Int64(seconds), timescale: 1)
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
        let time = CMTimeMake(value: Int64(stringtodouble(getDurationFromEpisode())), timescale: 1)
        return time
    }
    
    
    func getDurationInSeconds() -> Double{
        return CMTimeGetSeconds(getDurationinCMTime())
    }
    
    func setDuration(_ duration: CMTime) {
        let seconds = CMTimeGetSeconds(duration)
        episodeDuration = secondsToHoursMinutesSeconds(seconds)
    }
    
    
    
    func remaining() -> CMTime{
        let played = readplayed()
        let duration = stringtodouble(getDurationFromEpisode())
        let remainingtime = CMTimeSubtract(DoubleToCMTime(duration), played)
        return remainingtime
    }
    
    func saveplayed(_ playtime: Double){
        //in seconds
        let defaults = UserDefaults.standard
        defaults.set(episodeTitle, forKey: "LastEpisodePlayed")
        defaults.setValue(playtime, forKey: episodeTitle)
        defaults.synchronize()
    }
    
    func readplayed() -> CMTime{
        
        let defaults = UserDefaults.standard
        var playedtime:CMTime = CMTimeMakeWithSeconds(0,preferredTimescale: Int32(0))
        
        if  let episodeplayedtime = defaults.value(forKey: episodeTitle){
           // NSLog("Title: \(episodeTitle) - Played: \(episodeplayedtime)")
            playedtime = DoubleToCMTime(episodeplayedtime as! Double)
        } else{
            NSLog("Title: \(episodeTitle) - Not played yet")
            playedtime = CMTimeMake(value: 0, timescale: 1)
        }
        return playedtime
    }
    
    func deleteEpisodeFromDocumentsFolder(){
        let existence = existsLocally(episodeFilename)
        if (existence.existlocal){
            let localFeedFile = existence.localURL
            let manager = FileManager.default
            do {
                try manager.removeItem(atPath: localFeedFile)
                NSLog("deleted \(localFeedFile)")
            }catch{
                NSLog("no file to delete")
                
            }
        }
    }
    
    
}

func DoubleToCMTime(_ seconds: Double) -> CMTime{
    if seconds > 0 {
        let secondsInt = Int64(seconds)
        return CMTimeMake(value: secondsInt ,timescale: 1)
    }else{
        return CMTimeMake(value: 0,timescale: 1)
    }
}





func getEpisodeImage(_ episode: Episode, size:CGSize?=nil) -> UIImage{
    
    var episodePicture : UIImage
    episodePicture = UIImage(named: "StandardCover")!
    if (episode.episodeImage != ""){
        let existence = existsLocally(episode.episodeImage)
        if (existence.existlocal){
            do {
                let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: existence.localURL) as NSDictionary?
                if attr != nil {
                    
                    
                    if let image = UIImage(contentsOfFile: existence.localURL){
                        episodePicture = image
                    }
                    
                }
            }catch{
            }
        }else{
            EpisodesTableViewController().downloadurl(episode.episodeImage)
        }
    }
    
    if (size != nil){
      //  NSLog("resize EpisodePicture")
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size!, !hasAlpha, scale)
        episodePicture.draw(in: CGRect(origin: CGPoint.zero, size: size!))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        episodePicture = scaledImage!
    }
   // NSLog("EpisodePicture size: \(episodePicture.size) (\(episode.episodeTitle))")
    return episodePicture
}


func getImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    color.setFill()
    UIRectFill(rect)
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
}

func stringtodouble(_ input :String) -> Double{
    let timeArray = input.components(separatedBy: ":")
    var seconds = 0.0
    
    for element in timeArray{
        seconds = (seconds + Double(element)!) * 60
    }
    seconds = seconds / 60
    return seconds
}

func secondsToHoursMinutesSeconds (_ seconds : Double) -> (String) {
    let (hr,  minf) = modf (seconds / 3600)
    let (min, secf) = modf (60 * minf)
    let rh = hr
    let rm = min
    let rs = 60 * secf
    
    
    var returnstring = String()
    if rh != 0 {
        returnstring = NSString(format: "%02.0f:%02.0f:%02.0f", rh,rm,rs) as String
    }else {
        returnstring = NSString(format: "%02.0f:%02.0f", rm,rs) as String
    }
    return returnstring
}



class Chapter {
    var chapterTitle: String = String()
    var chapterStart: String = String()
    var chapterImage: String = String()
    var chapterLink : String = String()
}
