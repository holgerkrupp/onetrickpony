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
    func pauseepisode(_ cell: EpisodeCell)
    func resumeepisode(_ cell: EpisodeCell)
    func cancelepisode(_ cell: EpisodeCell)
    func downloadepisode(_ cell: EpisodeCell)
    func isdownloading(_ cell: EpisodeCell) -> Bool
}


class EpisodeCell: UITableViewCell {
    
    
    var delegate: EpisodeCellDelegate?
    let status = Reach().connectionStatus()
    
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
            EpisodePlayButton.setImage(createPauseImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSize(width: 30, height: 30), filled: true), for: UIControl.State())
            EpisodePlayButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), for: UIControl.State())

        }else{
            SingletonClass.sharedInstance.player.pause()
            EpisodePlayButton.setImage(createPlayImageWithColor(getColorFromPodcastSettings("playControlColor"),size: CGSize(width: 30, height: 30), filled: true), for: UIControl.State())
            EpisodePlayButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), for: UIControl.State())

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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func updateprogressbar(_ fileOffset: Int64){
       // NSLog(fileOffset)
    }
    
    func updateProgress(_ episode: Episode){
        if episode.getDurationInSeconds() != 0.0{
            var remain = Float(CMTimeGetSeconds(episode.remaining()))
            if remain <= 0{
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
    }
    
    func updateDownloadProgress(_ progress: Float){
        EpisodeDownloadProgressbar.progress = progress
        if progress > 0.0 && progress < 1{
            EpisodeDownloadProgressbar.isHidden = false
        }else{
            EpisodeDownloadProgressbar.isHidden = true
        }
    }
    

    
    
    func filltableviewcell(_ episode: Episode){

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
            let duration = episode.getDurationinCMTime()
         EpisodeTimeProgressbar.progress = 1-remain/Float(CMTimeGetSeconds(duration))
        }else{
            EpisodeDurationLabel!.text = NSLocalizedString("episode.noduration",value: "Duration unknown", comment: "shown in TableView")
            EpisodeTimeProgressbar.progress = 0
        }
        EpisodeTimeProgressbar.backgroundColor = getColorFromPodcastSettings("progressBackgroundColor")
        EpisodeTimeProgressbar.progressTintColor = getColorFromPodcastSettings("highlightColor")
        
        EpisodeDurationLabel!.textColor = getColorFromPodcastSettings("secondarytextcolor")
        
        
        var date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        var dateString: String = String()
        
        date = episode.episodePubDate as Date
     
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        dateString = dateFormatter.string(from: date)
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
        EpisodeDownloadButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), for: UIControl.State())
        EpisodePauseButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), for: UIControl.State())
        EpisodeCancelButton.setTitleColor(getColorFromPodcastSettings("playControlColor"), for: UIControl.State())
   
        
        
    }
    
}
