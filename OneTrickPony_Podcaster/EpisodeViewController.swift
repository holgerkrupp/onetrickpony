//
//  EpisodeViewController.swift
//  OneTrickPony_Podcaster
//
//  Created by Holger Krupp on 24/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer



class EpisodeViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    var episode = Episode()

    var local = false
    var somethingplayscurrently = false
    var thisisplaying = false
    
    var url:NSURL = NSURL()
    
    var updater : CADisplayLink! = nil
    
    let speeds: [Float] = [0.5,1,1.5,2]
    let speedtext: [String] = ["1/2x","1x","1,5x","2x"]
    
    
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var progressSlider: UISlider!
    @IBOutlet var playPause:UIButton!
    @IBOutlet var episodeImage:UIImageView!
    
    @IBOutlet weak var playedtime: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    @IBOutlet weak var forward30Button: UIButton!
    @IBOutlet weak var back30Button: UIButton!
    
    @IBOutlet weak var sleeptimerButton: UIButton!
    @IBOutlet weak var chapterButton: UIButton!
    @IBOutlet weak var playerRateButton: UIButton!
    
    @IBOutlet weak var shareButton: UIButton!
    @IBAction func sharebuttonpressed(sender: UIButton){
        displayShareSheet()
    }
    
    @IBOutlet weak var listButton: UIButton!
    @IBAction func listButtonpressed(sender: UIButton){
        back()
    }
    
    func back(){
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    @IBAction func SleepTimerButtonPressed(sender: AnyObject) {
       // self.performSegueWithIdentifier("SleepTimerSegue", sender: self)
        
        let alert = UIAlertController(title: "Sleeptimer", message: "The sleep timer will automatically pause the episode after the selcted time", preferredStyle: .ActionSheet)
        
        let disableAction = UIAlertAction(title: "Disable", style: .Default) { (alert: UIAlertAction!) -> Void in
            self.cancelleeptimer()
        }
        
        let firstAction = UIAlertAction(title: "30 Minutes", style: .Default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(30)
        }
        
        let secondAction = UIAlertAction(title: "15 Minutes", style: .Default) { (alert: UIAlertAction!) -> Void in
           self.setsleeptimer(15)
        }
        
        
        let debugAction = UIAlertAction(title: "DEBUG: 0.2 Minutes", style: .Default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(0.2)
        }
        
        let cancelAction = UIAlertAction(title: "cancel", style: .Cancel) { (alert: UIAlertAction!) -> Void in
            
        }
        alert.addAction(disableAction)
        alert.addAction(firstAction)
        alert.addAction(secondAction)
        alert.addAction(debugAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion:nil) // 6
 
        
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //segue for the popover configuration window
        if segue.identifier == "SleepTimerSegue" {
          let vc = segue.destinationViewController 
            let controller = vc.popoverPresentationController
            
            if controller  != nil{
                controller?.delegate = self
            }
            }
        }
    
    
    
    
    
    
    
    
    
    
    @IBAction func playpause(sender: UIButton){
        
        if (episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle){
            if SingletonClass.sharedInstance.player.playing == false {
                play()
            } else {
                pause()
            }
        } else {

            pause()

            do{
                try SingletonClass.sharedInstance.player = AVAudioPlayer(contentsOfURL: url)

                SingletonClass.sharedInstance.player.currentTime = readplayed(episode)

                SingletonClass.sharedInstance.episodePlaying = episode

                play()
            }catch{
                print("error")
            }
        }
        setplaypausebutton()
    }
    
    @IBAction func pressspeedbutton(sender: UIButton){
        changespeed()
    }
    
    
    @IBAction func slidermoving(sender:UISlider){
        stoptimer()
    }
    
    @IBAction func sliderchange(sender:UISlider){
        if (episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle){
            
            SingletonClass.sharedInstance.player.currentTime = Double(progressSlider.value)
        }
    }
    
    @IBAction func restarttimer(sender:UISlider){
        starttimer()
    }
    
    @IBAction func plus30(sender:UIButton){
        moveplayer(30)
    }
    
    @IBAction func minus30(sender:UIButton){
        moveplayer(-30)
    }
    
    func moveplayer(seconds:Double){
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
        SingletonClass.sharedInstance.player.currentTime = SingletonClass.sharedInstance.player.currentTime + seconds
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disableswipeback()
        //fill the view with content
        fillplayerView(self, episode: episode)
        
        //load the url and let's decide if we stream or play locally
        url = loadNSURL(episode)
        
        
        if (SingletonClass.sharedInstance.playerinitialized == false) {
            initplayer(episode)
        }
        
        //first if statement can be deleted if streaming is integrated later - probably.
        if (SingletonClass.sharedInstance.playerinitialized == true) {
          //  updateplayprogress()
            if (SingletonClass.sharedInstance.player.playing == false){
                // streaming soll nicht sofort losspielen um Daten zu sparen … warum ich das jetzt auf deutsch schreiben weiß ich nicht.
                if (local == true){
                    if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
                        allowremotebuttons()
                        
                        autoplay()
                        starttimer()
                    }
                }
            }
        }
        setplaypausebutton()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        fillplayerView(self, episode: episode)
        starttimer()
        updateplayprogress()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        self.navigationController?.navigationBarHidden = false
    }
    
    func starttimer(){
        SingletonClass.sharedInstance.audioTimer.invalidate()
        SingletonClass.sharedInstance.audioTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target:self, selector: "updateplayprogress",userInfo: nil,repeats: true)
    }
    
    func stoptimer(){
        SingletonClass.sharedInstance.audioTimer.invalidate()
    }
    
    
    

    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        //do som stuff from the popover
    }
    
    
    func setsleeptimer(minutes: Double){
        let seconds = minutes * 60
        SingletonClass.sharedInstance.sleeptimer = seconds
        SingletonClass.sharedInstance.sleeptimerset = true
        print("Sleeptimer set to \(minutes) that's \(seconds)")
    }
    
    func cancelleeptimer(){
        SingletonClass.sharedInstance.sleeptimerset = false
    }
    
    func checksleeptimer(){
        if (SingletonClass.sharedInstance.sleeptimerset == true){
            if (SingletonClass.sharedInstance.sleeptimer <= 0.0){
                pause()
                cancelleeptimer()
            }
            print(SingletonClass.sharedInstance.sleeptimer)
        }
        
    }
    
    func updateSleepTimer(){
        // if a Sleeptimer is set, reduce the time of the sleeptimer by the Interval of the playtimer
        if (SingletonClass.sharedInstance.sleeptimerset == true){
            SingletonClass.sharedInstance.sleeptimer -= SingletonClass.sharedInstance.audioTimer.timeInterval
        }
    }
    
    
    
    func loadNSURL(episode : Episode) -> NSURL{
        //
        let manager = NSFileManager.defaultManager()
        let documentsDirectoryUrl = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let fileName = episode.episodeFilename
        print("doc directory \(documentsDirectoryUrl)")
        let localFeedFile = documentsDirectoryUrl + "/" + fileName
        print(episode.episodeFilename)
        if  manager.fileExistsAtPath(localFeedFile){
            url = NSURL(fileURLWithPath: localFeedFile)
            
            local = true
        }else{
            url = NSURL(string: episode.episodeUrl)!
            local = false
        }

        print("loadNSURL \(url)")
        return url
    }
    
    func autoplay(){
        if SingletonClass.sharedInstance.player.playing == false {
            play()
            
        }
    }
    
    
    
    func setplaypausebutton(){
        playPause.setTitle("play", forState: .Normal)
        if (SingletonClass.sharedInstance.playerinitialized == true) {
            if (SingletonClass.sharedInstance.player.playing == true) {
                if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
                    playPause.setTitle("pause", forState: .Normal)
                }
            }
        }
    }
    
    
    
    
    func initplayer(episode: Episode){
        url = loadNSURL(episode)
        do{
            try SingletonClass.sharedInstance.player = AVAudioPlayer(contentsOfURL: url)
            SingletonClass.sharedInstance.episodePlaying = episode
            SingletonClass.sharedInstance.playerinitialized = true
            SingletonClass.sharedInstance.player.enableRate = true
            SingletonClass.sharedInstance.setaudioSession()
            
        }catch{
            print("error in initplayer")
        }
    }
    
    func changespeed(){
        
        SingletonClass.sharedInstance.player.enableRate = true
        let currentspeed = SingletonClass.sharedInstance.player.rate
        let indexofspeed:Int = speeds.indexOf(currentspeed)!
        var newindex:Int
        if (indexofspeed+1 < speeds.count){
            newindex = indexofspeed+1
        }else{
            newindex = 0
        }
        SingletonClass.sharedInstance.player.rate = speeds[newindex]
        playerRateButton.setTitle(speedtext[newindex], forState: .Normal)
    }
    
    
    func updateplayprogress(){
        if (SingletonClass.sharedInstance.playerinitialized == true){
            // get time from player (Double)
            let progress = Double(SingletonClass.sharedInstance.player.currentTime)
            // save time to NSUserdefaults (Double) - saveplayed(episode: Episode, playtime: Double)
            saveplayed(SingletonClass.sharedInstance.episodePlaying, playtime: progress)
            
            // update slider & time labels if in focus (Double)
            updateSliderProgress(progress)
            updateSleepTimer()
            checksleeptimer()
            
            
        }
    }
    
    

    
    
    func updateSliderProgress(progress: Double){
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
                fillplayerView(self, episode: episode)
            }
        


    }

    
    func play(){
        starttimer()
        let starttime = readplayed(episode)
        
        SingletonClass.sharedInstance.player.currentTime = starttime
        SingletonClass.sharedInstance.player.play()
        playPause.setTitle("pause", forState: .Normal)
        SingletonClass.sharedInstance.episodePlaying = episode
        somethingplayscurrently = true
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
        
        
    }
    func pause(){
        stoptimer()
        saveplayed(SingletonClass.sharedInstance.episodePlaying, playtime: SingletonClass.sharedInstance.player.currentTime)
        SingletonClass.sharedInstance.player.pause()
        playPause.setTitle("play", forState: .Normal)
        somethingplayscurrently = false
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
        
    }
    
    func allowremotebuttons(){
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        commandCenter.nextTrackCommand.enabled = true
        commandCenter.playCommand.addTarget(self, action: "play")
        commandCenter.pauseCommand.addTarget(self, action: "pause")
        
        let playcenter = MPNowPlayingInfoCenter.defaultCenter()
        playcenter.nowPlayingInfo = [
            MPMediaItemPropertyArtist : "Artist!",
            MPMediaItemPropertyTitle : episode.episodeTitle,
            MPMediaItemPropertyPlaybackDuration: SingletonClass.sharedInstance.player.duration,
            MPNowPlayingInfoPropertyPlaybackRate: SingletonClass.sharedInstance.player.rate]
        
        
    }
    
    func disableswipeback(){
        if navigationController!.respondsToSelector(Selector("interactivePopGestureRecognizer")) {
            navigationController!.view.removeGestureRecognizer(navigationController!.interactivePopGestureRecognizer!)
        }
    }
    
    func displayShareSheet() {
        let shareContent:String = "Ich höre gerade \(episode.episodeTitle) - \(episode.episodeLink)"
        print(shareContent)
        let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: {})
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
}



