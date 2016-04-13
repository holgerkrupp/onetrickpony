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


class EpisodeViewController: UIViewController, UIPopoverPresentationControllerDelegate, ChapterMarksViewControllerDelegate {

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
    @IBOutlet var playButton:UIButton!
    @IBOutlet var pauseButton:UIButton!
    @IBOutlet var episodeImage:UIImageView!
    @IBOutlet var episodeShowNotesWebView: UIWebView!
    @IBOutlet var infoButton:UIButton!
    
    @IBOutlet weak var playedtime: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    @IBOutlet weak var forward30Button: UIButton!
    @IBOutlet weak var back30Button: UIButton!
    @IBOutlet weak var playerRateButton: UIButton!

    @IBOutlet weak var subView: UIView!

    
    @IBOutlet weak var sleeptimerBarButton: UIBarButtonItem!
    @IBOutlet weak var chapterBarButton: UIBarButtonItem!
    @IBOutlet weak var shareBarButton: UIBarButtonItem!

    
    
    @IBAction func sharebuttonpressed(sender: UIBarButtonItem){
        displayShareSheet()
    }
    
    @IBOutlet weak var listButton: UIButton!
    @IBAction func listButtonpressed(sender: UIButton){
        back()
    }
    
    func back(){
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    @IBAction func SleepTimerButtonPressed(sender: UIBarButtonItem) {
       showsleeptimer()
    }
    
    @IBAction func infoButtonPressed(sender: UIButton){
        if episodeShowNotesWebView.hidden == true {
            episodeShowNotesWebView.hidden = false
            infoButton.selected = true
        }else{
            episodeShowNotesWebView.hidden = true
            infoButton.selected = false
        }
    }

    @IBAction func tapImage(recognizer:UITapGestureRecognizer) {
    
        if episodeShowNotesWebView.hidden == true {
            episodeShowNotesWebView.hidden = false
        }else{
            episodeShowNotesWebView.hidden = true
        }
    }

    
    @IBAction func playButtonPressed(sender: UIButton){
        switchPlayPause()

    }
    @IBAction func pauseButtonPressed(sender: UIButton){
        pause()
        
    }
    
    @IBAction func pressspeedbutton(sender: UIButton){
        changespeed()
    }
    
    
    @IBAction func slidermoving(sender:UISlider){
        stoptimer()
    }
    
    @IBAction func sliderchange(sender:UISlider){
      //  NSLog(progressSlider.value)
        if (episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle){
            SingletonClass.sharedInstance.player.seekToTime(SingletonClass.sharedInstance.episodePlaying.getprogressinCMTime(Double(progressSlider.value)))

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
    //    disableswipeback()

        
        //fill the view with content
        fillPlayerView(episode)
        adjustColors()
        episodeShowNotesWebView.hidden = true
        
        enableOrDisableControllsIfNoInFocus()
        allowremotebuttons()
        if existsLocally(episode.episodeUrl).existlocal{
            autoplay()
        }
        setplaypausebutton()
        
    }
    
    
    func fillPlayerView(episode: Episode){
        
            // Text
           titleLabel.text = episode.episodeTitle
           titleLabel.textColor = getColorFromPodcastSettings("textcolor")
            
            
            // Time & Slider
            
            let starttime = episode.readplayed
            let duration = stringtodouble(episode.getDurationFromEpisode())
            
           progressSlider.maximumValue = Float(duration)
            let currentplaytime = Float(CMTimeGetSeconds(starttime()))
            
           progressSlider.setValue(currentplaytime, animated: false)
            // progressSlider.backgroundColor = getColorFromPodcastSettings("progressBackgroundColor")
           progressSlider.minimumTrackTintColor = getColorFromPodcastSettings("highlightColor")
           progressSlider.maximumTrackTintColor = getColorFromPodcastSettings("progressBackgroundColor")
           progressSlider.setMaximumTrackImage(getImageWithColor(getColorFromPodcastSettings("progressBackgroundColor"),size: CGSizeMake(2, 10)), forState: .Normal)
           progressSlider.setMinimumTrackImage(getImageWithColor(getColorFromPodcastSettings("highlightColor"),size: CGSizeMake(2, 10)), forState: .Normal)
           progressSlider.setThumbImage(getImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSizeMake(2, 30)), forState: .Normal)
            
            
           playedtime.text = secondsToHoursMinutesSeconds(CMTimeGetSeconds(starttime()))
           playedtime.textColor = getColorFromPodcastSettings("secondarytextcolor")
            
           remainingTimeLabel.text = secondsToHoursMinutesSeconds(CMTimeGetSeconds(episode.remaining()))
           remainingTimeLabel.textColor = getColorFromPodcastSettings("secondarytextcolor")
            
            let description = episode.episodeDescription.stringByReplacingOccurrencesOfString("\n", withString: "</br>")
            
           episodeShowNotesWebView.loadHTMLString(description, baseURL: nil)
            
           episodeImage.image = getEpisodeImage(episode)
            // rate Button
            if (SingletonClass.sharedInstance.playerinitialized == true) {
                let currentspeed = SingletonClass.sharedInstance.player.rate
                if currentspeed != 0 {
                    let indexofspeed:Int = speeds.indexOf(currentspeed)!
                   playerRateButton.setTitle(speedtext[indexofspeed], forState: .Normal)
                }
            }
           playerRateButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
           forward30Button.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
           back30Button.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
           playButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
           pauseButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
            
            
            
           forward30Button.setImage(createSkipWithColor(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSizeMake(30, 30), filled: true, forward: true, label: "30"), forState: .Normal)
           forward30Button.setTitle(nil, forState: .Normal)
            
           back30Button.setImage(createSkipWithColor(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSizeMake(30, 30), filled: true, forward: false, label: "30"), forState: .Normal)
           back30Button.setTitle(nil, forState: .Normal)
            
            
            
        
    }
    
    
    func adjustColors(){
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.toolbarHidden = false
        

        

        playButton.tintColor = getColorFromPodcastSettings("playControlColor")
        pauseButton.tintColor = getColorFromPodcastSettings("playControlColor")
        back30Button.tintColor = getColorFromPodcastSettings("playControlColor")
        forward30Button.tintColor = getColorFromPodcastSettings("playControlColor")

        self.navigationController?.toolbar.barTintColor = getColorFromPodcastSettings("backgroundColor")
        self.navigationController?.toolbar.translucent = false
        self.navigationController?.toolbar.clipsToBounds = true
        
        
        self.view.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        subView.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        sleeptimerBarButton.tintColor = getColorFromPodcastSettings("playControlColor")
        shareBarButton.tintColor = getColorFromPodcastSettings("playControlColor")
        chapterBarButton.tintColor = getColorFromPodcastSettings("playControlColor")
        infoButton.tintColor = getColorFromPodcastSettings("playControlColor")
        
        if episode.episodeChapter.count == 0
        {
            chapterBarButton.enabled = false
            chapterBarButton.tintColor = getColorFromPodcastSettings("backgroundColor")
            
        }
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        if SingletonClass.sharedInstance.player.rate != 0 {
            starttimer()
        }
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        fixTheDuration()
        updateplayprogress()
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
        if episode.episodeTitle == ""{
            episode = SingletonClass.sharedInstance.episodePlaying
        }
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle != episode.episodeTitle){
            forward30Button.enabled = false
            forward30Button.hidden = true
            back30Button.enabled = false
            back30Button.hidden = true
            playerRateButton.enabled = false
            playerRateButton.hidden = true
        }else{
            forward30Button.enabled = true
            forward30Button.hidden = false
            back30Button.enabled = true
            back30Button.hidden = false
            playerRateButton.enabled = true
            playerRateButton.hidden = false
        }
    }
    
