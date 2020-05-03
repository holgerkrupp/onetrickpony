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
import SafariServices
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}



class EpisodeViewController: UIViewController, UIPopoverPresentationControllerDelegate, UIWebViewDelegate, SFSafariViewControllerDelegate, ChapterMarksViewControllerDelegate {
    
    var episode = Episode()
    
    var local = false
    var somethingplayscurrently = false
    var thisisplaying = false
    
    //var url:URL = URL()
    
    var updater : CADisplayLink! = nil
    
    let speeds: [Float] = [0.5,1,1.5,2]
    let speedtext: [String] = ["1/2x","1x","1,5x","2x"]
    
    var DynamicView = UIView()
    
    
    
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var chapterTitleLabel:UILabel!
    @IBOutlet var progressSlider: UISlider!
    @IBOutlet var playButton:UIButton!
    @IBOutlet var pauseButton:UIButton!
    @IBOutlet var episodeImage:UIImageView!
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
    
    
    @IBOutlet weak var ShowNotesContainer: UIView!
    @IBOutlet weak var ShowNotesDismissButton: UIButton!
    @IBOutlet var episodeShowNotesWebView: UIWebView!

    @IBAction func ShowNotesDismissButtonPressed(_ sender: UIButton) {
        
        if ShowNotesContainer.isHidden == true {
            ShowNotesContainer.isHidden = false
            infoButton.isSelected = true

        }else{
            ShowNotesContainer.isHidden = true
            infoButton.isSelected = false

        }
    }
    
    
    
    
    
    
    @IBAction func sharebuttonpressed(_ sender: UIBarButtonItem){
        displayShareSheet()
    }
    
    @IBOutlet weak var listButton: UIButton!
    @IBAction func listButtonpressed(_ sender: UIButton){
        back()
    }
    
    func back(){
        _ = navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func SleepTimerButtonPressed(_ sender: UIBarButtonItem) {
        showsleeptimer()
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton){
        let url = URL(string: episode.episodeLink)
        openWithSafariVC(url!)
        
        /*if ShowNotesContainer.hidden == true {
            ShowNotesContainer.hidden = false
            infoButton.selected = true
        }else{
            ShowNotesContainer.hidden = true
            infoButton.selected = false
        }*/
    }
    
    @IBAction func tapImage(_ recognizer:UITapGestureRecognizer) {
        
        if ShowNotesContainer.isHidden == true {
            ShowNotesContainer.isHidden = false
        }else{
            ShowNotesContainer.isHidden = true
        }
    }
    
    
    @IBAction func playButtonPressed(_ sender: UIButton){
        switchPlayPause()
        
    }
    @IBAction func pauseButtonPressed(_ sender: UIButton){
        pause()
        
    }
    
    @IBAction func pressspeedbutton(_ sender: UIButton){
        changespeed()
    }
    
    
    @IBAction func slidermoving(_ sender:UISlider){
        stoptimer()
    }
    
    @IBAction func sliderchange(_ sender:UISlider){
        //  NSLog(progressSlider.value)
        if (episode.episodeTitle == SingletonClass.sharedInstance.episodePlaying.episodeTitle){
            SingletonClass.sharedInstance.player.seek(to: SingletonClass.sharedInstance.episodePlaying.getprogressinCMTime(Double(progressSlider.value)))
            
        }
    }
    
    @IBAction func restarttimer(_ sender:UISlider){
        starttimer()
    }
    
    @IBAction func plus30(_ sender:UIButton){
        moveplayer(30)
    }
    
    @IBAction func minus30(_ sender:UIButton){
        moveplayer(-30)
    }
    
    
    
    
    /**************************************************************************
     
     ALL THE BASIC VIEW FUNCTIONS FOLLOWING
     (loading and the view controller)
     
     **************************************************************************/
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        //    disableswipeback()
        
        fillPlayerView(episode)
        adjustColors()
        episodeShowNotesWebView.isHidden = false
        ShowNotesContainer.isHidden = true
    ShowNotesDismissButton.setImage(createCircleWithCross(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSize(width: 30, height: 30), filled: false), for: UIControl.State())
        
        enableOrDisableControllsIfNoInFocus()
        allowremotebuttons()
        /*
        if (SingletonClass.sharedInstance.playerinitialized == false){
            initplayer(episode)
        }
        */
        
        if existsLocally(episode.episodeUrl).existlocal && (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle) {
            autoplay()
        }
        setplaypausebutton()
        
    }
    
    
    func updateProgress(_ episode: Episode){
        let starttime = episode.readplayed
        let duration = stringtodouble(episode.getDurationFromEpisode())
        
        progressSlider.maximumValue = Float(duration)
        let currentplaytime = Float(CMTimeGetSeconds(starttime()))
        
        
        progressSlider.setValue(currentplaytime, animated: false)
        
        
        playedtime.text = secondsToHoursMinutesSeconds(CMTimeGetSeconds(starttime()))
        playedtime.textColor = getColorFromPodcastSettings("textcolor")
        
        remainingTimeLabel.text = secondsToHoursMinutesSeconds(CMTimeGetSeconds(episode.remaining()))
        remainingTimeLabel.textColor = getColorFromPodcastSettings("textcolor")
        
        if let chapter = episode.getChapterForSeconds(Double(currentplaytime)){
            chapterTitleLabel.text = chapter.chapterTitle
            chapterTitleLabel.textColor = getColorFromPodcastSettings("secondarytextcolor")
            chapterTitleLabel.isEnabled = true
            chapterTitleLabel.isHidden = false
        }else{
            chapterTitleLabel.isHidden = true
        }
    }
    
