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
    
    
    var player:AVAudioPlayer        = AVAudioPlayer()
    var avaudioplayerplaying:Bool   = false
    
    var streamer:AVPlayer           = AVPlayer()
    var streamerplaying:Bool        = false
    
    var playerinitialized: Bool     = false
    var episodePlaying:Episode      = Episode()
    var audioTimer:NSTimer          = NSTimer()
    
    var sleeptimerset:Bool          = false
    var sleeptimer:Double           = 0.0
    
    class var sharedInstance: SingletonClass {
        struct Singleton {
            static let instance = SingletonClass()
        }
        
        return Singleton.instance
    }
    
    func setaudioSession (){
        
   
    let audioSession = AVAudioSession.sharedInstance()
        
    try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
  
        do
        {
            try audioSession.setActive(false)
        }
        catch let error as NSError
        {
            print(error.description)
        }
    }
}