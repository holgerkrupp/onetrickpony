//
//  StocksCell.swift
//  OneTrickPony
//
//  Created by Holger Krupp on 17/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import UIKit
import Foundation
import CoreMedia



protocol EpisodeCellDelegate {
    func pauseepisode(cell: EpisodeCell)
    func resumeepisode(cell: EpisodeCell)
    func cancelepisode(cell: EpisodeCell)
    func downloadepisode(cell: EpisodeCell)
}


class EpisodeCell: UITableViewCell {
    
    
    var delegate: EpisodeCellDelegate?

    
    @IBOutlet weak var EpisodeNameLabel: UILabel!
    @IBOutlet weak var EpisodeDateLabel: UILabel!
    @IBOutlet weak var EpisodeDurationLabel: UILabel!
    @IBOutlet weak var EpisodeFileSizeLabel: UILabel!
    @IBOutlet weak var EpisodeImage: UIImageView!
    @IBOutlet weak var EpisodeTime: UIProgressView!
    @IBOutlet weak var Episodeprogressbar: UIProgressView!

    
    @IBOutlet weak var EpisodeDownloadButton: UIButton!
    
    
    var episode: Episode = Episode()
    
    @IBAction func download(){
        print("download button pressed")
        delegate?.downloadepisode(self)
       
    }
    
    func downloadepisode(episode : Episode){
        EpisodeDownloadButton!.setTitle("downloading", forState: UIControlState.Normal)
        Episodeprogressbar.hidden = false
        delegate?.downloadepisode(self)
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
        
  
        // handover all episode information to the cell
        cell.episode = episode
        
        
        // fill basic fields
        if let label = cell.EpisodeNameLabel {
            label.text = episode.episodeTitle
        }
        
      //  cell.EpisodeDurationLabel!.text = episode.episodeDuration
        
        cell.EpisodeDurationLabel!.text = "\(secondsToHoursMinutesSeconds(Double(CMTimeGetSeconds(episode.remaining())))) remaining"
        
        
        var date: NSDate = NSDate()
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        var dateString: String = String()
        
        dateString = episode.episodePubDate
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss ZZ"
        date = dateFormatter.dateFromString(dateString)!
        dateFormatter.dateFormat = "dd.MM.yy"
        dateString = dateFormatter.stringFromDate(date)
        cell.EpisodeDateLabel!.text = dateString
        
        
        
        let filesize: Double = Double(episode.episodeFilesize)/1024/1024
        cell.EpisodeFileSizeLabel!.text = String(format:"%.1f", filesize) + " MB"
        let remain = Float(CMTimeGetSeconds(episode.remaining()))
        
        cell.EpisodeTime.progress = remain
        //print(cell.EpisodeTime.progress)
        
        var existence = existslocally(episode.episodeUrl)
        // modify Download button to show either 'download' or 'play'
        if (existence.existlocal){
            episode.episodeLocal = true
            cell.Episodeprogressbar.progress = 1
            cell.Episodeprogressbar.hidden = true
         //   cell.EpisodeprogressLabel.hidden = true
            cell.EpisodeDownloadButton!.setTitle("Play", forState: UIControlState.Normal)
            cell.EpisodeDownloadButton!.setImage(UIImage(named: "iPhone"), forState: UIControlState.Normal)
            cell.EpisodeDownloadButton!.enabled = false
        }else{
            // just in case - should never been used - but acctually is used and I don't know why
            cell.Episodeprogressbar.progress = 0
            cell.Episodeprogressbar.hidden = true
       //     cell.EpisodeprogressLabel.hidden = true
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
        
        print("redraw cell \(episode.episodeTitle)")
        
        //check if the episode has been played and how far
     //   let playposition = readplayed(episode)
        //print("Episode \(episode.episodeTitle) played at position \(playposition) max duration is \(episode.episodeDuration)")
        

        
        
    }
    
}