    /**************************************************************************
     
                    ALL THE TIMER FUNCTIONS FOLLOWING
            (updating the view to show the correct progress)
     
     **************************************************************************/
    
    
    func starttimer(){
        SingletonClass.sharedInstance.audioTimer.invalidate()
        SingletonClass.sharedInstance.audioTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target:self, selector: #selector(EpisodeViewController.updateplayprogress),userInfo: nil,repeats: true)
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
        
        
        
        let alert = UIAlertController(title: NSLocalizedString("sleep.timer.title", value: "Sleep timer", comment: "shown in Episode Player"), message: NSLocalizedString("The sleep timer will automatically pause the episode after the selcted time", comment: "shown in Episode Player"), preferredStyle: .ActionSheet)
        
        let disableAction = UIAlertAction(title: NSLocalizedString("sleep.timer.deactivate", value: "Disable", comment: "shown in Episode Player"), style: .Default) { (alert: UIAlertAction!) -> Void in
            self.cancelleeptimer()
        }
        
        let firstAction = UIAlertAction(title: NSLocalizedString("sleep.timer.30", value: "30 Minutes", comment: "shown in Episode Player"), style: .Default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(30)
        }
        
        let secondAction = UIAlertAction(title: NSLocalizedString("sleep.timer.15", value: "15 Minutes", comment: "shown in Episode Player"), style: .Default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(15)
        }
        
        
        let thirdAction = UIAlertAction(title: NSLocalizedString("sleep.timer.5", value: "5 Minutes", comment: "shown in Episode Player"), style: .Default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(5)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("sleep.timer.cancel", value: "cancel", comment: "shown in Episode Player"), style: .Cancel) { (alert: UIAlertAction!) -> Void in
            
        }
        alert.addAction(disableAction)
        alert.addAction(firstAction)
        alert.addAction(secondAction)
        alert.addAction(thirdAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion:nil) // 6
    }
    

