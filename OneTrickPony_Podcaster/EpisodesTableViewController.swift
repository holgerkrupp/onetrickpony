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
    
    
    lazy var downloadsSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = self.downloadsSession

        
        loadfeedandparse()
        self.refreshControl?.addTarget(self, action: "pulltorefresh:", forControlEvents: UIControlEvents.ValueChanged)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    

    
    func loadfeedandparse(){
        
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
    }
    
    
    
    
    
    func updatetableview(){
        
        loadfeedandparse()
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    
    
    
    
    func pulltorefresh(sender:AnyObject)
    {
        
        if let dict = myDict {
            // Use your dict here
            let url = dict.valueForKey("feedurl") as! String
            print("pullto \(url)")
            downloadurl(url)
        }
        // Code to refresh table view
        
        // THIS HAS TO BE MOVED TO A SPECIFIC CALL WHEN THE FILE HAS BEEN UPDATED updatetableview()
        

        
    }
    
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "viewEpisode" {
            let episode: Episode = episodes[tableView.indexPathForSelectedRow!.row]
            let viewController = segue.destinationViewController as! EpisodeViewController
          //  self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Episode list", style:.Plain, target: self, action: nil);
            viewController.episode = episode
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    // Table view parts
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> EpisodeCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodeCell
        let episode: Episode = episodes[indexPath.row]
        
        cell.delegate = self
        cell.filltableviewcell(cell, episode: episode)
        
        return cell
    }
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let episode: Episode = episodes[indexPath.row]
        if (editingStyle == UITableViewCellEditingStyle.Delete){
            print("delete")
            let manager = NSFileManager.defaultManager()
            let documentsDirectoryUrl = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            let fileName = episode.episodeFilename
            print("doc directory \(documentsDirectoryUrl)")
            let localFeedFile = documentsDirectoryUrl + "/" + fileName
            print(episode.episodeFilename)
            do {
                try manager.removeItemAtPath(localFeedFile)
                print("deleted")
                episode.episodeLocal = false
            }catch{
                print("no file to delete")
                
            }
            let indexPath2 = NSIndexPath(forRow: indexPath.row, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath2], withRowAnimation: UITableViewRowAnimation.None)
            
            
            
        }
    }
    
    
    
    /* This shall replace the segue function to download first if not available.
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let episode: Episode = episodes[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodeCell
        if (episode.episodeLocal){
            print("click and local")
            
            performSegueWithIdentifier("viewEpisode", sender: nil)
        }else{
            print("click not local")
            cell.downloadepisode(episode)
        }
    }
    */
    
    
    
    
    
    // these are all download functions
    

    

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
        print("session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes.")

        print("TaskOrigRequest URL String \(downloadTask.originalRequest?.URL?.absoluteString)")
        if let downloadUrl = downloadTask.originalRequest?.URL?.absoluteString,
            download = activeDownloads[downloadUrl] {
                // 2
                download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
                print("Progress : \(download.progress)")
                print("Episode Index: \(episodeIndexForDownloadTask(downloadTask))")
                // 3
                let totalSize = NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: NSByteCountFormatterCountStyle.Binary)
                // 4
                if let episodeIndex = episodeIndexForDownloadTask(downloadTask), let episodeCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: episodeIndex, inSection: 0)) as? EpisodeCell {
                    dispatch_async(dispatch_get_main_queue(), {
                        episodeCell.Episodeprogressbar.hidden = false
                     //   episodeCell.EpisodeprogressLabel.hidden = false
                        episodeCell.Episodeprogressbar.progress = download.progress
                   //     episodeCell.EpisodeprogressLabel.text =  String(format: "%.1f%% of %@",  download.progress * 100, totalSize)
                    })
                }
        }
    }
    
    
    
    
    
    // the following functin is called when a download has been finished. It will write the date to the right folder (Documents Folder - hint hint) and update the tableviewcell if needed.
    
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
                    
                    // IF XML start updatetableview()
                    if (destinationURL.pathExtension!.lowercaseString == "xml"){
                        updatetableview()
                    }
                    
                    
                } catch let error as NSError {
                    print("Could not copy file to disk: \(error.localizedDescription)")
                }
        
        // clear the download list
        if let url = downloadTask.originalRequest?.URL?.absoluteString {
            activeDownloads[url] = nil
            // update the cell to update it that it has the file locally and only if it's a media file and not the feed
            if let episodeIndex = episodeIndexForDownloadTask(downloadTask), let episodeCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: episodeIndex, inSection: 0)) as? EpisodeCell {
                episodeCell.Episodeprogressbar.hidden = true
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
    
    
    
    
    
    
    
    
    
    // this function will get me the index for the cell of the episode containing the link used to download an episode in german I would call it something like episodedownloadcellindex (that was a strange sentence)
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

    
    // these are the parser functions
    
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
            episodes.append(episode)
        }
    }
    
}

extension EpisodesTableViewController: NSURLSessionDownloadDelegate {
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURLlocation: NSURL) {
        print("Finished downloading.")
    }
}


extension EpisodesTableViewController: EpisodeCellDelegate {
   
    
    func pauseepisode(cell: EpisodeCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let episode = episodes[indexPath.row]
           // pauseDownload(episode)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }

    func downloadepisode(cell: EpisodeCell){
       
        if let indexPath = tableView.indexPathForCell(cell) {
        let episode = episodes[indexPath.row]
        startDownloadepisode(episode)
       
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    func resumeepisode(cell: EpisodeCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let episode = episodes[indexPath.row]
        //    resumeDownload(episode)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func cancelepisode(cell: EpisodeCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let episode = episodes[indexPath.row]
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