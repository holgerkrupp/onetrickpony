//
//  Download.swift
//  DML
//
//  Created by Holger Krupp on 08/02/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation

class Download: NSObject {
    
    var url: String
    var isDownloading = false
    var progress: Float = 0.0
    var isEpisode = false
    
    var downloadTask: URLSessionDownloadTask?
    var resumeData: Data?
    
    init(url: String) {
        self.url = url
    }
}