    func setsleeptimer(minutes: Double){
        let seconds = minutes * 60
        SingletonClass.sharedInstance.sleeptimer = seconds
        SingletonClass.sharedInstance.sleeptimerset = true
        NSLog("Sleeptimer set to \(minutes) that's \(seconds)")
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
        //    NSLog(SingletonClass.sharedInstance.sleeptimer)
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
        if segue.identifier == "showChapterMarks" {
            let vc = segue.destinationViewController as! ChapterMarksViewController
            vc.EpisodeViewController = self
            let controller = vc.popoverPresentationController
             vc.Chapters = episode.episodeChapter
            
            if controller  != nil{
                controller?.delegate = self
            }
        }
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    
    
    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {
        NSLog("should dismiss")
        return true
    }
    
    
    /**************************************************************************
     
                ALL THE FILE LOADING FUNCTIONS FOLLOWING
                (could be part of the basic player section)
     
     **************************************************************************/
    
    
    
    
    func loadNSURL(episode : Episode) -> NSURL{
        let locally = existsLocally(episode.episodeFilename)
        if  locally.existlocal{
            url = NSURL(fileURLWithPath: locally.localURL)
        }else{
            url = NSURL(string: episode.episodeUrl)!
        }
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
        fixTheDuration()
        updateMPMediaPlayer()

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
            updatePlayPosition()
            

        }
    }
    
    func jumpToTimeInPlayer(seconds:Double){
        let targetTime = CMTimeMakeWithSeconds(seconds,1)
        print("targettime \(targetTime)")
        SingletonClass.sharedInstance.player.seekToTime(targetTime)
        updatePlayPosition()
        
    }
    
    

