//
//  ChapterMarksViewController.swift
//  DML
//
//  Created by Holger Krupp on 21/02/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//


import UIKit



class ChapterMarksViewController: UITableViewController {
var Chapters      : [Chapter]!
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Chapters.count
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChapterCell", forIndexPath: indexPath)
        var chapter: Chapter = Chapter()
        chapter = Chapters[indexPath.row]
        cell.textLabel!.text = chapter.chapterTitle
        let chapterStartSeconds = stringtodouble(chapter.chapterStart)
        let chapterStartText = secondsToHoursMinutesSeconds(chapterStartSeconds)
        cell.detailTextLabel!.text = chapterStartText
        
        
        // prepare the future: Links for Chapters can be implemented here, but I just don't want to work on the WebView and stuff at the moment.
        /*
        if chapter.chapterLink != "" {
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
        }
        */
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var chapter: Chapter = Chapter()
        chapter = Chapters[indexPath.row]
        let chapterStartSeconds = stringtodouble(chapter.chapterStart)
        EpisodeViewController().jumpToTimeInPlayer(chapterStartSeconds)
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    
    
}
