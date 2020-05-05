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

    
    func loadNSURL(_ episode : Episode) -> URL{
        let locally = existsLocally(episode.episodeFilename)
        if  locally.existlocal{
             return URL(fileURLWithPath: locally.localURL)
        }else{
            return URL(string: episode.episodeUrl)!
        }
    }
    
    func fixTheDuration(_ episode: Episode){
        if episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle {
            let duration = SingletonClass.sharedInstance.player.currentItem?.asset.duration
            episode.setDuration(duration!)
            SingletonClass.sharedInstance.episodePlaying.setDuration(duration!)
        }
    }
    
    
    func initplayer(_ episode: Episode){
        let url = loadNSURL(episode)
        SingletonClass.sharedInstance.player = AVPlayer(url: url)
        SingletonClass.sharedInstance.episodePlaying = episode
        SingletonClass.sharedInstance.playerinitialized = true
        
        
        SingletonClass.sharedInstance.setaudioSession()
        fixTheDuration(episode)
        updateMPMediaPlayer(episode)
        
    }
    
    func updateMPMediaPlayer(_ episode: Episode){
        
        let playcenter = MPNowPlayingInfoCenter.default()
        let mediaArtwort = MPMediaItemArtwork(image: getEpisodeImage(episode))
        playcenter.nowPlayingInfo = [
            MPMediaItemPropertyArtwork: mediaArtwort,
            
            MPMediaItemPropertyTitle : episode.episodeTitle,
            MPMediaItemPropertyPlaybackDuration: Double(CMTimeGetSeconds(episode.getDurationinCMTime())),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(CMTimeGetSeconds(SingletonClass.sharedInstance.player.currentTime())),
            MPNowPlayingInfoPropertyPlaybackRate: SingletonClass.sharedInstance.player.rate]
    }
    
    
    
    func moveplayer(_ seconds:Double){
        let secondsToAdd = CMTimeMakeWithSeconds(seconds,preferredTimescale: 1)
            let jumpToTime = CMTimeAdd(SingletonClass.sharedInstance.player.currentTime(), secondsToAdd)
            
            SingletonClass.sharedInstance.player.seek(to: jumpToTime)
            updatePlayPosition()
           
    }
    
    func updatePlayPosition(){
        let played = SingletonClass.sharedInstance.player.currentTime()
        let episode = SingletonClass.sharedInstance.episodePlaying
        episode.saveplayed(Double(CMTimeGetSeconds(played)))
        NSLog("played: \(Double(CMTimeGetSeconds(played)))")
    }

    
    
    
    
}
