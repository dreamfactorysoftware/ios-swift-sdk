//
//  AddressBookViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class AddressBookViewController: UITableViewController {
    // list of groups
    var addressBookContentArray: [GroupRecord] = []
    
    // for prefetching data
    var contactListViewController: ContactListViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showAdd()
        navBar.showBackButton(true)
        navBar.addButton.addTarget(self, action: #selector(hitAddGroupButton), forControlEvents: .TouchDown)
        navBar.enableAllTouch()
        
        getAddressBookContentFromServer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.addButton.removeTarget(self, action: #selector(hitAddGroupButton), forControlEvents: .TouchDown)
    }
    
    func hitAddGroupButton() {
        showGroupAddViewController()
    }
    
    //MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addressBookContentArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("addressBookTableViewCell", forIndexPath: indexPath)
        
        let record = addressBookContentArray[indexPath.row]
        cell.textLabel?.text = record.name
        
        return cell
    }
    
    //MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // allow swipe to delete
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let record = addressBookContentArray[indexPath.row]
            
            // can not delete group until all references to it are removed
            // remove relations -> remove group
            // pass record ID so it knows what group we are removing
            removeGroupFromServer(record.id)
            
            addressBookContentArray.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let record = addressBookContentArray[indexPath.row]
        
        contactListViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ContactListViewController") as! ContactListViewController
        contactListViewController.groupRecord = record
        contactListViewController.prefetch()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        showContactListViewController()
    }
    
    //MARK: - Private functions
    
    private func getAddressBookContentFromServer() {
        // get all the groups
        RESTEngine.sharedEngine.getAddressBookContentFromServerWithSuccess({ response in
            self.addressBookContentArray.removeAll()
            let records = response!["resource"] as! JSONArray
            for recordInfo in records {
                let newRecord = GroupRecord(json: recordInfo)
                self.addressBookContentArray.append(newRecord)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
            }, failure: { error in
                NSLog("Error getting address book data: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func removeGroupFromServer(groupId: NSNumber) {
        RESTEngine.sharedEngine.removeGroupFromServerWithGroupId(groupId, success: nil, failure: { error in
            NSLog("Error deleting group: \(error)")
            dispatch_async(dispatch_get_main_queue()) {
                Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        })
    }
    
    private func showContactListViewController() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // already fetching so just wait until the data gets back
            self.contactListViewController.waitToReady()
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationController?.pushViewController(self.contactListViewController, animated: true)
            }
        }
    }
    
    private func showGroupAddViewController() {
        let groupAddViewController = self.storyboard?.instantiateViewControllerWithIdentifier("GroupAddViewController") as! GroupAddViewController
        // tell the viewController we are creating a new group
        groupAddViewController.prefetch()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // already fetching so just wait until the data gets back
            groupAddViewController.waitToReady()
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationController?.pushViewController(groupAddViewController, animated: true)
            }
        }
    }
}
