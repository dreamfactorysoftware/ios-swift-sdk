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
    
    private lazy var baseUrl: String = {
        return NSUserDefaults.standardUserDefaults().valueForKey(kBaseInstanceUrl) as! String
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showAdd()
        navBar.showBackButton(true)
        navBar.addButton.addTarget(self, action: "hitAddGroupButton", forControlEvents: .TouchDown)
        navBar.enableAllTouch()
        
        getAddressBookContentFromServer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.addButton.removeTarget(self, action: "hitAddGroupButton", forControlEvents: .TouchDown)
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
            removeContactGroupRelationWithGroupId(record.id)
            
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
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact_group"
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            
            api.restPath(restApiPath, method: "GET", queryParams: nil, body: nil, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error getting address book data: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                } else {
                    self.addressBookContentArray.removeAll()
                    let records = response!["resource"] as! JSONArray
                    for recordInfo in records {
                        let newRecord = GroupRecord(json: recordInfo)
                        self.addressBookContentArray.append(newRecord)
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    private func removeContactGroupRelationWithGroupId(groupId: NSNumber) {
        // remove all contact-group relations for the group being deleted
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact_group_relationship"
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            // create filter to select all contact_group_relationship records that
            // reference the group being deleted
            let queryParams: [String: AnyObject] = ["filter": "contact_group_id=\(groupId)"]
            
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            
            api.restPath(restApiPath, method: "DELETE", queryParams: queryParams, body: nil, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error removing contact group relation: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                } else {
                    // once the references to the group are removed, can remove group record
                    self.removeGroupFromServer(groupId)
                }
            })
        }
    }
    
    private func removeGroupFromServer(groupId: NSNumber) {
        // Get the relation all at once
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact_group"
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            // delete the record by the record ID
            // form is "ids":"1,2,3"
            let queryParams: [String: AnyObject] = ["ids": "\(groupId)"]
            
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            
            api.restPath(restApiPath, method: "DELETE", queryParams: queryParams, body: nil, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error deleting group: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                }
            })
        }
    }
    
    private func showContactListViewController() {
        dispatch_async(dispatch_queue_create("addressBookQueue", nil)) {
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
        dispatch_async(dispatch_queue_create("contactListShowQueue", nil)) {
            // already fetching so just wait until the data gets back
            groupAddViewController.waitToReady()
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationController?.pushViewController(groupAddViewController, animated: true)
            }
        }
    }
}