    func fillPlayerView(_ episode: Episode){
        
        // Text
        titleLabel.text = episode.episodeTitle
        titleLabel.textColor = getColorFromPodcastSettings("textcolor")
        self.title = episode.episodeTitle
        
        
        
        
        // Time & Slider
        
        updateProgress(episode)
        
        progressSlider.minimumTrackTintColor = getColorFromPodcastSettings("highlightColor")
        progressSlider.maximumTrackTintColor = getColorFromPodcastSettings("progressBackgroundColor")
        let bigprogressbar = getObjectForKeyFromPodcastSettings("bigprogressbar") as! Bool
        var progressslidersize: CGFloat
        if bigprogressbar == true {
            progressslidersize = 30
        }else{
            progressslidersize = 5
        }
        
        progressSlider.setMaximumTrackImage(getImageWithColor(getColorFromPodcastSettings("progressBackgroundColor"),size: CGSize(width: 2, height: progressslidersize)), for: UIControl.State())
        progressSlider.setMinimumTrackImage(getImageWithColor(getColorFromPodcastSettings("highlightColor"),size: CGSize(width: 2, height: progressslidersize)), for: UIControl.State())
        progressSlider.setThumbImage(getImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSize(width: 2, height: 40)), for: UIControl.State())
        
        var description = episode.episodeDescription //.stringByReplacingOccurrencesOfString("\n", withString: "</br>")
        
        
        
        let urlpath = Bundle.main.bundleURL
        let cssloader = "<link href=\"shownotes.css\" type=\"text/css\" rel=\"stylesheet\" /><body>"
        description = cssloader + description + "</body>"
        episodeShowNotesWebView.loadHTMLString(description, baseURL: urlpath)
        
        episodeImage.image = getEpisodeImage(episode, size: CGSize(width: episodeImage.frame.size.height, height: episodeImage.frame.size.width))
        // rate Button
        if (SingletonClass.sharedInstance.playerinitialized == true) {
            let currentspeed = SingletonClass.sharedInstance.player.rate
            if currentspeed != 0 {
                let indexofspeed:Int = speeds.firstIndex(of: currentspeed)!
                playerRateButton.setTitle(speedtext[indexofspeed], for: UIControl.State())
            }
        }
        playerRateButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
        forward30Button.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
        back30Button.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
        playButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
        pauseButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
        
        
        
        forward30Button.setImage(createSkipWithColor(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSize(width: 30, height: 30), filled: true, forward: true, label: "30"), for: UIControl.State())
        forward30Button.setTitle(nil, for: UIControl.State())
        
