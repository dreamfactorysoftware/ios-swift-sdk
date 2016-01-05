//
//  ContactListViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class ContactListViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    // which group is being viewed
    var groupRecord: GroupRecord!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func prefetch() {
        
    }
    
    // blocks until the data has been fetched
    func waitToReady() {
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

}
