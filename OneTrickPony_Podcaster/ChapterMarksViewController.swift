//
//  ChapterMarksViewController.swift
//  DML
//
//  Created by Holger Krupp on 21/02/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//


import UIKit
import AVFoundation


protocol ChapterMarksViewControllerDelegate {
    var episode: Episode { get }
    func jumpToTimeInPlayer(_ seconds:Double)
    
}

class ChapterMarksViewController: UITableViewController {
var Chapters      : [Chapter]!
    
var EpisodeViewController: ChapterMarksViewControllerDelegate?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Chapters.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterCell", for: indexPath)
        var chapter: Chapter = Chapter()
        chapter = Chapters[indexPath.row]
        cell.textLabel!.text = chapter.chapterTitle
        let chapterStartSeconds = stringtodouble(chapter.chapterStart)
        let chapterStartText = secondsToHoursMinutesSeconds(chapterStartSeconds)
        cell.detailTextLabel!.text = chapterStartText
        cell.accessoryType = UITableViewCell.AccessoryType.none
        
        let episode = EpisodeViewController?.episode
        
        let currentplaytime = Float(CMTimeGetSeconds(episode!.readplayed()))
        if let playingChapter = episode!.getChapterForSeconds(Double(currentplaytime)){
            if chapter.chapterTitle == playingChapter.chapterTitle{
                cell.accessoryType = UITableViewCell.AccessoryType.checkmark
            }
        }
        
        
        // prepare the future: Links for Chapters can be implemented here, but I just don't want to work on the WebView and stuff at the moment.
        /*
        if chapter.chapterLink != "" {
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
        }
        */
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var chapter: Chapter = Chapter()
        chapter = Chapters[indexPath.row]
        let chapterStartSeconds = stringtodouble(chapter.chapterStart)

        EpisodeViewController?.jumpToTimeInPlayer(chapterStartSeconds)

        self.dismiss(animated: true, completion: nil)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
       // EpisodeViewController().play()
       // EpisodeViewController().updateplayprogress()
    }
    

    
    
}
