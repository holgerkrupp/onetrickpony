//
//  AVPlayer_Singleton.swift
//  OneTrickPony_Podcaster
//
//  Created by Holger Krupp on 30/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation
import AVFoundation

class SingletonClass {
    
    
    var player:AVPlayer        = AVPlayer()
    var AVPlayerplaying:Bool   = false
    
    var playerinitialized: Bool     = false
    var episodePlaying:Episode      = Episode()
    var audioTimer:Timer          = Timer()
    
    var sleeptimerset:Bool          = false
    var sleeptimer:Double           = 0.0
    
    var firstload:Bool              = true
    var numberofepisodes:Int        = Int()
    
    class var sharedInstance: SingletonClass {
        struct Singleton {
            static let instance = SingletonClass()
        }
        
        return Singleton.instance
    }
    
    func setaudioSession (){
        
   
    let audioSession = AVAudioSession.sharedInstance()
        
        do
        {
        try audioSession.setCategory(AVAudioSession.Category(rawValue: "playback"))
        }
        catch let error as NSError{
             NSLog(error.description)
        }
  
        do
        {
            try audioSession.setActive(false)
        }
        catch let error as NSError
        {
            NSLog(error.description)
        }
    if #available(iOS 9.0, *) {
        do
        {
        try audioSession.setMode(convertToAVAudioSessionMode("spokenAudio"))
        }
        catch let error as NSError{
             NSLog(error.description)
        }
    } else {
        // Fallback on earlier versions
    }
        
        do
        {
            try audioSession.setActive(false)
        }
        catch let error as NSError
        {
            NSLog(error.description)
        }
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToAVAudioSessionMode(_ input: String) -> AVAudioSession.Mode {
	return AVAudioSession.Mode(rawValue: input)
}
