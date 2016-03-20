//
// EpisodesTableViewController.swift
// OneTrickPony_Podcaster
//
// Created by Holger Krupp on 24/01/16.
// Copyright © 2016 Holger Krupp. All rights reserved.
//
import UIKit
import AVFoundation



class EpisodesTableViewController: UITableViewController, NSXMLParserDelegate {
    
    struct SessionProperties {
        static let identifier : String! = "url_session_background_download"
    }
    
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()

    
    var feedParser: NSXMLParser = NSXMLParser()
   // var feeddate: NSDate = NSDate()// this element contains currently the lastBuildDate from the feed, should be managed smarter one day to reduce the full feed loading to check if the feed is new
    
    var lastfeeddate: String = String()
    
    var episodes  = [Episode]()
    
    var episodeTitle: String = String()
    var episodeLink: String = String()//Link to the website
    var episodeUrl: String = String() //Link to the mediafile
    var episodeDuration: String = String()
    var episodePubDate: String = String()
    var episodeFilename: String = String()
    var episodeFilesize: Int = Int()
    var episodeImage: String = String()
    var episodeChapters = [Chapter]()
    var episodeDescription: String = String()
    var eName: String = String()
    
    let manager = NSFileManager.defaultManager()
    var myDict: NSDictionary?
    
    var activeDownloads = [String: Download]()
    
    
    lazy var downloadsSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    
    
    /**************************************************************************
     
                    ALL THE BASIC VIEW FUNCTIONS FOLLOWING
                (loading and configurating the view controller)
     
     **************************************************************************/
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = self.downloadsSession
      //  removePersistentStorrage()
        
        
        
        print("last Episode: \(getvalueforkeyfrompersistentstorrage("latestepisode"))")
        print("last FeedDay: \(getvalueforkeyfrompersistentstorrage("lastfeedday"))")
        
        
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.separatorColor = getColorFromPodcastSettings("highlightColor")
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.tableView.layoutMargins = UIEdgeInsetsZero

        
        