    func playPausefromRemoteCenter(){
        if SingletonClass.sharedInstance.player.rate != 0{
            pause()
        }else{
            play()
        }
    }
    
    
    
   
    func switchPlayPause(){
        
        
        if SingletonClass.sharedInstance.playerinitialized == false {
            initplayer(episode)
            play()
        }else{
            if SingletonClass.sharedInstance.episodePlaying.episodeTitle != episode.episodeTitle {
                // a new episode is loaded
                let oldEpisode = SingletonClass.sharedInstance.episodePlaying
                SingletonClass.sharedInstance.episodePlaying = episode
                url = loadNSURL(episode)
                SingletonClass.sharedInstance.player.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: url))
                fixTheDuration()
                let starttime = episode.readplayed()
                SingletonClass.sharedInstance.player.seekToTime(starttime)

                play()
            }else{
                play()
            }
        }
        
        setplaypausebutton()
    }
    
    func fixTheDuration(){
        if episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle {
            let duration = SingletonClass.sharedInstance.player.currentItem?.asset.duration
            episode.setDuration(duration!)
            SingletonClass.sharedInstance.episodePlaying.setDuration(duration!)
        }
    }

    
    func play(){
        
        var starttime = episode.readplayed()
        if (SingletonClass.sharedInstance.playerinitialized == false) {
            initplayer(episode)
        }
        
        if starttime >= episode.getDurationinCMTime() && episode.getDurationInSeconds() != 0.0 {
            // the item has been played to the end,I'll reset the starttime to start playing from the beginning
            episode.saveplayed(0.0)
            NSLog("read after save \(episode.getDurationinCMTime())")
            starttime = episode.readplayed()
        }
        


        
        starttimer()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(EpisodeViewController.playerDidFinishPlaying), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)

        SingletonClass.sharedInstance.player.seekToTime(starttime)
        SingletonClass.sharedInstance.player.play()
        if let newindex = getObjectForKeyFromPersistentStorrage("player.rate"){
            NSLog("rateindex: \(newindex)")
            updateRate(newindex as! Int)
        }
        somethingplayscurrently = true
        setplaypausebutton()
        updateMPMediaPlayer()
    }

    
    func updatePlayPosition(){
        let played = SingletonClass.sharedInstance.player.currentTime()
        episode.saveplayed(Double(CMTimeGetSeconds(played)))
        NSLog("played: \(Double(CMTimeGetSeconds(played)))")
        updateplayprogress()
       
    }

    
    func pause(){
        stoptimer()
        SingletonClass.sharedInstance.player.pause()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        let played = SingletonClass.sharedInstance.player.currentTime()
        let episode = SingletonClass.sharedInstance.episodePlaying
        episode.saveplayed(Double(CMTimeGetSeconds(played)))
        NSLog("played: \(Double(CMTimeGetSeconds(played)))")
        somethingplayscurrently = false
        setplaypausebutton()
        updateMPMediaPlayer()
    }
    
    
    func playerDidFinishPlaying(){
        let episode = SingletonClass.sharedInstance.episodePlaying
        NSLog("Did finish Playing \(episode.episodeTitle)")
        episode.deleteEpisodeFromDocumentsFolder()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    func setplaypausebutton(){
        enableOrDisableControllsIfNoInFocus()
    
        playButton.setTitle(nil, forState: .Normal)
        playButton.setImage(createPlayImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSizeMake(30, 30), filled: true), forState: .Normal)
        
        
        
        pauseButton.hidden = true
        playButton.hidden = false
        if (SingletonClass.sharedInstance.playerinitialized == true) {
            if (SingletonClass.sharedInstance.player.rate != 0 && SingletonClass.sharedInstance.player.error == nil) {
                if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
                    pauseButton.setTitle(nil, forState: .Normal)
                    pauseButton.setImage(createPauseImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSizeMake(30,30), filled: true), forState: .Normal)
                    playButton.hidden = true
                    pauseButton.hidden = false
                }
            }
        }
    }
    
    func changespeed(){
        
      
        let currentspeed = SingletonClass.sharedInstance.player.rate
        if currentspeed != 0 { // stupid quick fix to avoid a crash when the player is paused
            let indexofspeed:Int = speeds.indexOf(currentspeed)!
            var newindex:Int
            if (indexofspeed+1 < speeds.count){
                newindex = indexofspeed+1
            }else{
                newindex = 0
            }
            updateRate(newindex)
            /*
            SingletonClass.sharedInstance.player.rate = speeds[newindex]
            playerRateButton.setTitle(speedtext[newindex], forState: .Normal)
            playerRateButton.tintColor = getColorFromPodcastSettings("playControlColor")

            setObjectForKeyToPersistentStorrage("player.rate", object: newindex)
             */
        }
    }
    
    func updateRate(rateindex: Int){
        
        playerRateButton.setTitle(speedtext[rateindex], forState: .Normal)
        playerRateButton.tintColor = getColorFromPodcastSettings("playControlColor")
        setObjectForKeyToPersistentStorrage("player.rate", object: rateindex)
        SingletonClass.sharedInstance.player.rate = speeds[rateindex]
    }
    
    func updateplayprogress(){
        if (SingletonClass.sharedInstance.playerinitialized == true){
            // get time from player (Double)
            let progress = Double(CMTimeGetSeconds(SingletonClass.sharedInstance.player.currentTime()))
            let episode = SingletonClass.sharedInstance.episodePlaying
            
        
            episode.saveplayed(progress)
            
            
            
            updateSliderProgress(progress)
            updateMPMediaPlayer()
            setplaypausebutton()
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
                fillPlayerView(episode)
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
        
        commandCenter.skipBackwardCommand.addTarget(self, action: #selector(EpisodeViewController.back30))
        commandCenter.skipForwardCommand.addTarget(self, action: #selector(EpisodeViewController.forward30))
        
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        
        
        commandCenter.playCommand.addTarget(self, action: #selector(EpisodeViewController.playPausefromRemoteCenter))
        commandCenter.pauseCommand.addTarget(self, action: #selector(EpisodeViewController.playPausefromRemoteCenter))
        commandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(EpisodeViewController.playPausefromRemoteCenter))
       
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
        
        let shareContent:String = String.localizedStringWithFormat(NSLocalizedString("share.sheet", value:"I'm listening to %@ - %@",comment: "used for tweets and stuff"), episode.episodeTitle, episode.episodeLink)
        
     //   let shareContent:String = "I'm listening to \(episode.episodeTitle) - \(episode.episodeLink)"
        NSLog(shareContent)
        let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: {})
    }

    
}



