//
//  EpisodesClass.swift
//  OneTrickPony_Podcaster
//
//  Created by Holger Krupp on 24/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//
import UIKit
import Foundation

class Episode {
    
    var episodeTitle:       String = String()
    var episodeLink:        String = String()
    var episodeUrl:         String = String()
    var episodeDuration:    String = String()
    var episodePubDate:     String = String()
    var episodeFilename:    String = String()
    var episodeFilesize:    Int = Int()
    var episodeImage:       String = String()
    var episodeChapter      = [Chapter]()
    var episodeLocal:       Bool = false
    
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


func fillplayerView(view : EpisodeViewController, episode : Episode){
    let episode = view.episode
    // Text
    view.titleLabel.text = episode.episodeTitle
    
    
    // Time & Slider
    
    let starttime = readplayed(episode)
    let duration = stringtodouble(episode.episodeDuration)
    
    view.progressSlider.maximumValue = Float(duration)
    view.progressSlider.setValue(Float(starttime), animated: false)
    view.playedtime.text = secondsToHoursMinutesSeconds(starttime)
    view.remainingTimeLabel.text = secondsToHoursMinutesSeconds(duration - starttime)

    
    // IMage
    let existence = existslocally(episode.episodeImage)
    if (existence.existlocal){
        view.episodeImage.image = UIImage(named: existence.localURL)
    }else{
        view.episodeImage.image = UIImage(named: "StandardCover")
    }
    
    // rate Button
    if (SingletonClass.sharedInstance.playerinitialized == true) {
        SingletonClass.sharedInstance.player.enableRate = true
        let currentspeed = SingletonClass.sharedInstance.player.rate
        let indexofspeed:Int = view.speeds.indexOf(currentspeed)!
        view.playerRateButton.setTitle(view.speedtext[indexofspeed], forState: .Normal)
    }
    
    
}

func remaining(episode:Episode) -> Double{
    let played = readplayed(episode)
    let douration = stringtodouble(episode.episodeDuration)
    let remainingtime = douration - played
    return remainingtime
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

func saveplayed(episode: Episode, playtime: Double){
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(episode.episodeTitle, forKey: "LastEpisodePlayed")
    defaults.setObject(playtime, forKey: episode.episodeTitle)
    defaults.synchronize()
}

func readplayed(episode: Episode) -> Double{
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var playedtime:Double = 0
    if  let episodeplayedtime = defaults.valueForKey(episode.episodeTitle){
        playedtime = episodeplayedtime  as! Double
    }
    return playedtime
}

class Chapter {
    var chapterTitle: String = String()
    var chapterStart: String = String()
    var chapterImage: String = String()
    var chapterLink : String = String()
}
