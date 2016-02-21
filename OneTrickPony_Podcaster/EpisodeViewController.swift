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
       showsleeptimer()
 
        
        
    }
    

    

    
    @IBAction func playpause(sender: UIButton){
        switchPlayPause()

    }
    
    @IBAction func pressspeedbutton(sender: UIButton){
        changespeed()
    }
    
    
    @IBAction func slidermoving(sender:UISlider){
        stoptimer()
    }
    
    @IBAction func sliderchange(sender:UISlider){
        print(progressSlider.value)
        if (episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle){
            SingletonClass.sharedInstance.player.seekToTime(SingletonClass.sharedInstance.episodePlaying.getprogressinCMTime(Double(progressSlider.value)))
           //     SingletonClass.sharedInstance.player.seekToTime(Double(progressSlider.value))
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
    

    
    
    /**************************************************************************
     
                    ALL THE BASIC VIEW FUNCTIONS FOLLOWING
                (loading and confuring the view controller)
     
     **************************************************************************/
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        disableswipeback()
        
        if (SingletonClass.sharedInstance.playerinitialized == false) {
            initplayer(episode)
        }
        
        //fill the view with content
        fillplayerView(self, episode: episode)
        enableOrDisableControllsIfNoInFocus()
        allowremotebuttons()
        
        
        
        // the following two lines would change the look of the thumb of the slider.
        //let sliderimage = UIImage(named:"halfbar")
        //progressSlider.setThumbImage(sliderimage, forState: .Normal)
        
        
        
        //load the url and let's decide if we stream or play locally
        url = loadNSURL(episode)
        
        

        
        
        if (SingletonClass.sharedInstance.playerinitialized == true) {
          //  updateplayprogress()
            if (SingletonClass.sharedInstance.player.rate == 0 && SingletonClass.sharedInstance.player.error == nil){
                // streaming soll nicht sofort losspielen um Daten zu sparen … warum ich das jetzt auf deutsch schreiben weiß ich nicht.
                if (existslocally(episode.episodeFilename).existlocal == true){
                    if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
                        
                        updateMPMediaPlayer()
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
    
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        //do som stuff from the popover
    }
    
    func disableswipeback(){
        if navigationController!.respondsToSelector(Selector("interactivePopGestureRecognizer")) {
            navigationController!.view.removeGestureRecognizer(navigationController!.interactivePopGestureRecognizer!)
        }
    }
    
    
    
    func enableOrDisableControllsIfNoInFocus(){
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle != episode.episodeTitle){
            forward30Button.enabled = false
            forward30Button.hidden = true
            back30Button.enabled = false
            back30Button.hidden = true
            playerRateButton.enabled = false
            playerRateButton.hidden = true
            sleeptimerButton.enabled = false
            sleeptimerButton.hidden = true
        }else{
            forward30Button.enabled = true
            forward30Button.hidden = false
            back30Button.enabled = true
            back30Button.hidden = false
            playerRateButton.enabled = true
            playerRateButton.hidden = false
            sleeptimerButton.enabled = true
            sleeptimerButton.hidden = false
        }
    }
    
    /**************************************************************************
     
                    ALL THE TIMER FUNCTIONS FOLLOWING
            (updating the view to show the correct progress)
     
     **************************************************************************/
    
    
    func starttimer(){
        SingletonClass.sharedInstance.audioTimer.invalidate()
        SingletonClass.sharedInstance.audioTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target:self, selector: "updateplayprogress",userInfo: nil,repeats: true)
    }
    
    func stoptimer(){
        SingletonClass.sharedInstance.audioTimer.invalidate()
    }
    
    

    
    
    
    
    /**************************************************************************
    
                        ALL THE SLEEP TIMER FUNCTIONS FOLLOWING
                    (showing and updating the sleep timer to pause audio)
    
    **************************************************************************/
    
    func showsleeptimer(){
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
    
    
    /**************************************************************************
     
                ALL THE CHAPTER MARK FUNCTIONS FOLLOWING
                (showing and chosing the chapter marks)
     
     **************************************************************************/
    
    
    
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
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    
    /**************************************************************************
     
                ALL THE FILE LOADING FUNCTIONS FOLLOWING
                (could be part of the basic player section)
     
     **************************************************************************/
    
    
    
    
    func loadNSURL(episode : Episode) -> NSURL{
        let locally = existslocally(episode.episodeFilename)
        if  locally.existlocal{
            url = NSURL(fileURLWithPath: locally.localURL)
        }else{
            url = NSURL(string: episode.episodeUrl)!
        }

        print("loadNSURL \(url)")
        return url
    }
    
    
    /**************************************************************************
     
                    ALL THE PLAYER FUNCTIONS FOLLOWING
                (Play, Pause, skip forward and backwards)
     
     **************************************************************************/
    
    func initplayer(episode: Episode){
        url = loadNSURL(episode)
        SingletonClass.sharedInstance.player = AVPlayer(URL: url)
            SingletonClass.sharedInstance.episodePlaying = episode
            SingletonClass.sharedInstance.playerinitialized = true
          
            SingletonClass.sharedInstance.setaudioSession()
        
    }
    
    
    func autoplay(){
        if SingletonClass.sharedInstance.player.rate == 0 && SingletonClass.sharedInstance.player.error == nil {
            play()
            
        }
    }
    
    
    func moveplayer(seconds:Double){
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
            let secondsToAdd = CMTimeMakeWithSeconds(seconds,1)
            let jumpToTime = CMTimeAdd(SingletonClass.sharedInstance.player.currentTime(), secondsToAdd)
            
            //maybe i have to check here if the jumpToTime is smaller 0 or bigger thant the complete duration
            SingletonClass.sharedInstance.player.seekToTime(jumpToTime)
        }
    }

    func playPausefromRemoteCenter(){
        if (SingletonClass.sharedInstance.player.rate != 0 && SingletonClass.sharedInstance.player.error == nil) {
            pause()
        }else{
            play()
        }
    }
    
    
    
   
    func switchPlayPause(){

       // enableOrDisableControllsIfNoInFocus()
        if SingletonClass.sharedInstance.player.rate != 0 {
            pause()
          
            if episode.episodeTitle != "" {
                if episode.episodeTitle != SingletonClass.sharedInstance.episodePlaying.episodeTitle{
                //replace the item loaded
                SingletonClass.sharedInstance.player.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: url))
                // I jump to corrent play position
                SingletonClass.sharedInstance.player.seekToTime(episode.readplayed())
                // switch the meta information
                SingletonClass.sharedInstance.episodePlaying = episode
                //and start playing
                play()
                }
            }
        }else{
            play()
        }

        
        
        
        
        /*
        //if the view contains the Episode which is currently playing, run first part of if
        if (episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle){
            
            // at this state the Episode shown on the screen is the same like the one currently loaded in the player
            if SingletonClass.sharedInstance.player.rate == 0 && SingletonClass.sharedInstance.player.error == nil {
                // if the episode is not playing and the player didn't create an error, we can start playing
                play()
            } else {
                // otherwise we assume the player is playing and we can pause
                pause()
            }
        } else {
            // here the episode playing is a different one than the one on the screen.
            pause()
            //so I replace the item loaded
            SingletonClass.sharedInstance.player.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: url))
                // I jump to corrent play position
                SingletonClass.sharedInstance.player.seekToTime(episode.readplayed())
                // switch the meta information
                SingletonClass.sharedInstance.episodePlaying = episode
                //and start playing
                play()
            
        }
*/
        setplaypausebutton()
    }
    
    

    
    func play(){
        starttimer()
        
        episode = SingletonClass.sharedInstance.episodePlaying
        var starttime = episode.readplayed()
        if starttime >= episode.getDurationinCMTime(){
            // the item has been played to the end,I'll reset the starttime to start playing from the beginning
            
            episode.saveplayed(0.0)
            starttime = episode.readplayed()
            
        }
        
        
       // let item = SingletonClass.sharedInstance.player.currentItem
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidFinishPlaying", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)

        SingletonClass.sharedInstance.player.seekToTime(starttime)
        SingletonClass.sharedInstance.player.play()
        playPause.setTitle("pause", forState: .Normal)
      //  SingletonClass.sharedInstance.episodePlaying = episode
        somethingplayscurrently = true
        updateMPMediaPlayer()
        
    }
    func pause(){
        stoptimer()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        SingletonClass.sharedInstance.episodePlaying.saveplayed(Double(CMTimeGetSeconds(SingletonClass.sharedInstance.player.currentTime())))
        SingletonClass.sharedInstance.player.pause()
        playPause.setTitle("play", forState: .Normal)
        somethingplayscurrently = false
        updateMPMediaPlayer()
        
        
    }
    
    
    func playerDidFinishPlaying(){
        let episode = SingletonClass.sharedInstance.episodePlaying
        print("Did finish Playing \(episode.episodeTitle)")
        episode.deleteEpisodeFromDocumentsFolder()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    func setplaypausebutton(){
        enableOrDisableControllsIfNoInFocus()
        playPause.setTitle("play", forState: .Normal)
        if (SingletonClass.sharedInstance.playerinitialized == true) {
            if (SingletonClass.sharedInstance.player.rate != 0 && SingletonClass.sharedInstance.player.error == nil) {
                if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
                    playPause.setTitle("pause", forState: .Normal)
                }
            }
        }
    }
    
    func changespeed(){
        
      
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
            let progress = Double(CMTimeGetSeconds(SingletonClass.sharedInstance.player.currentTime()))
            let episode = SingletonClass.sharedInstance.episodePlaying
            
            
            // save time to NSUserdefaults (Double) - saveplayed(episode: Episode, playtime: Double)
            episode.saveplayed(progress)
            
            
            EpisodesTableViewController().updateCellForEpisode(episode)
            
            updateSliderProgress(progress)
            updateMPMediaPlayer()
            
            updateSleepTimer()
            checksleeptimer()
            
            
        }
    }
    
    

    
    func back30(){
        moveplayer(-30)
    }
    func forward30(){
        moveplayer(30)
    }
    
    
    func updateSliderProgress(progress: Double){
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
                fillplayerView(self, episode: episode)
            }
    }

    
    
    /**************************************************************************
     
                    ALL THE REMOTE PLAYER FUNCTIONS FOLLOWING
                    (Controllcenter and Lockscreen player)
     
     **************************************************************************/

    
    func allowremotebuttons(){
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        
        commandCenter.togglePlayPauseCommand.enabled = true
        commandCenter.playCommand.enabled = true
        commandCenter.pauseCommand.enabled = true
        
        commandCenter.skipBackwardCommand.addTarget(self, action: "back30")
        commandCenter.skipForwardCommand.addTarget(self, action: "forward30")
        
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        
        
        commandCenter.playCommand.addTarget(self, action: "playPausefromRemoteCenter")
        commandCenter.pauseCommand.addTarget(self, action: "playPausefromRemoteCenter")
        commandCenter.togglePlayPauseCommand.addTarget(self, action: "playPausefromRemoteCenter")
        
        
  
        
        
    }
    
    func updateMPMediaPlayer(){
        
        let playcenter = MPNowPlayingInfoCenter.defaultCenter()
            let mediaArtwort = MPMediaItemArtwork(image: getEpisodeImage(episode))
        playcenter.nowPlayingInfo = [
            MPMediaItemPropertyArtwork: mediaArtwort,
            
            MPMediaItemPropertyTitle : episode.episodeTitle,
            MPMediaItemPropertyPlaybackDuration: Double(CMTimeGetSeconds(episode.getDurationinCMTime())),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(CMTimeGetSeconds(SingletonClass.sharedInstance.player.currentTime())),
            MPNowPlayingInfoPropertyPlaybackRate: SingletonClass.sharedInstance.player.rate]
    }
    
    
    /**************************************************************************
     
                    ALL THE SHARE SHEET FUNCTIONS FOLLOWING
                (allowing to share the episode with friends)
     
     **************************************************************************/
    

    
    func displayShareSheet() {
        let shareContent:String = "I'm listening to \(episode.episodeTitle) - \(episode.episodeLink)"
        print(shareContent)
        let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: {})
    }

    
}



