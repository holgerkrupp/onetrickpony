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
    var episodeDuration:    String = String()
    var episodePubDate:     NSDate = NSDate()
    var episodeFilename:    String = String()
    var episodeFilesize:    Int = Int()
    var episodeImage:       String = String()
    var episodeChapter      = [Chapter]()
    var episodeDescription: String = String()
    
    
    var episodeLocal:       Bool = false
    var episodeIndex:       Int = Int()
    
    
    
    func getprogressinCMTime(progress: Double) -> CMTime {
        let seconds = progress //* stringtodouble(episodeDuration)
        let time = CMTimeMake(Int64(seconds), 1)
        return time
    }
    
    func getDurationinCMTime() -> CMTime {
        let time = CMTimeMake(Int64(stringtodouble(episodeDuration)), 1)
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
        let duration = stringtodouble(episodeDuration)
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
    let existence = existsLocally(episode.episodeImage)
    if (existence.existlocal){
        return UIImage(named: existence.localURL)!
    }else{
        return UIImage(named: "StandardCover")!
    }
}


func fillplayerView(view : EpisodeViewController, episode : Episode){
    let episode = view.episode
    // Text
    view.titleLabel.text = episode.episodeTitle
    view.titleLabel.textColor = getColorFromPodcastSettings("textcolor")
    
    
    // Time & Slider
    
    let starttime = episode.readplayed
    let duration = stringtodouble(episode.episodeDuration)
    
    view.progressSlider.maximumValue = Float(duration)
    let currentplaytime = Float(CMTimeGetSeconds(starttime()))
    
    view.progressSlider.setValue(currentplaytime, animated: false)
  //  view.progressSlider.backgroundColor = getColorFromPodcastSettings("progressBackgroundColor")
    view.progressSlider.minimumTrackTintColor = getColorFromPodcastSettings("highlightColor")
    view.progressSlider.maximumTrackTintColor = getColorFromPodcastSettings("progressBackgroundColor")
    view.progressSlider.setMaximumTrackImage(getImageWithColor(getColorFromPodcastSettings("progressBackgroundColor"),size: CGSizeMake(2, 10)), forState: .Normal)
    view.progressSlider.setMinimumTrackImage(getImageWithColor(getColorFromPodcastSettings("highlightColor"),size: CGSizeMake(2, 10)), forState: .Normal)
    view.progressSlider.setThumbImage(getImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSizeMake(2, 30)), forState: .Normal)
    
    
    view.playedtime.text = secondsToHoursMinutesSeconds(CMTimeGetSeconds(starttime()))
    view.playedtime.textColor = getColorFromPodcastSettings("secondarytextcolor")
    
    view.remainingTimeLabel.text = secondsToHoursMinutesSeconds(CMTimeGetSeconds(episode.remaining()))
    view.remainingTimeLabel.textColor = getColorFromPodcastSettings("secondarytextcolor")
    
    let description = episode.episodeDescription.stringByReplacingOccurrencesOfString("\n", withString: "</br>")
    
    view.episodeShowNotesWebView.loadHTMLString(description, baseURL: nil)
    
    view.episodeImage.image = getEpisodeImage(episode)
    // rate Button
    if (SingletonClass.sharedInstance.playerinitialized == true) {
        let currentspeed = SingletonClass.sharedInstance.player.rate
        if currentspeed != 0 {
            let indexofspeed:Int = view.speeds.indexOf(currentspeed)!
            view.playerRateButton.setTitle(view.speedtext[indexofspeed], forState: .Normal)
        }
    }
    view.playerRateButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
    view.forward30Button.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
    view.back30Button.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
    view.playButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
    view.pauseButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")

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
    // I'm going through the array (which should have max 3 elements) to add up hours, minutes and seconds.
    // to do that I'll add the smaller element to the existing one and multiply by 60
    // because I'm also doing that for the seconds, I have to devide by 60 again. Not nice but it works.
    
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
