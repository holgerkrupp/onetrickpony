//
// EpisodesTableViewController.swift
// OneTrickPony_Podcaster
//
// Created by Holger Krupp on 24/01/16.
// Copyright © 2016 Holger Krupp. All rights reserved.
//
import UIKit
import AVFoundation




class EpisodesTableViewController: UITableViewController, XMLParserDelegate {
    
    
    
  //  var feedParser: XMLParser = XMLParser()
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
    
    let manager = FileManager.default
    var myDict: NSDictionary?
    
    let downloadImage: UIImage? = createCircleWithArrow(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSize(width: 30, height: 30), filled: true)
    
    let downloadPause: UIImage? = createCircleWithPause(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSize(width: 30, height: 30), filled: true)
    
    let downloadCancel: UIImage? = createCircleWithCross(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSize(width: 30, height: 30), filled: false)
    
    let status = Reach().connectionStatus()
    
    
    
    // parameters for background downloads
    var activeDownloads = [String: Download]()
    struct SessionProperties {
        static let identifier : String! = "url_session_background_download"
    }
    lazy var downloadsSession: Foundation.URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: SessionProperties.identifier)
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    
    // search relevant variables
    
    let searchController = UISearchController(searchResultsController: nil)
    var filtered = [Episode]()


    
    
    
    /**************************************************************************
     
     ALL THE BASIC VIEW FUNCTIONS FOLLOWING
     (loading and configurating the view controller)
     
     **************************************************************************/
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = self.downloadsSession
        self.title = NSLocalizedString("episodelist.title", value: "Episodes", comment: "Header of the Episodelist")
        //  removePersistentStorrage()
        
        
        /*
         print("last Episode: \(getObjectForKeyFromPersistentStorrage("latestepisode"))")
         print("last FeedDay: \(getObjectForKeyFromPersistentStorrage("lastfeedday"))")
         */
        loadfeedandparse {
            
        }
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.separatorColor = getColorFromPodcastSettings("highlightColor")
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.layoutMargins = UIEdgeInsets.zero
        if (navigationController != nil){
        self.navigationController?.navigationBar.barTintColor = getColorFromPodcastSettings("backgroundColor")
        self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : getColorFromPodcastSettings("textcolor")]
        self.navigationController?.navigationBar.tintColor = getColorFromPodcastSettings("textcolor")
        }
            DispatchQueue.main.async(execute: {
            self.autoFeedRefresh()
        })
        
        self.refreshControl?.addTarget(self, action:#selector(EpisodesTableViewController.refreshfeed), for: UIControl.Event.valueChanged)
        //   self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(EpisodesTableViewController.longPress(_:)))
        self.view.removeGestureRecognizer(longPressRecognizer)
        
        
        searchController.searchResultsUpdater = self

/*
        if #available(iOS 9.1, *) {
            searchController.obscuresBackgroundDuringPresentation = false
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = convertToNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: getColorFromPodcastSettings("textcolor")])
        }
 */
        searchController.searchBar.placeholder = NSLocalizedString("episodelist.search",value: "Search", comment: "shown in searchbar")
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            // Fallback on earlier versions
            tableView.tableHeaderView = searchController.searchBar
        }
        definesPresentationContext = true
        
    }
    

    
    
    func autoFeedRefresh(){
        let now = Date()
        if let lastfeedrefresh = getObjectForKeyFromPersistentStorrage("last feed refresh"){
            let interval = now.timeIntervalSince(lastfeedrefresh as! Date)
            NSLog("Time Interval between \(lastfeedrefresh) and \(now) is \(interval) seconds")
            if interval > 60*60*6 {
                switch status {
                case .unknown, .offline:
                    print("Not connected")
                case .online(.wwan):
                    print("Connected via WWAN")
                case .online(.wiFi):
                    print("Connected via WiFi")
                    self.refreshfeed()
                }
            }
        }
    }
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        //self.navigationController?.navigationBarHidden = true
        //self.navigationController?.toolbarHidden = true
        
        
        self.tableView.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        
        if SingletonClass.sharedInstance.playerinitialized {
            // self.tableView.reloadData()
            self.updateCellForEpisode(SingletonClass.sharedInstance.episodePlaying)
            SingletonClass.sharedInstance.audioTimer = Timer.scheduledTimer(timeInterval: 0.5, target:self, selector:#selector(EpisodesTableViewController.updatecell),userInfo: nil,repeats: true)
        }
    }
    
    
    @objc func updatecell(){
        updateCellProgressForEpisode(SingletonClass.sharedInstance.episodePlaying)
    }
    
    
    
    func updateCellProgressForEpisode(_ episode: Episode){
        let cellRowToBeUpdated = episode.episodeIndex
        let indexPath = IndexPath(row: cellRowToBeUpdated, section: 0)
        if self.tableView.cellForRow(at: indexPath) != nil {
            let currentCell = tableView.cellForRow(at: indexPath) as! EpisodeCell
            currentCell.updateProgress(episode)
        }
        
    }
    
    
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "viewEpisode" {
            
            var episode: Episode = episodes[tableView.indexPathForSelectedRow!.row]
            if isFiltering() {
                episode = filtered[tableView.indexPathForSelectedRow!.row]
            }
            let viewController = segue.destination as! EpisodeViewController
            viewController.episode = episode
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
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
    
    func loadfeedandparse(_ completion: () -> Void){
        
        //preload the file in the base directory named feed.xml
        episodes.removeAll()
        let urlpath = Bundle.main.path(forResource: "feed", ofType: "xml")
        let localfileurl:URL = URL(fileURLWithPath: urlpath!)
        var fileURLtoLoad = localfileurl
        
        var url = URL(fileURLWithPath: getObjectForKeyFromPodcastSettings("feedurl") as! String)
        // NSLog("url: \(url)")
        if url.pathExtension == "" {
            
            url = url.appendingPathComponent("feed.xml")
        }
        let fileName = url.lastPathComponent
        
        //find out the path of the document directory for this app
        let documentsDirectoryUrl = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        //merge path and filename
        let localFeedFile = documentsDirectoryUrl + "/" + fileName
        
        
        //check if the file exists in the local documents directory
        
        if manager.fileExists(atPath: localFeedFile){
            //change url to load to local file instead of the external one
            
            do {
                let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: localFeedFile) as NSDictionary?
                if let _attr = attr {
                    let fileSize = _attr.fileSize();
                    if fileSize > 1000 {
                        //the check for the fileSize is done in case a broken xml file has been downloaded (e.g. html file with 'error on database connection' message - should be one day removed by smarter way)
                        fileURLtoLoad = URL(fileURLWithPath: localFeedFile)
                    }
                }
            } catch {
                print("Error: \(error)")
            }
            
            
            
        }else{
            //we might be able to download the feed here, but I'm not sure if it's reactive enough.
            NSLog("no file in docs folder or file to small, I'll take the one in the base directory")
        }
        
        
        
        //parse the file (either the one in the documents folder or if that's not there the feed.xml from the base
        NSLog("loading feed from \(fileURLtoLoad)")
        if let feedParser: XMLParser = XMLParser(contentsOf: fileURLtoLoad){
            feedParser.delegate = self
            feedParser.parse()
        }
        completion()
    }
    
    
    
    
    func checkifepisodeisnew(_ completion:(_ result: Bool) -> Void){
        NSLog("Check if Episode is new started")
        var result:Bool
        result = false
        if let date1 = getObjectForKeyFromPersistentStorrage("latestepisode"){
            let Date1 = date1 as! Date
            let Date2 = episodes[0].episodePubDate
            NSLog("Last episode from storrage: \(Date1) - date from Episode[0]: \(Date2) ")
            
            if Date1.compare(Date2) == ComparisonResult.orderedDescending
            {
                NSLog("date1 after date2");
                result = false
            } else if Date1.compare(Date2) == ComparisonResult.orderedAscending
            {
                NSLog("date1 before date2");
                result = true
                setObjectForKeyToPersistentStorrage("latestepisode", object: episodes[0].episodePubDate)
                NSLog("set new Episode to persistent storrage")
            } else
            {
                NSLog("Dates are equal");
                result = false
            }

        }else{
            NSLog("no episode downloaded yet")
            result = true
            
            setObjectForKeyToPersistentStorrage("latestepisode", object: episodes[0].episodePubDate)
        }
        NSLog("episode check done")
        completion(result)
    }
    
    
    
    func createLocalNotification(_ episode: Episode){
        let localNotification =  UILocalNotification()
        
        localNotification.alertBody = String.localizedStringWithFormat(
            NSLocalizedString("notification.alert", value: "%@ is available", comment: "for local notification"),
            episode.episodeTitle)
        
        localNotification.alertAction = NSLocalizedString("notification.action", value: "Details", comment: "for local notification")
        
        
        localNotification.soundName = "pushSound.m4a"
        
        
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
            UIApplication.shared.presentLocalNotificationNow(localNotification)
        }

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
        
        UIApplication.shared.presentLocalNotificationNow(localNotification)
    }
    
    
    @objc func refreshfeed()
    {
        NSLog("Feed refresh started")
        let now = Date()
        setObjectForKeyToPersistentStorrage("last feed refresh", object: now)
        let url = getObjectForKeyFromPodcastSettings("feedurl")  as! String
        
        checkFeedDateIsNew {
            (result: Bool) in
            if result {
                // the file on the server has been update, start downloading a new feed file
                self.downloadurl(url)
                NSLog("Downloading feed")
            }else{
                NSLog("server feed same date or older")
            }
        }
        NSLog("clean up")
        cleanUpSpace()
        self.tableView.reloadData()
    }
    
    
    
    func checkFeedDateIsNew(_ completion:(_ result: Bool) -> Void){
        var result:Bool
        var savedfeeddate = getObjectForKeyFromPersistentStorrage("lastfeedday")
        
        if savedfeeddate == nil {
            let urlpath = Bundle.main.path(forResource: "feed", ofType: "xml")
            
            
            do {
                let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: urlpath!) as NSDictionary?
                if let _attr = attr {
                    savedfeeddate = _attr.fileModificationDate();
                    
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        NSLog("oldfeed: \(String(describing: savedfeeddate)) (from Persistent Storrage)")
        
        
        
        // get the last modified date from the file on the server
        var date = getHeaderFromUrl(getObjectForKeyFromPodcastSettings("feedurl") as! String, headerfield: "Last-Modified")
        
        if date == "" {
            
            // if the server does not contain a Last-Modified header for the feed, the Date fiedl will be used. This might lead to double download of the feed as the Date is more often updated than the Last-Modified. Only if even the Date fields is empthy, it is assumed that the server not reachable
            date = getHeaderFromUrl(getObjectForKeyFromPodcastSettings("feedurl") as! String, headerfield: "Date")
        }
        
        
        if date != "" {
            let newfeeddate = dateStringToNSDate(date)
            NSLog("newfeed: \(String(describing: newfeeddate)) (Header from Server)")
            
            
            // compare it with the last saved date
            //ASYNC
            
            
             
            if savedfeeddate != nil {
                let compareResult = (savedfeeddate! as AnyObject).compare(newfeeddate!)
                
                print(compareResult)
                
                if compareResult == ComparisonResult.orderedDescending {
                    // usually the date on the server should never be younger than the date saved
                    result = false
                    NSLog("\(String(describing: savedfeeddate)) (saved date) is younger than \(String(describing: newfeeddate)) - nothing to do but strange")
                    if (self.refreshControl != nil){
                        DispatchQueue.main.async {
                            self.refreshControl!.endRefreshing()
                        }
                    }
                }else if compareResult == ComparisonResult.orderedAscending{
                    // this is the normal behaviour when the feed has been updated
                    result = true
                    NSLog("\(String(describing: savedfeeddate)) (saved date) is older than \(String(describing: newfeeddate)) - to refresh feed")
                }else{
                    // this is the part when there has been no change on the feed since last check
                    result = false
                    print("same date")
                    if (self.refreshControl != nil){
                        DispatchQueue.main.async {
                            self.refreshControl!.endRefreshing()
                        }
                    }
                }
            }else{
                result = true
                NSLog("no saved feed date - to refresh feed")
            }
        }else{
            result = false
            NSLog("ERROR NO DATE")
            showErrorMessage(NSLocalizedString("title.server.not.reachable", value:"Error",
                comment: "shown when refreshing feed"), message: NSLocalizedString("message.server.not.reachable", value:"Server not reachable",
                    comment: "shown when refreshing feed"), viewController: self)
            if (self.refreshControl != nil){
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                }
            }
        }
            
        
        
        completion(result)
    }
    
   
    
    
    var data: NSMutableData = NSMutableData()
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        eName = elementName
        // print("DidStartElement \(eName)")
        
        if elementName == "lastBuildDate" {
            lastfeeddate = String()
            
            
        } else if elementName == "item" {
            episodeTitle = String()
            episodeLink = String()
            episodeDuration = String()
            episodePubDate = String()
            episodeDescription = String()
            lastfeeddate = String()
            episodeImage = String()
            episodeChapters = [Chapter]()
            
            
        } else if elementName == "enclosure"{
            episodeUrl = attributeDict["url"]!
            if let size = Int(attributeDict["length"]!){
                episodeFilesize = size
            }
            
            
            
        }else if elementName == "itunes:image"{
            episodeImage = attributeDict["href"]!
            
        } else if elementName == "psc:chapter"{
            
            // Podlove Simple Chapters parsing
            
            let chapter: Chapter = Chapter()
            if let atttitle: NSString = attributeDict["start"] as NSString? {
                chapter.chapterStart = atttitle as String
            }
            if let atttitle: NSString = attributeDict["title"] as NSString? {
                chapter.chapterTitle = atttitle as String
            }
            if let atttitle: NSString = attributeDict["href"] as NSString? {
                chapter.chapterLink = atttitle as String
            }
            if let atttitle: NSString = attributeDict["image"] as NSString? {
                chapter.chapterImage = atttitle as String
            }
            episodeChapters.append(chapter)
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (!data.isEmpty) {
            if eName == "title" {
                episodeTitle += data
            } else if eName == "link" {
                episodeLink += data
            }else if eName == "itunes:duration" {
                episodeDuration += data
            }else if eName == "pubDate" {
                episodePubDate = data
            }else if eName == "lastBuildDate"{
                lastfeeddate += data
            }else if eName == "content:encoded"{ //might be different in different feeds
                episodeDescription += string // here I don't want the new line characters to be delted
            }
        }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        //  print("didEndElement \(elementName)")
        if elementName == "lastBuildDate"{
            let lastBuildDate = dateStringToNSDate(lastfeeddate)
            setObjectForKeyToPersistentStorrage("lastfeedday" as String, object: lastBuildDate!)
        } else if elementName == "item" {
            
            
            let episode: Episode = Episode()
            episode.episodeTitle = episodeTitle
            episode.episodeUrl = episodeUrl
            episode.episodeLink = episodeLink
            
            
            
            
            // BUG BUG BUG
            episode.episodeDuration = episodeDuration
            //here I should take care that the duration within the feed is sometimes not correct and the duration within the feed can be 0 or even not existing at all
            if let publicationdate = dateStringToNSDate(episodePubDate){
                episode.episodePubDate = publicationdate
            }else{
                episode.episodePubDate = Date()
            }
            if let url: URL = URL(string: episodeUrl){
                episode.episodeFilename = url.lastPathComponent
            }
            episode.episodeFilesize = episodeFilesize
            
            episode.episodeChapter = episodeChapters
            episode.episodeDescription = episodeDescription
            if episodeImage != "" {
                episode.episodeImage = episodeImage
            }
            
            
            episode.episodeIndex = episodes.count
            episodes.append(episode)
//            dump(episode)
        }else if elementName == "channel"{
            print("end of feed")
            
        }
    }
    func parserDidEndDocument(_ parser: XMLParser) {
        SingletonClass.sharedInstance.numberofepisodes = episodes.count
        print("Parser DID End Document")
        var NotificationFired = false
        self.checkifepisodeisnew{
            (result: Bool) in
            if result == true{
                setObjectForKeyToPersistentStorrage("latestepisode", object: self.episodes[0].episodePubDate)
                if NotificationFired == false {
                    NSLog("checking if episode new should be done")
                    if existsLocally(self.episodes[0].episodeUrl).existlocal == false {
                        
                        self.createLocalNotification(self.episodes[0])
                        NotificationFired = true
                        self.autodownload(self.episodes[0])
                    }
                }
            }
        }
        
    }
    
    
    func autodownload(_ episode: Episode){
        
        // this function shall decided if the eposide will be downloaded automatically based on the Intenet connection (WiFi only) and if it has been already been played
        if episode.getDurationInSeconds() != 0.0{
            let remain = Float(CMTimeGetSeconds(episode.remaining()))
            if remain > 0{
                switch status {
                case .unknown, .offline:
                    print("Not connected")
                case .online(.wwan):
                    print("Connected via WWAN")
                case .online(.wiFi):
                    print("Connected via WiFi")
                    self.startDownloadepisode(episode)
                }
            }
        }
        
        //self.startDownloadepisode(episode)
        
    }
    
    /**************************************************************************
     
     ALL THE TABLE VIEW FUNCTIONS FOLLOWING
     (defining the table view and cells)
     
     **************************************************************************/
    
    
    
    
    // Table view parts
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isFiltering() {
            return filtered.count
        }
        
        return episodes.count
        
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as! EpisodeCell
            
        var episode: Episode = episodes[indexPath.row]
        if isFiltering() {
            episode = filtered[indexPath.row]
        }
        
        
        cell.episode = episode
        cell.layoutMargins = UIEdgeInsets.zero
        
        cell.backgroundColor = getColorFromPodcastSettings("backgroundColor")
        
        if let label = cell.EpisodeNameLabel {
            label.text = episode.episodeTitle
            label.textColor = getColorFromPodcastSettings("textcolor")
        }
        
        if SingletonClass.sharedInstance.episodePlaying.episodeTitle == episode.episodeTitle {
            if SingletonClass.sharedInstance.player.rate == 0{
                cell.EpisodePlayButton.setImage(createPlayImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSize(width: 44, height: 44), filled: true), for: UIControl.State())
            }else{
                cell.EpisodePlayButton.setImage(createPauseImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSize(width: 44, height: 44), filled: true), for: UIControl.State())
            }
            cell.EpisodePlayButton.isEnabled = true
            cell.EpisodePlayButton.isHidden = false
        }else{
            cell.EpisodePlayButton.isEnabled = false
            cell.EpisodePlayButton.isHidden = true
        }
        
        cell.delegate = self
        
        
        
        cell.EpisodePauseButton.titleLabel?.text = ""
        
        if let download = self.activeDownloads[episode.episodeUrl] {
            
            if (download.isDownloading) {
                cell.EpisodePauseButton.titleLabel?.text = ""
                
                cell.EpisodePauseButton.setImage(downloadPause, for: UIControl.State())
                
            }else{
                cell.EpisodePauseButton.setImage(downloadImage, for: UIControl.State())
            }
        }
        
        cell.EpisodeCancelButton.setImage(downloadCancel, for: UIControl.State())
        
        
        
        
        // moving the image creating to another thread to make the scolling more smooth
        
        //DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            
            let episodePicture: UIImage? = getEpisodeImage(episode, size: CGSize(width: cell.EpisodeImage.frame.size.height, height: cell.EpisodeImage.frame.size.width))
            if (episodePicture) != nil {
                DispatchQueue.main.async(execute: {
                    cell.EpisodeImage.image = episodePicture
                    
                })
            }
       // })
        
        
        // hide and show the Download controlls
        let existence = existsLocally(episode.episodeUrl)
        
        if (existence.existlocal){
            cell.EpisodeDownloadProgressbar.progress = 1
            cell.EpisodeDownloadProgressbar.isHidden = true
            cell.EpisodeDownloadButton!.setTitle("", for: UIControl.State())
            cell.EpisodeDownloadButton!.isHidden = true
            cell.EpisodeDownloadButton!.isEnabled = false
            cell.EpisodeCancelButton!.isHidden = true
            cell.EpisodePauseButton!.isHidden = true
            
        }else{
            var showDownloadControls = false
            if let download = activeDownloads[episode.episodeUrl] {
                showDownloadControls = true
                cell.EpisodeDownloadProgressbar.progress = download.progress
            }else{
                cell.EpisodeDownloadProgressbar.progress = 0
            }
            
            cell.EpisodeDownloadProgressbar.isHidden = !showDownloadControls
            cell.EpisodeDownloadButton!.setTitle("", for: UIControl.State())
            
            switch status {
            case .offline:
                cell.EpisodeDownloadButton!.isEnabled = false
            default:
                cell.EpisodeDownloadButton!.isEnabled = !showDownloadControls
            }
            
            cell.EpisodeDownloadButton!.setImage(downloadImage, for: UIControl.State())
            cell.EpisodeDownloadButton!.isHidden = showDownloadControls
            cell.EpisodePauseButton.isHidden = !showDownloadControls
            cell.EpisodeCancelButton.isHidden = !showDownloadControls
        }
        
        
        
        
        
        
        cell.filltableviewcell(episode)
        
        
        
        return cell
        
    }
    /*
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       
        if let thecell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as? EpisodeCell
        {
            thecell.EpisodeImage.image = nil
        }
    }
    */
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if episodes.count >= indexPath.row{
            var episode: Episode = episodes[indexPath.row]
            if isFiltering() {
                episode = filtered[indexPath.row]
            }
        // NSLog(episode.episodeTitle)
            let existence = existsLocally(episode.episodeUrl)
        
            if (existence.existlocal){
            
                return true
            }
        }
        return false
        
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        var episode: Episode = episodes[indexPath.row]
        if isFiltering() {
            episode = filtered[indexPath.row]
        }
        if (editingStyle == UITableViewCell.EditingStyle.delete){
            episode.deleteEpisodeFromDocumentsFolder()
            let indexPath2 = IndexPath(row: indexPath.row, section: 0)
            self.tableView.reloadRows(at: [indexPath2], with: UITableView.RowAnimation.none)
        }
    }
    

    
    func updateCellForEpisode(_ episode: Episode){
        let cellRowToBeUpdated = episode.episodeIndex
        
        let indexPath = IndexPath(row: cellRowToBeUpdated, section: 0)
        if self.tableView.cellForRow(at: indexPath) != nil {
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        
    }
    
    
    
    @objc func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                NSLog("long press on \(indexPath)")
                // your code here, get the row for the indexPath or do whatever you want
            }
        }
    }
    
    
    /**************************************************************************
     
     ALL THE DOWNLOAD FUNCTIONS FOLLOWING
     (used for downloading feed, coverimages and media files)
     [should be taken out of the viewController one day]
     
     **************************************************************************/
    
    
    
    
    func startDownloadepisode(_ episode: Episode) {
        if let url = activeDownloads[episode.episodeUrl] {
            print("\(url) already downloading")
            
        }else if existsLocally(episode.episodeUrl).existlocal{
            print("\(episode.episodeUrl) is already locally available")
        }else{
            if let url =  URL(string: episode.episodeUrl) {
                let download = Download(url: episode.episodeUrl)
                download.isEpisode  = true
                download.downloadTask = downloadsSession.downloadTask(with: url)
                download.downloadTask!.resume()
                download.isDownloading = true
                
                activeDownloads[download.url] = download
                print("started download of \(url)")
            }
        }
    }
    
    
    func pauseDownloadepisode(_ episode: Episode) {
        let urlString = episode.episodeUrl
        let download = activeDownloads[urlString]
        
        if(download!.isDownloading) {
            download!.downloadTask?.cancel { data in
                if data != nil {
                    download!.resumeData = data
                }
            }
            download!.isDownloading = false
        }
    }
    
    
    func resumeDownloadepisode(_ episode: Episode) {
        let urlString = episode.episodeUrl
        let download = activeDownloads[urlString]
        if let resumeData = download!.resumeData {
            download!.downloadTask = downloadsSession.downloadTask(withResumeData: resumeData)
            download!.downloadTask!.resume()
            download!.isDownloading = true
        } else if let url = URL(string: download!.url) {
            download!.downloadTask = downloadsSession.downloadTask(with: url)
            download!.downloadTask!.resume()
            download!.isDownloading = true
        }
        
    }
    
    func cancelDownloadepisode(_ episode: Episode) {
        let urlString = episode.episodeUrl
        let download = activeDownloads[urlString]
        download!.downloadTask?.cancel()
        activeDownloads[urlString] = nil
        
    }
    
    
    func downloadurl(_ urlstring: String) {
    
        NSLog("download request: \(urlstring)")
        if let url = activeDownloads[urlstring] {
            print("\(url) already downloading")
        }else if existsLocally(urlstring).existlocal{
            print("\(urlstring) is already locally available")
        }else{
            if let url =  URL(string: urlstring) {
                if url.host != "auphonic.com"{ //Auphonic exception for Trick17
                    let download = Download(url: urlstring)
                    download.isEpisode = false
                    download.downloadTask = downloadsSession.downloadTask(with: url)
                    download.downloadTask!.resume()
                    download.isDownloading = true
                    activeDownloads[download.url] = download
                }
            }
        }
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        //   NSLog("session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes.")
        
        //    print("TaskOrigRequest URL String \(downloadTask.originalRequest?.URL?.absoluteString)")
        if let downloadUrl = downloadTask.originalRequest?.url?.absoluteString,
            let download = activeDownloads[downloadUrl] {
            // 2
            download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
            DispatchQueue.main.async(execute: {
                if let episodeIndex = self.episodeIndexForDownloadTask(downloadTask), let episodeCell = self.tableView.cellForRow(at: IndexPath(row: episodeIndex, section: 0)) as? EpisodeCell {
                if (episodeCell.episode.episodeUrl == downloadUrl){
                    
                        episodeCell.updateDownloadProgress(download.progress)
                   
                }
                
            }
                 })
        }
    }
    
    
    
    
    
    // the following functin is called when a download has been finished. It will write the date to the right folder (Documents Folder - hint hint) and the tableviewcell if needed.
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // move the file to the final destination
        let destinationURL = localFilePathForUrl((downloadTask.originalRequest?.url)!)
        
        print("did finish download \(destinationURL)")
        
        // but clean the space before doing that.
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: destinationURL)
        } catch {
            NSLog("couldn't delete old file")
            // Non-fatal: file probably doesn't exist
        }
        do {
            try fileManager.copyItem(at: location, to: destinationURL)
            NSLog("moving feed from \(location) to \(destinationURL)")
            //  setObjectForKeyToPersistentStorrage("lastfeedday" as String, value: NSDate())
            do {
                try (destinationURL as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
                NSLog("\(destinationURL) excluded from backup")
            } catch _{
                NSLog("Failed to exclude from backup")
            }
            if (destinationURL.pathExtension.lowercased() == "xml"){
                let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: destinationURL.absoluteString) as NSDictionary?
                if let _attr = attr {
                    let fileSize = _attr.fileSize();
                    if fileSize > 1000 {
                        loadfeedandparse {
                            DispatchQueue.main.async(execute: {
                                self.tableView.reloadData()
                            })
                            cleanUpSpace()
                            DispatchQueue.main.async {
                            self.refreshControl!.endRefreshing()
                    }
                }
                }
                }
                
            }
        }catch let error as NSError {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
        
        // clear the download list
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            activeDownloads[url] = nil
            DispatchQueue.main.sync {
           
           
            // update the cell to update it that it has the file locally and only if it's a media file and not the feed
            if let episodeIndex = episodeIndexForDownloadTask(downloadTask), let episodeCell = tableView.cellForRow(at: IndexPath(row: episodeIndex, section: 0)) as? EpisodeCell {
                
//                DispatchQueue.main.async(execute: {
                    if (episodeCell.episode.episodeUrl == url){
                        episodeCell.EpisodeDownloadProgressbar.isHidden = true
                    }
                    
                    self.updateCellForEpisode(episodeCell.episode)
//                })
            }
                 }
        }
    }
    
    func localFilePathForUrl(_ originalUrl:URL)-> URL{
        
        var newUrl = originalUrl
        if originalUrl.pathExtension == "" {
            print("empty")
            newUrl = originalUrl.appendingPathComponent("feed.xml")
        }
        let fileName = newUrl.lastPathComponent
        let documentsDirectoryUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsDirectoryUrl!.appendingPathComponent(fileName)
        return destinationURL
    }
    
    
    
    
    
    
    
    
    
    
    // this function will get me the index of the array which should be the same as the index of the cell for the  episode containing the same episode as the download task
    
    
    func episodeIndexForDownloadTask(_ downloadTask: URLSessionDownloadTask) -> Int? {
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            
            for (index, episode) in episodes.enumerated() {
                if (url == episode.episodeUrl) || (url == episode.episodeImage) {
                    return index
                }
            }
        }
        return nil
    }
    
    
}