        back30Button.setImage(createSkipWithColor(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSize(width: 30, height: 30), filled: true, forward: false, label: "30"), for: UIControl.State())
        back30Button.setTitle(nil, for: UIControl.State())
        
        
        
        
    }
    
    
    func adjustColors(){
        self.navigationController?.isToolbarHidden = false
        
        listButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), for: UIControl.State())
        
        
        playButton.tintColor = getColorFromPodcastSettings("playControlColor")
        pauseButton.tintColor = getColorFromPodcastSettings("playControlColor")
        back30Button.tintColor = getColorFromPodcastSettings("playControlColor")
        forward30Button.tintColor = getColorFromPodcastSettings("playControlColor")
        
        self.navigationController?.toolbar.barTintColor = getColorFromPodcastSettings("backgroundColor")
        self.navigationController?.toolbar.isTranslucent = false
        self.navigationController?.toolbar.clipsToBounds = true
        
        
        self.view.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        subView.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        sleeptimerBarButton.tintColor = getColorFromPodcastSettings("playControlColor")
        shareBarButton.tintColor = getColorFromPodcastSettings("playControlColor")
        chapterBarButton.tintColor = getColorFromPodcastSettings("playControlColor")
        infoButton.tintColor = getColorFromPodcastSettings("playControlColor")
        playerRateButton.tintColor = getColorFromPodcastSettings("playControlColor")
        playerRateButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), for: UIControl.State())
        
        if episode.episodeChapter.count == 0
        {
            chapterBarButton.isEnabled = false
            chapterBarButton.tintColor = getColorFromPodcastSettings("backgroundColor")
            
        }
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if SingletonClass.sharedInstance.player.rate != 0 {
            starttimer()
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
      //  self.navigationController?.navigationBarHidden = true
        self.navigationController?.isToolbarHidden = false

        fixTheDuration()
        updateplayprogress()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
      //  self.navigationController?.navigationBarHidden = false
        self.navigationController?.isToolbarHidden = true
    }
    
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        //do some stuff from the popover
    }
    
    func disableswipeback(){
        if navigationController!.responds(to: #selector(getter: UINavigationController.interactivePopGestureRecognizer)) {
            navigationController!.view.removeGestureRecognizer(navigationController!.interactivePopGestureRecognizer!)
        }
    }
    
    
    
    func enableOrDisableControllsIfNoInFocus(){
        if episode.episodeTitle == ""{
            episode = SingletonClass.sharedInstance.episodePlaying
        }
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle != episode.episodeTitle){
            forward30Button.isEnabled = false
            forward30Button.isHidden = true
            back30Button.isEnabled = false
            back30Button.isHidden = true
            playerRateButton.isEnabled = false
            playerRateButton.isHidden = true
        }else{
            forward30Button.isEnabled = true
            forward30Button.isHidden = false
            back30Button.isEnabled = true
            back30Button.isHidden = false
            playerRateButton.isEnabled = true
            playerRateButton.isHidden = false
        }
    }
    
    /**************************************************************************
     
     ALL THE TIMER FUNCTIONS FOLLOWING
     (updating the view to show the correct progress)
     
     **************************************************************************/
    
    
    func starttimer(){
        SingletonClass.sharedInstance.audioTimer.invalidate()
        SingletonClass.sharedInstance.audioTimer = Timer.scheduledTimer(timeInterval: 0.2, target:self, selector: #selector(EpisodeViewController.updateplayprogress),userInfo: nil,repeats: true)
    }
    
    func stoptimer(){
        SingletonClass.sharedInstance.audioTimer.invalidate()
    }
    
    
    
    
    
    
    
    /**************************************************************************
     
     ALL THE SLEEP TIMER FUNCTIONS FOLLOWING
     (showing and updating the sleep timer to pause audio)
     
     **************************************************************************/
    
    func showsleeptimer(){
        
        var description = NSLocalizedString("sleep.timer.description", value: "The sleep timer will automatically pause the episode after the selcted time", comment: "shown in Episode Player")
        
        if let remainingTime = readSleepTimer().remaining {
            if readSleepTimer().set == true {
                let timeInfo = String.localizedStringWithFormat(
                    NSLocalizedString("string.for.time.remaining", value:"%@ remaining",
                                      comment: "shown in TableView"),
                    secondsToHoursMinutesSeconds(Double(remainingTime)))
                description = description + "\n\n" + timeInfo
            }
        }
        
        
        let alert = UIAlertController(title: NSLocalizedString("sleep.timer.title", value: "Sleep timer", comment: "shown in Episode Player"), message: description , preferredStyle: .actionSheet)
        
        let disableAction = UIAlertAction(title: NSLocalizedString("sleep.timer.deactivate", value: "Disable", comment: "shown in Episode Player"), style: .default) { (alert: UIAlertAction!) -> Void in
            self.cancelleeptimer()
        }
        
        let firstAction = UIAlertAction(title: NSLocalizedString("sleep.timer.30", value: "30 Minutes", comment: "shown in Episode Player"), style: .default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(30)
        }
        
        let secondAction = UIAlertAction(title: NSLocalizedString("sleep.timer.15", value: "15 Minutes", comment: "shown in Episode Player"), style: .default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(15)
        }
        
        
        let thirdAction = UIAlertAction(title: NSLocalizedString("sleep.timer.5", value: "5 Minutes", comment: "shown in Episode Player"), style: .default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(5)
        }
        
        let debugAction = UIAlertAction(title: NSLocalizedString("sleep.timer.debug", value: "0.1 Minutes", comment: "shown in Episode Player"), style: .default) { (alert: UIAlertAction!) -> Void in
            self.setsleeptimer(0.1)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("sleep.timer.cancel", value: "cancel", comment: "shown in Episode Player"), style: .cancel) { (alert: UIAlertAction!) -> Void in
            
        }
        alert.addAction(disableAction)
        alert.addAction(firstAction)
        alert.addAction(secondAction)
        alert.addAction(thirdAction)
        
        
        #if targetEnvironment(simulator)
        alert.addAction(debugAction)
        #endif
        
        
        alert.addAction(cancelAction)
        alert.view.tintColor = getColorFromPodcastSettings("playControlColor")
        // alert.view.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        present(alert, animated: true, completion:nil) // 6
        NSLog("\(readSleepTimer())")
    }
    
    
    
    func setsleeptimer(_ minutes: Double){
        let seconds = minutes * 60
        SingletonClass.sharedInstance.sleeptimer = seconds
        SingletonClass.sharedInstance.sleeptimerset = true
        NSLog("Sleeptimer set to \(minutes) that's \(seconds)")
    }
    
    func cancelleeptimer(){
        SingletonClass.sharedInstance.sleeptimerset = false
    }
    
    func readSleepTimer() -> (set : Bool, remaining : Double?) {
        return (SingletonClass.sharedInstance.sleeptimerset, SingletonClass.sharedInstance.sleeptimer)
    }
    
    func checksleeptimer(){
        if (readSleepTimer().remaining <= 0.0){
            pause()
            NSLog("good night")
            cancelleeptimer()
        }
        
        
    }
    
    func updateSleepTimer(){
        // if a Sleeptimer is set, reduce the time of the sleeptimer by the Interval of the playtimer
        SingletonClass.sharedInstance.sleeptimer -= SingletonClass.sharedInstance.audioTimer.timeInterval
        
    }
    
    
    /**************************************************************************
     
     ALL THE CHAPTER MARK FUNCTIONS FOLLOWING
     (showing and chosing the chapter marks)
     
     **************************************************************************/
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //segue for the popover configuration window
        if segue.identifier == "showChapterMarks" {
            let vc = segue.destination as! ChapterMarksViewController
            vc.EpisodeViewController = self
            let controller = vc.popoverPresentationController
            vc.Chapters = episode.episodeChapter
            
            if controller  != nil{
                controller?.delegate = self
            }
        }
    }
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
    
    
    /**************************************************************************
     
     ALL THE FILE LOADING FUNCTIONS FOLLOWING
     (could be part of the basic player section)
     
     **************************************************************************/
    
    
    
    
    func loadNSURL(_ episode : Episode) -> URL{
        let locally = existsLocally(episode.episodeFilename)
        if  locally.existlocal{
            return URL(fileURLWithPath: locally.localURL)
        }else{
            return URL(string: episode.episodeUrl)!
        }
    }
    
    
    /**************************************************************************
     
     ALL THE PLAYER FUNCTIONS FOLLOWING
     (Play, Pause, skip forward and backwards)
     
     **************************************************************************/
    
    func initplayer(_ episode: Episode){
        
        
       // createLoadingMessage()
        
            let url = loadNSURL(episode)
            SingletonClass.sharedInstance.player = AVPlayer(url: url)
            SingletonClass.sharedInstance.episodePlaying = episode
            SingletonClass.sharedInstance.playerinitialized = true
        
        
            SingletonClass.sharedInstance.setaudioSession()
            fixTheDuration()
            updateMPMediaPlayer()
        
        
    }
    
    
    func createLoadingMessage(){
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        let Width = screenWidth*0.75
        let Height = screenHeight*0.75
        let x = (screenWidth-Width)/2
        let y = (screenHeight-Height)/2
        DynamicView=UIView(frame: CGRect(x: x, y: y, width: Width, height: Height))
        DynamicView.backgroundColor=UIColor.black.withAlphaComponent(0.75)
        DynamicView.layer.cornerRadius=25
        DynamicView.layer.borderWidth=2
        self.view.addSubview(DynamicView)
    }
    
    func removeLoadingMessage(){
            DynamicView.removeFromSuperview()
    }
    
    
    func autoplay(){
        if SingletonClass.sharedInstance.player.rate == 0 && SingletonClass.sharedInstance.player.error == nil {
            play()
            
        }
    }
    
    
    func moveplayer(_ seconds:Double){
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
            let secondsToAdd = CMTimeMakeWithSeconds(seconds,1)
            let jumpToTime = CMTimeAdd(SingletonClass.sharedInstance.player.currentTime(), secondsToAdd)
            SingletonClass.sharedInstance.player.seek(to: jumpToTime)
            updatePlayPosition()
            
            
        }
    }
    
    func jumpToTimeInPlayer(_ seconds:Double){
        let targetTime = CMTimeMakeWithSeconds(seconds,1)
        print("targettime \(targetTime)")
        SingletonClass.sharedInstance.player.seek(to: targetTime)
        updatePlayPosition()
        
    }
    
    
    
    @objc func playPausefromRemoteCenter(){
        
        episode = SingletonClass.sharedInstance.episodePlaying
        NSLog("playPausefromRemote: \(episode.episodeTitle)")
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
                SingletonClass.sharedInstance.episodePlaying = episode
                let url = loadNSURL(episode)
                SingletonClass.sharedInstance.player.replaceCurrentItem(with: AVPlayerItem(url: url))
                fixTheDuration()
                let starttime = episode.readplayed()
                SingletonClass.sharedInstance.player.seek(to: starttime)
                
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
        
        
        if (SingletonClass.sharedInstance.playerinitialized == false) {
            initplayer(episode)
        }
        
        
        var starttime = episode.readplayed()
        if starttime >= episode.getDurationinCMTime() && episode.getDurationInSeconds() != 0.0 {
            episode.saveplayed(0.0)
            NSLog("read after save \(episode.getDurationinCMTime())")
            starttime = episode.readplayed()
        }
        
        starttimer()
        NotificationCenter.default.addObserver(self, selector:#selector(EpisodeViewController.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        SingletonClass.sharedInstance.player.seek(to: starttime)
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
        NotificationCenter.default.removeObserver(self)
        let played = SingletonClass.sharedInstance.player.currentTime()
        let episode = SingletonClass.sharedInstance.episodePlaying
        episode.saveplayed(Double(CMTimeGetSeconds(played)))
        NSLog("played: \(Double(CMTimeGetSeconds(played)))")
        somethingplayscurrently = false
        setplaypausebutton()
        updateMPMediaPlayer()
    }
    
    
    @objc func playerDidFinishPlaying(){
        let episode = SingletonClass.sharedInstance.episodePlaying
        NSLog("Did finish Playing \(episode.episodeTitle)")
        episode.deleteEpisodeFromDocumentsFolder()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    func setplaypausebutton(){
        enableOrDisableControllsIfNoInFocus()
        
        playButton.setTitle(nil, for: UIControl.State())
        playButton.setImage(createPlayImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSize(width: 30, height: 30), filled: true), for: UIControl.State())
        
        
        
        pauseButton.isHidden = true
        playButton.isHidden = false
        if (SingletonClass.sharedInstance.playerinitialized == true) {
            if (SingletonClass.sharedInstance.player.rate != 0 && SingletonClass.sharedInstance.player.error == nil) {
                if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
                    pauseButton.setTitle(nil, for: UIControl.State())
                    pauseButton.setImage(createPauseImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSize(width: 30,height: 30), filled: true), for: UIControl.State())
                    playButton.isHidden = true
                    pauseButton.isHidden = false
                }
            }
        }
    }
    
    func changespeed(){
        
        
        let currentspeed = SingletonClass.sharedInstance.player.rate
        if currentspeed != 0 { // stupid quick fix to avoid a crash when the player is paused
            let indexofspeed:Int = speeds.firstIndex(of: currentspeed)!
            var newindex:Int
            if (indexofspeed+1 < speeds.count){
                newindex = indexofspeed+1
            }else{
                newindex = 0
            }
            updateRate(newindex)
        }
    }
    
    func updateRate(_ rateindex: Int){
        playerRateButton.titleLabel?.textColor = getColorFromPodcastSettings("playControlColor")
        playerRateButton.setTitle(speedtext[rateindex], for: UIControl.State())
        
        setObjectForKeyToPersistentStorrage("player.rate", object: rateindex)
        SingletonClass.sharedInstance.player.rate = speeds[rateindex]
    }
    
    @objc func updateplayprogress(){
        if (SingletonClass.sharedInstance.playerinitialized == true){
            let progress = Double(CMTimeGetSeconds(SingletonClass.sharedInstance.player.currentTime()))
            let episode = SingletonClass.sharedInstance.episodePlaying
            
            
            episode.saveplayed(progress)
            
            //  NSLog("now Playing Chapter: \(episode.getChapterForSeconds(progress)?.chapterTitle)")
            
            
            
            
            
            updateSliderProgress(progress)
            updateMPMediaPlayer()
            setplaypausebutton()
            if (readSleepTimer().set == true){
                updateSleepTimer()
                checksleeptimer()
            }
            
        }
    }
    
    
    
    
    @objc func back30(){
        episode = SingletonClass.sharedInstance.episodePlaying
        moveplayer(-30)
    }
    @objc func forward30(){
        episode = SingletonClass.sharedInstance.episodePlaying
        moveplayer(30)
    }
    
    
    func updateSliderProgress(_ progress: Double){
        if (SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle){
            updateProgress(episode)
        }
    }
    
    
    
    /**************************************************************************
     
     ALL THE REMOTE PLAYER FUNCTIONS FOLLOWING
     (Controllcenter and Lockscreen player)
     
     **************************************************************************/
    
    
    func allowremotebuttons(){
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        

        commandCenter.skipBackwardCommand.addTarget         { (commandEvent) -> MPRemoteCommandHandlerStatus in  self.back30();   return .success }

        commandCenter.skipForwardCommand.addTarget         { (commandEvent) -> MPRemoteCommandHandlerStatus in  self.forward30();   return .success }

        
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        
        
        commandCenter.playCommand.addTarget         { (commandEvent) -> MPRemoteCommandHandlerStatus in  self.playPausefromRemoteCenter();   return .success }

        commandCenter.pauseCommand.addTarget         { (commandEvent) -> MPRemoteCommandHandlerStatus in  self.playPausefromRemoteCenter();   return .success }

        commandCenter.togglePlayPauseCommand.addTarget         { (commandEvent) -> MPRemoteCommandHandlerStatus in  self.playPausefromRemoteCenter();   return .success }

    }
    
    func updateMPMediaPlayer(){
        
        let playcenter = MPNowPlayingInfoCenter.default()
        let mediaArtwort = MPMediaItemArtwork(image: getEpisodeImage(episode))
        playcenter.nowPlayingInfo = [
            MPMediaItemPropertyArtwork: mediaArtwort,
            MPMediaItemPropertyReleaseDate: SingletonClass.sharedInstance.episodePlaying.episodePubDate,
            // MPMediaItemPropertyAlbumTitle: (SingletonClass.sharedInstance.episodePlaying.getChapterForSeconds(CMTimeGetSeconds(SingletonClass.sharedInstance.player.currentTime()))?.chapterTitle)!,
            MPMediaItemPropertyTitle : SingletonClass.sharedInstance.episodePlaying.episodeTitle,
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
        let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    /**************************************************************************
     
     ALL THE WebView FUNCTIONS FOLLOWING
     (Shownotes and their links)
     
     **************************************************************************/
    
    func webView(_ webView: UIWebView, shouldStartLoadWith r: URLRequest, navigationType nt: UIWebView.NavigationType) -> Bool{
        if (nt == UIWebView.NavigationType.linkClicked ) {
            openWithSafariVC(r.url!)
            return false;
        }
        return true;
        
    }
    
    func openWithSafariVC(_ url: URL)
    {
        if #available(iOS 9.0, *) {
            let svc = SFSafariViewController(url: url)
            svc.delegate = self
            self.present(svc, animated: true, completion: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
        
    }
    
    @available(iOS 9.0, *)
    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}