        self.refreshControl?.addTarget(self, action:"refreshfeed", forControlEvents: UIControlEvents.ValueChanged)
     //   self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")

        
        
    }
    
    

    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.toolbarHidden = true

        self.tableView.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        loadfeedandparse {
            
        }
        if SingletonClass.sharedInstance.playerinitialized {
            SingletonClass.sharedInstance.audioTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target:self, selector:"updatecell",userInfo: nil,repeats: true)
        }
    }

    func updatecell(){
        updateCellForEpisode(SingletonClass.sharedInstance.episodePlaying)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "viewEpisode" {
            let episode: Episode = episodes[tableView.indexPathForSelectedRow!.row]
            let viewController = segue.destinationViewController as! EpisodeViewController
            viewController.episode = episode
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "viewEpisode" {
            return true
        }
        return true
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**************************************************************************
     
                    ALL THE FEED FUNCTIONS FOLLOWING
                    (loading and parsing the feed)
     
     **************************************************************************/
    
    func loadfeedandparse(completion: () -> Void){
        
        //preload the file in the base directory named feed.xml
        episodes.removeAll()
        let urlpath = NSBundle.mainBundle().pathForResource("feed", ofType: "xml")
        let localfileurl:NSURL = NSURL.fileURLWithPath(urlpath!)
        var fileURLtoLoad = localfileurl
        
        var url = NSURL.fileURLWithPath(getValueForKeyFromPodcastSettings("feedurl") as! String) 
        if url.pathExtension == "" {
            
            url = url.URLByAppendingPathComponent("feed.xml")
        }
        let fileName = url.lastPathComponent!
        
        //find out the path of the document directory for this app
        let documentsDirectoryUrl = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        //merge path and filename
        let localFeedFile = documentsDirectoryUrl + "/" + fileName
        
        
        //check if the file exists in the local documents directory
        
        if manager.fileExistsAtPath(localFeedFile){
            //change url to load to local file instead of the external one

            do {
                let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(localFeedFile)
                if let _attr = attr {
                   let fileSize = _attr.fileSize();
                    if fileSize > 1000 {
                        //the check for the fileSize is done in case a broken xml file has been downloaded (e.g. html file with 'error on database connection' message - should be one day removed by smarter way)
                        fileURLtoLoad = NSURL.fileURLWithPath(localFeedFile)
                    }
                }
            } catch {
                print("Error: \(error)")
            }
            
            
            
        }else{
            //we might be able to download the feed here, but I'm not sure if it's reactive enough.
            print("no file in docs folder or file to small, I'll take the one in the base directory")
        }
    
        
        
        //parse the file (either the one in the documents folder or if that's not there the feed.xml from the base
        print("loading feed from \(fileURLtoLoad)")
        feedParser = NSXMLParser(contentsOfURL: fileURLtoLoad)!
        feedParser.delegate = self
        feedParser.parse()
        
        completion()
    }
    

    
    
    func checkifepisodeisnew(completion:(result: Bool) -> Void){
        print("Check if Episode is new started")
        var result:Bool
        result = false
        if let date1 = getvalueforkeyfrompersistentstorrage("latestepisode"){
            let Date1 = date1 as! NSDate
            let Date2 = episodes[0].episodePubDate
            if Date1.earlierDate(Date2).isEqualToDate(Date1){
                result = true
              //  setvalueforkeytopersistentstorrage("latestepisode", value: episodes[0].episodePubDate)
                print("set new Episode to persistent storrage")

            }else{
                print("no new episode found")
                //   dummyNotificationforDebugging()
            }
        }else{
            print("no episode downloaded yet")
            result = true

          //  setvalueforkeytopersistentstorrage("latestepisode", value: episodes[0].episodePubDate)
        }
        print("episode check done")
        completion(result: result)
    }

    
    
    func createLocalNotification(episode: Episode){
        let localNotification =  UILocalNotification()
        localNotification.alertBody = "\(episode.episodeTitle) is available"
        localNotification.soundName = "pushSound.m4a"
        localNotification.alertAction = "Details"
        
        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
    }
    
    
    
    func dummyNotificationforDebugging(){
        let localNotification =  UILocalNotification()
        //---the message to display for the alert---
        localNotification.alertBody =
        "nothing new is available"
        
        //---uses the default sound---
        localNotification.soundName = "pushSound.m4a";
        
        //---title for the button to display---
        localNotification.alertAction = "Details"
        
        //---display the notification---
        
        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
    }
    
    
    func refreshfeed()
    {
            let url = getValueForKeyFromPodcastSettings("feedurl")  as! String
            print("pullto \(url)")
            checkFeedDateIsNew {
                (result: Bool) in
                    if result {
                        // the file on the server has been update, start downloading a new feed file
                        self.downloadurl(url)
                        print("Downloading feed")
                    }else{
                        print("server feed same date or older")
                }
            }
    }
    
    
    
    func checkFeedDateIsNew(completion:(result: Bool) -> Void){
        var result:Bool
        let savedfeeddate = getvalueforkeyfrompersistentstorrage("lastfeedday")
        print("oldfeed: \(savedfeeddate) (from Persistent Storrage)")

        
            
            // get the last modified date from the file on the server
            let date = getHeaderFromUrl(getValueForKeyFromPodcastSettings("feedurl") as! String, headerfield: "Last-Modified")
        if date != "" {
            let newfeeddate = dateStringToNSDate(date)
            print("oldfeed: \(newfeeddate) (Header from Server)")
            
            
            // compare it with the last saved date
            let compareResult = savedfeeddate!.compare(newfeeddate)
            print(compareResult)
            
            if compareResult == NSComparisonResult.OrderedDescending {
                // usually the date on the server should never be younger than the date saved
                result = false
                print("\(savedfeeddate) (saved date) is younger than \(newfeeddate) - nothing to do but strange")
                self.refreshControl!.endRefreshing()
            }else if compareResult == NSComparisonResult.OrderedAscending{
                // this is the normal behaviour when the feed has been updated
                result = true
                print("\(savedfeeddate) (saved date) is older than \(newfeeddate) - to refresh feed")
            }else{
                // this is the part when there has been no change on the feed since last check
                result = false
                print("same date")
                self.refreshControl!.endRefreshing()
            }
        }else{
            result = false
            print("ERROR NO DATE")
            showErrorMessage("Error", message: "Server not reachable", viewController: self)
            self.refreshControl!.endRefreshing()
        }
        

        completion(result: result)
    }
    
    

    
    
    var data: NSMutableData = NSMutableData()
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        eName = elementName
        if elementName == "lastBuildDate" {
            lastfeeddate = String()
        } else if elementName == "item" {
            episodeTitle = String()
            episodeLink = String()
            
            episodeDuration = String()
            
            episodeChapters = [Chapter]()
        } else if elementName == "enclosure"{
            episodeUrl = attributeDict["url"]!
            episodeFilesize = Int(attributeDict["length"]!)!
        }else if elementName == "itunes:image"{
            episodeImage = attributeDict["href"]!
            
            let existence = existslocally(episodeImage)
            if (existence.existlocal){
                episodeImage = existence.localURL
            } else {
                downloadurl(episodeImage)
                episodeImage = existence.localURL
            }
            
        } else if elementName == "psc:chapter"{
            
            // Potlove Simple Chapters parsing
            
            let chapter: Chapter = Chapter()
            if let atttitle: NSString = attributeDict["start"] {
                chapter.chapterStart = atttitle as String
            }
            if let atttitle: NSString = attributeDict["title"] {
                chapter.chapterTitle = atttitle as String
            }
            if let atttitle: NSString = attributeDict["href"] {
                chapter.chapterLink = atttitle as String
            }
            if let atttitle: NSString = attributeDict["image"] {
                chapter.chapterImage = atttitle as String
            }
            episodeChapters.append(chapter)
        }
    }
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        let data = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if (!data.isEmpty) {
            if eName == "title" {
                episodeTitle = data
            } else if eName == "link" {
                episodeLink = data
            }else if eName == "itunes:duration" {
                episodeDuration = data
            }else if eName == "pubDate" {
                episodePubDate = data
            }else if eName == "lastBuildDate"{
                lastfeeddate = data
            }else if eName == "description"{
                episodeDescription = data
            }
        }
    }
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "lastBuildDate"{
            let lastBuildDate = dateStringToNSDate(lastfeeddate)
            setvalueforkeytopersistentstorrage("lastfeedday" as String, value: lastBuildDate)
        } else if elementName == "item" {
            let episode: Episode = Episode()
            episode.episodeTitle = episodeTitle
            episode.episodeUrl = episodeUrl
            episode.episodeLink = episodeLink
            
            
            episode.episodeDuration = episodeDuration
            
            
            // BUG BUG BUG 
            
            //here I should take care that the duration within the feed is sometimes not correct and the duration within the feed can be 0 But the code below doesn't work, as the loading of the file, if the duration is 0, takes a while and I should wait until AVPlayerStatus is readyToPlay.
            
            
            
            /*
            if stringtodouble(episodeDuration) == 0.0 && existslocally(episodeUrl).existlocal{
                let tempitem = AVPlayer(URL: NSURL(string: existslocally(episodeUrl).localURL)!)
                print("item: \(tempitem)")
                print("CMTime \(tempitem.currentItem!.duration)")
                print("Seconds \(CMTimeGetSeconds(tempitem.currentItem!.duration))")
                print("Text \(secondsToHoursMinutesSeconds(CMTimeGetSeconds(tempitem.currentItem!.duration)))")
                episode.episodeDuration = secondsToHoursMinutesSeconds(CMTimeGetSeconds(tempitem.currentItem!.duration))
                print("episode \(episodeTitle) without duration found - new duration: \(episode.episodeDuration)")
            }else{
                episode.episodeDuration = episodeDuration
            }
            */
            
            
            
            episode.episodePubDate = dateStringToNSDate(episodePubDate)
            let url: NSURL = NSURL(string: episodeUrl)!
            episode.episodeFilename = url.lastPathComponent!
            episode.episodeFilesize = episodeFilesize
            episode.episodeImage = episodeImage
            episode.episodeChapter = episodeChapters
            episode.episodeDescription = episodeDescription
            episode.episodeIndex = episodes.count
            episodes.append(episode)
        }else if elementName == "channel"{
            print("end of feed")

        }
    }
    func parserDidEndDocument(parser: NSXMLParser) {
        SingletonClass.sharedInstance.numberofepisodes = episodes.count
        print("Parser DID End Document")
        var NotificationFired = false
        self.checkifepisodeisnew{
            (result: Bool) in
            if result == true{
                setvalueforkeytopersistentstorrage("latestepisode", value: self.episodes[0].episodePubDate)
                if NotificationFired == false {
                    print("checking if episode new should be done")
                    self.startDownloadepisode(self.episodes[0])
                    self.createLocalNotification(self.episodes[0])
                    NotificationFired = true
                }
            }
        }
        
    }
    

    /**************************************************************************
     
                ALL THE TABLE VIEW FUNCTIONS FOLLOWING
                    (defining the table view and cells)
     
     **************************************************************************/
    
    
    
    
    // Table view parts
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EpisodeCell", forIndexPath: indexPath) as! EpisodeCell
        let episode: Episode = episodes[indexPath.row]
        cell.layoutMargins = UIEdgeInsetsZero
        
        cell.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        
        if let label = cell.EpisodeNameLabel {
            label.text = episode.episodeTitle
            label.textColor = getColorFromPodcastSettings("textcolor")
        }
        
        if SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle {
            if SingletonClass.sharedInstance.player.rate == 0{
                cell.EpisodePlayButton.setImage(UIImage(named: "Play filled"), forState: UIControlState.Normal)
            }else{
                cell.EpisodePlayButton.setImage(UIImage(named: "Pause filled"), forState: UIControlState.Normal)
            }
            cell.EpisodePlayButton.enabled = true
            cell.EpisodePlayButton.hidden = false
        }else{
            cell.EpisodePlayButton.enabled = false
            cell.EpisodePlayButton.hidden = true
        }
        
        cell.delegate = self
        
        if let download = activeDownloads[episode.episodeUrl] {
            let title = (download.isDownloading) ? "Pause" : "Resume"
            cell.EpisodePauseButton.setTitle(title, forState: UIControlState.Normal)
        }
        
        
        var showDownloadControls = false
        if let download = activeDownloads[episode.episodeUrl] {
            showDownloadControls = true
            
            cell.EpisodeDownloadProgressbar.progress = download.progress
        }
        cell.EpisodeDownloadProgressbar.hidden = !showDownloadControls
        
        
        cell.EpisodePauseButton.hidden = !showDownloadControls
        cell.EpisodeCancelButton.hidden = !showDownloadControls
        cell.EpisodeDownloadButton.hidden = showDownloadControls
        
        
        cell.filltableviewcell(episode)

        return cell
    }
    
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        // WHAT WOULD BE COOL IS to return only true if the episode is locally or partly locally
        
        
        return true
    }
    
    
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let episode: Episode = episodes[indexPath.row]
        if (editingStyle == UITableViewCellEditingStyle.Delete){
            episode.deleteEpisodeFromDocumentsFolder()
            let indexPath2 = NSIndexPath(forRow: indexPath.row, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath2], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    func updateCellForEpisode(episode: Episode){
        let cellRowToBeUpdated = episode.episodeIndex
        let indexPath = NSIndexPath(forRow: cellRowToBeUpdated, inSection: 0)
        if self.tableView.cellForRowAtIndexPath(indexPath) != nil {
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        }
        
    }

    /**************************************************************************
    
                    ALL THE DOWNLOAD FUNCTIONS FOLLOWING
                (used for downloading feed, coverimages and media files)
                    [should be taken out of the viewController one day]
    
    **************************************************************************/
    

    

    func startDownloadepisode(episode: Episode) {
        if let url =  NSURL(string: episode.episodeUrl) {
            let download = Download(url: episode.episodeUrl)
            download.isEpisode  = true
            download.downloadTask = downloadsSession.downloadTaskWithURL(url)
            download.downloadTask!.resume()
            download.isDownloading = true
  
            activeDownloads[download.url] = download
            print("started download of \(url)")
           
        }
    }
    
    
    func pauseDownloadepisode(episode: Episode) {
        let urlString = episode.episodeUrl
        let download = activeDownloads[urlString]
        
        if(download!.isDownloading) {
            download!.downloadTask?.cancelByProducingResumeData { data in
                if data != nil {
                    download!.resumeData = data
                }
            }
            download!.isDownloading = false
        }
    }
    
    
    func resumeDownloadepisode(episode: Episode) {
        let urlString = episode.episodeUrl
        let download = activeDownloads[urlString]
                if let resumeData = download!.resumeData {
                    download!.downloadTask = downloadsSession.downloadTaskWithResumeData(resumeData)
                    download!.downloadTask!.resume()
                    download!.isDownloading = true
                } else if let url = NSURL(string: download!.url) {
                    download!.downloadTask = downloadsSession.downloadTaskWithURL(url)
                    download!.downloadTask!.resume()
                    download!.isDownloading = true
                }
        
    }
    
    func cancelDownloadepisode(episode: Episode) {
        let urlString = episode.episodeUrl
        let download = activeDownloads[urlString]
                download!.downloadTask?.cancel()
                activeDownloads[urlString] = nil
        
    }
    
    
    func downloadurl(urlstring: String) {
        if let url = activeDownloads[urlstring] {
        print("\(url) already downloading")
            }else{
        if let url =  NSURL(string: urlstring) {
        let download = Download(url: urlstring)
         download.isEpisode = false
        download.downloadTask = downloadsSession.downloadTaskWithURL(url)
        download.downloadTask!.resume()
        download.isDownloading = true
        activeDownloads[download.url] = download
        }
        }
    }
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
      //  print("session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes.")

    //    print("TaskOrigRequest URL String \(downloadTask.originalRequest?.URL?.absoluteString)")
        if let downloadUrl = downloadTask.originalRequest?.URL?.absoluteString,
            download = activeDownloads[downloadUrl] {
                // 2
                download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)

                if let episodeIndex = episodeIndexForDownloadTask(downloadTask), let episodeCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: episodeIndex, inSection: 0)) as? EpisodeCell {
                    dispatch_async(dispatch_get_main_queue(), {
                        episodeCell.EpisodeDownloadProgressbar.hidden = false
                        episodeCell.EpisodeDownloadProgressbar.progress = download.progress
                        episodeCell.EpisodeDownloadButton!.setTitle("Pause", forState: UIControlState.Normal)
                        
                   //     episodeCell.EpisodeprogressLabel.text =  String(format: "%.1f%% of %@",  download.progress * 100, totalSize)
                    })
                }
        }
    }
    
    
    
    
    
    // the following functin is called when a download has been finished. It will write the date to the right folder (Documents Folder - hint hint) and the tableviewcell if needed.
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        // move the file to the final destination
        let destinationURL = localFilePathForUrl((downloadTask.originalRequest?.URL)!)
                
                print("did finish download \(destinationURL)")
                
                // but clean the space before doing that.
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtURL(destinationURL)
                } catch {
                    // Non-fatal: file probably doesn't exist
                }
                do {
                    try fileManager.copyItemAtURL(location, toURL: destinationURL)
                    print("wrote new file")
                  //  setvalueforkeytopersistentstorrage("lastfeedday" as String, value: NSDate())

                    if (destinationURL.pathExtension!.lowercaseString == "xml"){
                        loadfeedandparse {
                        
                            self.tableView.reloadData()
                       
                            
                            self.refreshControl?.endRefreshing()
                        }
                    }
                    
                    
                } catch let error as NSError {
                    print("Could not copy file to disk: \(error.localizedDescription)")
                }
        
        // clear the download list
        if let url = downloadTask.originalRequest?.URL?.absoluteString {
            activeDownloads[url] = nil
            // update the cell to update it that it has the file locally and only if it's a media file and not the feed
            if let episodeIndex = episodeIndexForDownloadTask(downloadTask), let episodeCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: episodeIndex, inSection: 0)) as? EpisodeCell {
                episodeCell.EpisodeDownloadProgressbar.hidden = true
         //       episodeCell.EpisodeprogressLabel.hidden = true
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: episodeIndex, inSection: 0)], withRowAnimation: .None)
                })
            }
        }
    }
    
    func localFilePathForUrl(originalUrl:NSURL)-> NSURL{
        
        var newUrl = originalUrl
        if originalUrl.pathExtension == "" {
            print("empty")
            newUrl = originalUrl.URLByAppendingPathComponent("feed.xml")
        }
        let fileName = newUrl.lastPathComponent!
        let documentsDirectoryUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let destinationURL = documentsDirectoryUrl!.URLByAppendingPathComponent(fileName)
        return destinationURL
    }
    
    
    
    
    

    
    
    
    
        // this function will get me the index of the array which should be the same as the index of the cell for the  episode containing the same episode as the download task
    

    func episodeIndexForDownloadTask(downloadTask: NSURLSessionDownloadTask) -> Int? {
        if let url = downloadTask.originalRequest?.URL?.absoluteString {

            for (index, episode) in episodes.enumerate() {
                if url == episode.episodeUrl {
                    return index
                }
            }
        }
        return nil
    }

    
}

extension EpisodesTableViewController: NSURLSessionDownloadDelegate {
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURLlocation: NSURL) {
        print("Finished downloading.")
    }
}


extension EpisodesTableViewController: EpisodeCellDelegate {
    func downloadepisode(cell: EpisodeCell){
        
        if let indexPath = tableView.indexPathForCell(cell) {
            let episode = episodes[indexPath.row]
            startDownloadepisode(episode)
            
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func pauseepisode(cell: EpisodeCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
           let episode = episodes[indexPath.row]
            pauseDownloadepisode(episode)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }


    func resumeepisode(cell: EpisodeCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let episode = episodes[indexPath.row]
            resumeDownloadepisode(episode)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func cancelepisode(cell: EpisodeCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let episode = episodes[indexPath.row]
            cancelDownloadepisode(episode)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }

}

extension EpisodesTableViewController: NSURLSessionDelegate {
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                dispatch_async(dispatch_get_main_queue(), {
                    completionHandler()
                })
            }
        }
    }
}