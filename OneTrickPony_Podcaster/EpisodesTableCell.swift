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
    func isdownloading(cell: EpisodeCell) -> Bool
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
    @IBOutlet weak var EpisodePauseButton: UIButton!
    @IBOutlet weak var EpisodeCancelButton: UIButton!
    
    @IBAction func playButtonPressed(){
        if SingletonClass.sharedInstance.player.rate == 0 {
            SingletonClass.sharedInstance.player.play()
            EpisodePlayButton.setImage(createPauseImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSizeMake(30, 30), filled: true), forState: .Normal)
            EpisodePlayButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), forState: .Normal)

        }else{
            SingletonClass.sharedInstance.player.pause()
            EpisodePlayButton.setImage(createPlayImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSizeMake(30, 30), filled: true), forState: .Normal)
            EpisodePlayButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), forState: .Normal)

    }
    }
    var episode: Episode = Episode()
    
    @IBAction func downloadPressed(){
        delegate?.downloadepisode(self)
    }
    @IBAction func pauseOrResumePressed(){
        if (delegate?.isdownloading(self) == true) {
                delegate?.pauseepisode(self)
        } else {
                delegate?.resumeepisode(self)
        }
    }
    @IBAction func cancelPressed(){
        delegate?.cancelepisode(self)
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
       // NSLog(fileOffset)
    }
    
    func filltableviewcell(episode: Episode){
        
  

        if episode.getDurationInSeconds() != 0.0{
        var remain = Float(CMTimeGetSeconds(episode.remaining()))
        if remain <= 0{
            // the item has been played to the end
            remain = 0
            EpisodeDurationLabel!.text = NSLocalizedString("episode.finished",value: "Done playing", comment: "shown in TableView")
        }else{
            EpisodeDurationLabel!.text = String.localizedStringWithFormat(
                NSLocalizedString("string.for.time.remaining", value:"%@ remaining",
                    comment: "shown in TableView"),
                secondsToHoursMinutesSeconds(Double(remain)))
        }
        EpisodeTimeProgressbar.progress = 1-remain/Float(CMTimeGetSeconds(episode.getDurationinCMTime()))
        }else{
            EpisodeDurationLabel!.text = NSLocalizedString("episode.noduration",value: "Duration unknown", comment: "shown in TableView")
            EpisodeTimeProgressbar.progress = 0
        }
        EpisodeTimeProgressbar.backgroundColor = getColorFromPodcastSettings("progressBackgroundColor")
        EpisodeTimeProgressbar.progressTintColor = getColorFromPodcastSettings("highlightColor")
        
        EpisodeDurationLabel!.textColor = getColorFromPodcastSettings("secondarytextcolor")
        
        
        var date: NSDate = NSDate()
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        var dateString: String = String()
        
        date = episode.episodePubDate
     
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .NoStyle
        
        dateString = dateFormatter.stringFromDate(date)
        EpisodeDateLabel!.text = dateString
        
        EpisodeDateLabel!.textColor = getColorFromPodcastSettings("secondarytextcolor")
        
        
        let filesize: Double = Double(episode.episodeFilesize)/1024/1024
        EpisodeFileSizeLabel!.text = String.localizedStringWithFormat(
            NSLocalizedString("string.for.file.size", value:"%.1f MB",
                comment: "shown in TableView"),
            filesize)
        EpisodeFileSizeLabel!.textColor = getColorFromPodcastSettings("secondarytextcolor")
        EpisodeDownloadProgressbar.backgroundColor = getColorFromPodcastSettings("progressBackgroundColor")
        EpisodeDownloadProgressbar.progressTintColor = getColorFromPodcastSettings("highlightColor")
        EpisodeDownloadButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), forState: .Normal)
        EpisodePauseButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), forState: .Normal)
        EpisodeCancelButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), forState: .Normal)
        var existence = existsLocally(episode.episodeUrl)
        // modify Download button to show either 'download' or 'play'
        if (existence.existlocal){
            episode.episodeLocal = true
            EpisodeDownloadProgressbar.progress = 1
            EpisodeDownloadProgressbar.hidden = true
            EpisodeDownloadButton!.setTitle("Play", forState: UIControlState.Normal)
            EpisodeDownloadButton.hidden = true
            EpisodeDownloadButton!.enabled = false
        }else{
            // just in case - should never been used - but acctually is used and I don't know why
            EpisodeDownloadProgressbar.progress = 0
            EpisodeDownloadProgressbar.hidden = true

            EpisodeDownloadButton!.setTitle("", forState: UIControlState.Normal)
            EpisodeDownloadButton!.setImage(createCircleWithArrow(getColorFromPodcastSettings("playControlColor"),width:1, size: CGSizeMake(30, 30), filled: true), forState: .Normal)

            EpisodeDownloadButton!.enabled = true
            episode.episodeLocal = false
        }
        // set Episode image if existing
        EpisodeImage.image = getEpisodeImage(episode)


        
        
    }
    
}
