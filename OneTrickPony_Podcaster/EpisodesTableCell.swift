//
//  
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
    @IBOutlet weak var EpisodeTimeProgressbar: UIProgressView!
    @IBOutlet weak var EpisodeDownloadProgressbar: UIProgressView!
    
    @IBOutlet weak var EpisodePlayButton: UIButton!
    
    @IBOutlet weak var EpisodeDownloadButton: UIButton!
    
    @IBAction func playButtonPressed(){
        if SingletonClass.sharedInstance.player.rate == 0 {
            SingletonClass.sharedInstance.player.play()
            EpisodePlayButton.setImage(UIImage(named: "Pause filled"), forState: UIControlState.Normal)
        }else{
            SingletonClass.sharedInstance.player.pause()
            EpisodePlayButton.setImage(UIImage(named: "Play filled"), forState: UIControlState.Normal)
    }
    }
    var episode: Episode = Episode()
    
    @IBAction func download(){
        print("download button pressed")
        delegate?.downloadepisode(self)
       
    }
    
    func downloadepisode(episode : Episode){
        EpisodeDownloadButton!.setTitle("downloading", forState: UIControlState.Normal)
        EpisodeDownloadProgressbar.hidden = false
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
    
    func filltableviewcell(episode: Episode){
        
  

        if episode.getDurationInSeconds() != 0.0{
        var remain = Float(CMTimeGetSeconds(episode.remaining()))
        if remain <= 0{
            // the item has been played to the end
            remain = 0
            EpisodeDurationLabel!.text = "Done playing"
        }else{
            EpisodeDurationLabel!.text = "\(secondsToHoursMinutesSeconds(Double(remain))) remaining"
        }
        EpisodeTimeProgressbar.progress = 1-remain/Float(CMTimeGetSeconds(episode.getDurationinCMTime()))
        }else{
            EpisodeDurationLabel!.text = "Duration unknown"
            EpisodeTimeProgressbar.progress = 0
        }
        
        
        var date: NSDate = NSDate()
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        var dateString: String = String()
        
        dateString = episode.episodePubDate
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss ZZ"
        date = dateFormatter.dateFromString(dateString)!
        dateFormatter.dateFormat = "dd.MM.yy"
        dateString = dateFormatter.stringFromDate(date)
        EpisodeDateLabel!.text = dateString
        
        
        
        let filesize: Double = Double(episode.episodeFilesize)/1024/1024
        EpisodeFileSizeLabel!.text = String(format:"%.1f", filesize) + " MB"

        //print(EpisodeTimeProgressbar.progress)
        
        var existence = existslocally(episode.episodeUrl)
        // modify Download button to show either 'download' or 'play'
        if (existence.existlocal){
            episode.episodeLocal = true
            EpisodeDownloadProgressbar.progress = 1
            EpisodeDownloadProgressbar.hidden = true
         //   EpisodeprogressLabel.hidden = true
            EpisodeDownloadButton!.setTitle("Play", forState: UIControlState.Normal)
            EpisodeDownloadButton!.setImage(UIImage(named: "iPhone"), forState: UIControlState.Normal)
            EpisodeDownloadButton!.enabled = false
        }else{
            // just in case - should never been used - but acctually is used and I don't know why
            EpisodeDownloadProgressbar.progress = 0
            EpisodeDownloadProgressbar.hidden = true
       //     EpisodeprogressLabel.hidden = true
            EpisodeDownloadButton!.setTitle("Download", forState: UIControlState.Normal)
            EpisodeDownloadButton!.setImage(UIImage(named: "Download from the Cloud"), forState: UIControlState.Normal)
            EpisodeDownloadButton!.enabled = true
            episode.episodeLocal = false
        }
        // set Episode image if existing
        existence = existslocally(episode.episodeImage)
        if (existence.existlocal){
            EpisodeImage.image = UIImage(named: existence.localURL)
        }else{
            EpisodeImage.hidden = true
        }
        
        
        
        //check if the episode has been played and how far
     //   let playposition = readplayed(episode)
        //print("Episode \(episode.episodeTitle) played at position \(playposition) max duration is \(episode.episodeDuration)")
        

        
        
    }
    
}
