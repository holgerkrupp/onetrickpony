//
//  StocksCell.swift
//  OneTrickPony
//
//  Created by Holger Krupp on 17/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import UIKit
import Foundation

class EpisodeCell: UITableViewCell {
    
    
    
    
    @IBOutlet weak var EpisodeNameLabel: UILabel!
    @IBOutlet weak var EpisodeDateLabel: UILabel!
    @IBOutlet weak var EpisodeDurationLabel: UILabel!
    @IBOutlet weak var EpisodeFileSizeLabel: UILabel!
    @IBOutlet weak var EpisodeImage: UIImageView!
    @IBOutlet weak var EpisodeTime: UIProgressView!
    
    
    
    @IBOutlet weak var DownloadprogressLabel: UILabel!
    @IBOutlet weak var EpisodeDownloadButton: UIButton!
    
    
    var episode: Episode = Episode()
    
    @IBAction func download(){
     
        print("download button pressed")
        downloadepisode(episode)
       
    }
    
    func downloadepisode(episode : Episode){
        EpisodeDownloadButton!.setTitle("downloading", forState: UIControlState.Normal)
        EpisodesTableViewController().download(episode.episodeUrl)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func updateprogressbar(fileOffset: Int64){
        print(fileOffset)
    }
    
    func filltableviewcell(cell: EpisodeCell, episode: Episode){
        
        
        var date: NSDate = NSDate()
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        var dateString: String = String()
        
        
        // handover all episode information to the cell
        cell.episode = episode
        
        
        // fill basic fields
        cell.EpisodeNameLabel!.text = episode.episodeTitle
        
      //  cell.EpisodeDurationLabel!.text = episode.episodeDuration
        cell.EpisodeDurationLabel!.text = "\(secondsToHoursMinutesSeconds(remaining(episode))) remaining"
        dateString = episode.episodePubDate
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss ZZ"
        date = dateFormatter.dateFromString(dateString)!
        dateFormatter.dateFormat = "dd.MM.yy"
        dateString = dateFormatter.stringFromDate(date)
        cell.EpisodeDateLabel!.text = dateString
        let filesize: Double = Double(episode.episodeFilesize)/1024/1024
        cell.EpisodeFileSizeLabel!.text = String(format:"%.1f", filesize) + " MB"
        let remain = Float(readplayed(episode)) / Float(stringtodouble(episode.episodeDuration))
        
        cell.EpisodeTime.progress = remain
        //print(cell.EpisodeTime.progress)
        
        var existence = existslocally(episode.episodeUrl)
        // modify Download button to show either 'download' or 'play'
        if (existence.existlocal){
            episode.episodeLocal = true
            cell.EpisodeDownloadButton!.setTitle("Play", forState: UIControlState.Normal)
            cell.EpisodeDownloadButton!.setImage(UIImage(named: "iPhone"), forState: UIControlState.Normal)
            cell.EpisodeDownloadButton!.enabled = false
        }else{
            // just in case - should never been used - but acctually is used and I don't know why
            cell.EpisodeDownloadButton!.setTitle("Download", forState: UIControlState.Normal)
            cell.EpisodeDownloadButton!.setImage(UIImage(named: "Download from the Cloud"), forState: UIControlState.Normal)
            cell.EpisodeDownloadButton!.enabled = true
            episode.episodeLocal = false
        }
        // set Episode image if existing
        existence = existslocally(episode.episodeImage)
        if (existence.existlocal){
            cell.EpisodeImage.image = UIImage(named: existence.localURL)
        }else{
            cell.EpisodeImage.hidden = true
        }
        

        
        //check if the episode has been played and how far
        let playposition = readplayed(episode)
        //print("Episode \(episode.episodeTitle) played at position \(playposition) max duration is \(episode.episodeDuration)")
        

        
        
    }
    
}
