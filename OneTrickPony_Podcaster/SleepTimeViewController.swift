//
//  SleepTimeViewController.swift
//  DML
//
//  Created by Holger Krupp on 11/02/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import UIKit

class SleepTimeViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print(indexPath)
        navigationController?.popViewControllerAnimated(true)

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("segue")
    }

}
