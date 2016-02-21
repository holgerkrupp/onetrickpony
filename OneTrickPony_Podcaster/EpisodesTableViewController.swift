//
// EpisodesTableViewController.swift
// OneTrickPony_Podcaster
//
// Created by Holger Krupp on 24/01/16.
// Copyright © 2016 Holger Krupp. All rights reserved.
//
import UIKit



class EpisodesTableViewController: UITableViewController, NSXMLParserDelegate {
    
    struct SessionProperties {
        static let identifier : String! = "url_session_background_download"
    }
    
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()

    
    var feedParser: NSXMLParser = NSXMLParser()
    var feeddate: String = String() // this element contains currently the lastBuildDate from the feed, should be managed smarter one day to reduce the full feed loading to check if the feed is new
    
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
    var eName: String = String()
    
    
    let manager = NSFileManager.defaultManager()
    var myDict: NSDictionary?
    
    var activeDownloads = [String: Download]()
    var todownloadnew:Bool = Bool()
    
    
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
      
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.refreshControl?.addTarget(self, action: "refreshfeed", forControlEvents: UIControlEvents.ValueChanged)
        
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        loadfeedandparse {
            
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "viewEpisode" {
            let episode: Episode = episodes[tableView.indexPathForSelectedRow!.row]
            let viewController = segue.destinationViewController as! EpisodeViewController
            //  self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Episode list", style:.Plain, target: self, action: nil);
            viewController.episode = episode
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "viewEpisode" {
            return true
        }
        return true
    }
    /*
    func switchtoplayerview(episode: Episode){
        if existslocally(episode.episodeUrl).existlocal {
            
            let segue:UIStoryboardSegue = UIStoryboardSegue(identifier: "viewEpisode", source: self, destination: self)
           print(self.childViewControllers)
            if segue.identifier == "viewEpisode" {

                let viewController = segue.destinationViewController as! EpisodeViewController
                viewController.episode = episode
            }
        } else {
            print("no streaming support")
        }
    }
    */
    
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
        var localfileurl:NSURL = NSURL.fileURLWithPath(urlpath!)
        
        //get the file name expected from the feed (Step 1 load directory)
        
        if let path = NSBundle.mainBundle().pathForResource("PodcastSettings", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
            print("myDict ok")
        }else{
            print("no plist")
        }
        if let dict = myDict {
            //get the file name expected from the feed (Step 2 get value for key)
            
            var url = NSURL.fileURLWithPath(dict.valueForKey("feedurl") as! String)
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
                localfileurl = NSURL.fileURLWithPath(localFeedFile)
            }else{
                //we might be able to download the feed here, but I'm not sure if it's reactive enough.
                print("no file in docs folder, I'll take the one in the base directory")
            }
            
            
            
        }else{
            // somebody didn't put the feed in the plist
            print("no feed in plist")
        }
        
        
        //parse the file (either the one in the documents folder or if that's not there the feed.xml from the base
        print("loading feed from \(localfileurl)")
        feedParser = NSXMLParser(contentsOfURL: localfileurl)!
        feedParser.delegate = self
        feedParser.parse()
        
