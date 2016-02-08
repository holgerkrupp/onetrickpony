//
// EpisodesTableViewController.swift
// OneTrickPony_Podcaster
//
// Created by Holger Krupp on 24/01/16.
// Copyright © 2016 Holger Krupp. All rights reserved.
//
import UIKit


struct globals {
    static var episodes: [Episode] = []
}

class EpisodesTableViewController: UITableViewController, NSXMLParserDelegate {
    struct SessionProperties {
        static let identifier : String! = "url_session_background_download"
    }
    var feedParser: NSXMLParser = NSXMLParser()
    var episodes: [Episode] = globals.episodes
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
    
    var delegate = DownloadSessionDelegate.sharedInstance
    let manager = NSFileManager.defaultManager()
    var myDict: NSDictionary?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadfeedandparse()
        globals.episodes = episodes
        self.refreshControl?.addTarget(self, action: "pulltorefresh:", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    

    
    func loadfeedandparse(){
        
        //preload the file in the base directory named feed.xml
        
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
    
    
    
    
    
    
    
    
    
    
    
    func pulltorefresh(sender:AnyObject)
    {
        
        if let dict = myDict {
            // Use your dict here
            let url = dict.valueForKey("feedurl") as! String
            print("pullto \(url)")
            download(url)
        }
        // Code to refresh table view
        loadfeedandparse()
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
        
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
   /*
    func startConnectionAt(urlPath: String){
        let url: NSURL = NSURL(string: urlPath)!
        let request: NSURLRequest = NSURLRequest(URL: url)
        print("Request: \(request)")
        let connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: false)!
        print("EpisodeTablesDownload of \(url)")

        connection.start()
    }
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        print("Connection failed.\(error.localizedDescription)")
    }
    func connection(connection: NSURLConnection, didRecieveResponse response: NSURLResponse) {
        print("Recieved response")
    }
    func connection(didReceiveResponse: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        self.data = NSMutableData()
    }
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        self.data.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        var originalUrl = connection.originalRequest.URL
        //Get the file name and create a destination URL
 
        if originalUrl!.pathExtension == "" {
            print("empty")
            originalUrl = originalUrl?.URLByAppendingPathComponent("feed.xml")
        }
        let fileName = originalUrl!.lastPathComponent!
        let documentsDirectoryUrl = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let destinationURL = documentsDirectoryUrl!.URLByAppendingPathComponent(fileName)
        print("the file will be moved to \(destinationURL).")
        //Hold this file as an NSData and write it to the new location
        if let fileData:NSData = data{
            fileData.writeToURL(destinationURL, atomically: false) // true
            print(destinationURL.path!)
        }
    
    
    
    
    
    
        episodes.removeAll()
        
        loadfeedandparse()
        tableView.reloadData()
        refreshControl?.endRefreshing()
        print("success")
    }
    */
    
    func download(data: String) {
        print("download \(data)")
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(SessionProperties.identifier)
        let backgroundSession = NSURLSession(configuration: configuration, delegate: self.delegate, delegateQueue: nil)
        let url = NSURLRequest(URL: NSURL(string: data)!)

        let downloadTask = backgroundSession.downloadTaskWithRequest(url)
        
        downloadTask.resume()
        
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
                download(episodeImage)
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


