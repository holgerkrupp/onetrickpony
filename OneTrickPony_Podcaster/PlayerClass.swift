//
//  PlayerClass.swift
//  DML
//
//  Created by Holger Krupp on 17/04/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//



// under development - currently not used


import Foundation
import MediaPlayer

class Player {

    
    func loadNSURL(episode : Episode) -> NSURL{
        let locally = existsLocally(episode.episodeFilename)
        var url = NSURL()
        if  locally.existlocal{
            url = NSURL(fileURLWithPath: locally.localURL)
        }else{
            url = NSURL(string: episode.episodeUrl)!
        }
        return url
    }
    
    func fixTheDuration(episode: Episode){
        if episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle {
            let duration = SingletonClass.sharedInstance.player.currentItem?.asset.duration
            episode.setDuration(duration!)
            SingletonClass.sharedInstance.episodePlaying.setDuration(duration!)
        }
    }
    
    
    func initplayer(episode: Episode){
        let url = loadNSURL(episode)
        SingletonClass.sharedInstance.player = AVPlayer(URL: url)
        SingletonClass.sharedInstance.episodePlaying = episode
        SingletonClass.sharedInstance.playerinitialized = true
        
        
        SingletonClass.sharedInstance.setaudioSession()
        fixTheDuration(episode)
        updateMPMediaPlayer(episode)
        
    }
    
    func updateMPMediaPlayer(episode: Episode){
        
        let playcenter = MPNowPlayingInfoCenter.defaultCenter()
        let mediaArtwort = MPMediaItemArtwork(image: getEpisodeImage(episode))
        playcenter.nowPlayingInfo = [
            MPMediaItemPropertyArtwork: mediaArtwort,
            
            MPMediaItemPropertyTitle : episode.episodeTitle,
            MPMediaItemPropertyPlaybackDuration: Double(CMTimeGetSeconds(episode.getDurationinCMTime())),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(CMTimeGetSeconds(SingletonClass.sharedInstance.player.currentTime())),
            MPNowPlayingInfoPropertyPlaybackRate: SingletonClass.sharedInstance.player.rate]
    }
    
    
    
    func moveplayer(seconds:Double){
            let secondsToAdd = CMTimeMakeWithSeconds(seconds,1)
            let jumpToTime = CMTimeAdd(SingletonClass.sharedInstance.player.currentTime(), secondsToAdd)
            
            SingletonClass.sharedInstance.player.seekToTime(jumpToTime)
            updatePlayPosition()
           
    }
    
    func updatePlayPosition(){
        let played = SingletonClass.sharedInstance.player.currentTime()
        let episode = SingletonClass.sharedInstance.episodePlaying
        episode.saveplayed(Double(CMTimeGetSeconds(played)))
        NSLog("played: \(Double(CMTimeGetSeconds(played)))")
    }

    
    
    
    
}