        completion()
    }
    
    func checkiffeedhaschanged(completion:(result: Bool) -> Void){
        var result:Bool
        if getvalueforkeyfrompersistentstrrage("lastfeedday") as! String != feeddate{
            print("feeddate: \(feeddate)")
            print("feed from persistent \(getvalueforkeyfrompersistentstrrage("lastfeedday") as! String)")
            result = true
            setvalueforkeytopersistentstorrage("lastfeedday", value: feeddate)
        }else{
            result = false
            
        }
        completion(result: result)
    }
    
    
    func checkifepisodeisnew(completion:(result: Bool) -> Void){
        var result:Bool
        if getvalueforkeyfrompersistentstrrage("latestepisode") as! String != episodes[0].episodePubDate{

            result = true
            setvalueforkeytopersistentstorrage("latestepisode", value: episodes[0].episodePubDate)
        }else{
            result = false

        }
        completion(result: result)
    }

    
    func downloadepisodeifnew(){
        if self.todownloadnew == true {
            print("start download of \(self.episodes[0].episodeTitle)")
            startDownloadepisode(self.episodes[0])
            self.todownloadnew = false
        }
        
    }
    
    
    func checkfornewepisode(completion:() -> Void){
        self.checkiffeedhaschanged {
            (result: Bool) in
            if result {
                print("new feed")
                self.checkifepisodeisnew{
                    (result: Bool) in
                    if result {
                        print("new episode")
                        self.todownloadnew = true
                        print("First Episode \(self.episodes[0].episodeTitle)")
                        self.downloadepisodeifnew()

                        self.createlocalnotification(self.episodes[0])
                        
                        
                    }else{
                        print("old episode")
                    }
                    print("Episode check done")
                    print("latest episode: \(self.episodes[0].episodeTitle)")
                }
            }else{
                print("old feed")
                self.todownloadnew = false
            }
        }
        completion()
    }
    
    
    func createlocalnotification(episode: Episode){
        let localNotification =  UILocalNotification()
        //---the message to display for the alert---
        localNotification.alertBody =
        "\(episode.episodeTitle) is available"
        
        //---uses the default sound---
        localNotification.soundName = UILocalNotificationDefaultSoundName
        
        //---title for the button to display---
        localNotification.alertAction = "Details"
        
        //---display the notification---
        
        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
    }
    
    
    func refreshfeed()
    {
        
        if let dict = myDict {
            // Use your dict here
            let url = dict.valueForKey("feedurl") as! String
            print("pullto \(url)")
            downloadurl(url)
        }

    }
    
    var data: NSMutableData = NSMutableData()
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        eName = elementName
        if elementName == "item" {
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
                print(episodeImage)
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
                episodeTitle += data
            } else if eName == "link" {
                episodeLink = data
            }else if eName == "itunes:duration" {
                episodeDuration = data
            }else if eName == "pubDate" {
                episodePubDate = data
            }else if eName == "lastBuildDate"{
                feeddate = data
                print("lastBuildDate \(data)")

            }
        }
    }
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let episode: Episode = Episode()
            episode.episodeTitle = episodeTitle
            episode.episodeLink = episodeLink
            episode.episodeDuration = episodeDuration
            episode.episodeUrl = episodeUrl
            episode.episodePubDate = episodePubDate
            let url: NSURL = NSURL(string: episodeUrl)!
            episode.episodeFilename = url.lastPathComponent!
            episode.episodeFilesize = episodeFilesize
            episode.episodeImage = episodeImage
            episode.episodeChapter = episodeChapters
            episode.episodeIndex = episodes.count
            episodes.append(episode)
        }else if elementName == "channel"{
            print("end of feed")
            SingletonClass.sharedInstance.numberofepisodes = episodes.count
            self.checkfornewepisode  {
                
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
        if let label = cell.EpisodeNameLabel {
            label.text = episode.episodeTitle
        }
        
        
        cell.delegate = self
        cell.filltableviewcell(episode)
        print("IP: \(indexPath)")
        print("ET: \(episodeTitle)")
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
    
    
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // let episode: Episode = episodes[indexPath.row]
       // switchtoplayerview(episode)
        
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
    
    
    func downloadurl(urlstring: String) {
        if let url =  NSURL(string: urlstring) {
        // initialize the download of an URL (NOT AN EPISODE, BUT e.g a picture or the feed)
        let download = Download(url: urlstring)
            download.isEpisode = false
        download.downloadTask = downloadsSession.downloadTaskWithURL(url)
        download.downloadTask!.resume()
        download.isDownloading = true
        activeDownloads[download.url] = download
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
    
    func localFilePathForUrl(var originalUrl:NSURL)-> NSURL{
        if originalUrl.pathExtension == "" {
            print("empty")
            originalUrl = originalUrl.URLByAppendingPathComponent("feed.xml")
        }
        let fileName = originalUrl.lastPathComponent!
        let documentsDirectoryUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let destinationURL = documentsDirectoryUrl!.URLByAppendingPathComponent(fileName)
        return destinationURL
    }
    
    
    
    
    
    func updateCellForEpisode(episode: Episode){
        let cellRowToBeUpdated = episode.episodeIndex
        print("update Cell \(tableView.cellForRowAtIndexPath(NSIndexPath(forRow: episode.episodeIndex, inSection: 0))) for Episode \(episode.episodeTitle)")
        
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: cellRowToBeUpdated, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Left)
        // here the cell within the Tableview should be updated when visible. But unfortunatly the cell is always nil and I have no idea why. I tried 5 hours without any success so I'll will move to another topic and maybe come back later.
    
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
           // let episode = episodes[indexPath.row]
         //   pauseDownload(episode)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }


    func resumeepisode(cell: EpisodeCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
       //     let episode = episodes[indexPath.row]
         //   resumeDownload(episode)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func cancelepisode(cell: EpisodeCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
           // let episode = episodes[indexPath.row]
          //  cancelDownload(episode)
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