extension EpisodesTableViewController: URLSessionDownloadDelegate {
    func URLSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingToURLlocation: URL) {
        print("Finished downloading.")
    }
}


extension EpisodesTableViewController: EpisodeCellDelegate {
    func downloadepisode(_ cell: EpisodeCell){
        
        if let indexPath = tableView.indexPath(for: cell) {
            let episode = episodes[indexPath.row]
            startDownloadepisode(episode)
            
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }
    
    func pauseepisode(_ cell: EpisodeCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let episode = episodes[indexPath.row]
            pauseDownloadepisode(episode)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }
    
    func isdownloading(_ cell: EpisodeCell) -> Bool{
        var ret = false
        if let indexPath = tableView.indexPath(for: cell) {
            let episode = episodes[indexPath.row]
            let download = activeDownloads[episode.episodeUrl]
            ret = download!.isDownloading
        }else{
            ret = false
        }
        print(ret)
        return ret
    }
    
    func resumeepisode(_ cell: EpisodeCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let episode = episodes[indexPath.row]
            resumeDownloadepisode(episode)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }
    
    func cancelepisode(_ cell: EpisodeCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let episode = episodes[indexPath.row]
            cancelDownloadepisode(episode)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }
    
    //Search Functions
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filtered = episodes.filter({( episode : Episode) -> Bool in
            return (episode.episodeTitle.lowercased().contains(searchText.lowercased())) || (episode.episodeDescription.lowercased().contains(searchText.lowercased()))
        })
        
        tableView.reloadData()
    }
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
}

extension EpisodesTableViewController: URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                DispatchQueue.main.async(execute: {
                    completionHandler()
                })
            }
        }
        }
        
    }
}





extension EpisodesTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
