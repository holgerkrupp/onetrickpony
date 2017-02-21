//
//  SettingsTableViewController.swift
//  OneTrickPony_Podcaster
//
//  Created by Holger Krupp on 26/01/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    var settings: [String: Any] = ["Auto download new Episodes": true, "Delete after listening": true,]
    
    override func viewDidLoad() {
        super.viewDidLoad()
     //   NSLog(settings.count)
        self.navigationController!.isNavigationBarHidden = false;
    }
    
    


    
    
}
