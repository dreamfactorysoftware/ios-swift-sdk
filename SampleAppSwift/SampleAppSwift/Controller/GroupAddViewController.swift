//
//  GroupAddViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class GroupAddViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate {
    @IBOutlet weak var groupAddTableView: UITableView!
    @IBOutlet weak var groupNameTextField: UITextField!
    
    // set groupRecord and contacts alreadyInGroup when editing an existing group
    // contacts already in the existing group
    var contactsAlreadyInGroupContentsArray: [NSNumber]!
    // record of the group being edited
    var groupRecord: GroupRecord?
    
    private var searchBar: UISearchBar!
    
    // if there is a search going on
    private var isSearch = false
    
    // holds contents of a search
    private var displayContentArray: [ContactRecord]!
    
    // array of contacts selected to be in the group
    private var selectedRows: [NSNumber]!
    
    // contacts broken into groups by first letter of last name
    private var contactSectionsDictionary: [String: [ContactRecord]]!
    
    // header letters
    private var alphabetArray: [String]!
    
    private var waitLock: NSCondition!
    private var waitReady = false
    
    private lazy var baseUrl: String = {
        return NSUserDefaults.standardUserDefaults().valueForKey(kBaseInstanceUrl) as! String
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupNameTextField.delegate = self
        groupNameTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        
        // set up the search bar programmatically
        searchBar = UISearchBar(frame: CGRectMake(0, 118, view.frame.size.width, 44))
        searchBar.delegate = self
        self.view.addSubview(searchBar)
        searchBar.setNeedsDisplay()
        self.view.reloadInputViews()
        
        if let groupRecord = groupRecord {
            // if we are editing a group, get any existing group members
            groupNameTextField.text = groupRecord.name
        }
        // remove header from table view
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showDone()
        navBar.doneButton.addTarget(self, action: "onDoneButtonClick", forControlEvents: .TouchDown)
        navBar.enableAllTouch()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.doneButton.removeTarget(self, action: "onDoneButtonClick", forControlEvents: .TouchDown)
        navBar.disableAllTouch()
    }
    
    func onDoneButtonClick() {
        if groupNameTextField.text?.characters.count == 0 {
            let alert = UIAlertController(title: nil, message: "Please enter a group name", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "ok", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if groupRecord != nil {
            // if we are editing a group, head to update
            buildUpdateRequest()
        } else {
            addNewGroupToServer()
        }
    }
    
    func prefetch() {
        displayContentArray = []
        contactsAlreadyInGroupContentsArray = []
        selectedRows = []
        
        // for sectioned alphabetized list
        alphabetArray = []
        contactSectionsDictionary = [:]
        
        waitLock = NSCondition()
        waitLock.lock()
        waitReady = false
        
        dispatch_async(dispatch_queue_create("contactListQueue", nil)) {
            self.getContactListFromServer()
            if self.groupRecord != nil {
                // if we are editing a group, get any existing group members
                self.getContactGroupRelationListFromServer()
            }
        }
        self.navBar.disableAllTouch()
    }
    
    func waitToReady() {
        dispatch_async(dispatch_queue_create("groupAddWaitQueue", nil)) {
            self.waitLock.lock()
            while !self.waitReady {
                self.waitLock.wait()
            }
            self.waitLock.unlock()
        }
    }
    
    //MARK: - Text field delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: - Search bar delegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        displayContentArray.removeAll()
        
        if searchText.isEmpty {
            // done with searching, show all the data
            isSearch = false
            groupAddTableView.reloadData()
            return
        }
        isSearch = true
        let firstLetter = searchText.substringToIndex(searchText.startIndex.advancedBy(1)).uppercaseString
        let arrayAtLetter = contactSectionsDictionary[firstLetter]
        if let arrayAtLetter = arrayAtLetter {
            for record in arrayAtLetter {
                if record.lastName.characters.count < searchText.characters.count {
                    continue
                }
                let lastNameSubstring = record.lastName.substringToIndex(record.lastName.startIndex.advancedBy(searchText.characters.count))
                if lastNameSubstring.caseInsensitiveCompare(searchText) == .OrderedSame {
                    displayContentArray.append(record)
                }
            }
            groupAddTableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if isSearch {
            return 1
        }
        return alphabetArray.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearch {
            return displayContentArray.count
        }
        let sectionContacts = contactSectionsDictionary[alphabetArray[section]]!
        return sectionContacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("addGroupContactTableViewCell", forIndexPath: indexPath)
        
        var record: ContactRecord!
        if isSearch {
            record = displayContentArray[indexPath.row]
        } else {
            let sectionContacts = contactSectionsDictionary[alphabetArray[indexPath.section]]!
            record = sectionContacts[indexPath.row]
        }
        
        cell.textLabel?.text = record.fullName
        
        // if the contact is selected to be in the group, mark it
        if selectedRows.contains(record.id) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    //MARK: - Table view delegate
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearch {
            let searchText = searchBar.text
            if searchText?.characters.count > 0 {
                return searchText!.substringToIndex(searchText!.startIndex.advancedBy(1)).uppercaseString
            }
        }
        return alphabetArray[section]
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red: 210/255.0, green: 225/255.0, blue: 239/255.0, alpha: 1.0)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        var contact: ContactRecord!
        
        if isSearch {
            contact = displayContentArray[indexPath.row]
        } else {
            let sectionContacts = contactSectionsDictionary[alphabetArray[indexPath.section]]!
            contact = sectionContacts[indexPath.row]
        }
        
        if cell.accessoryType == .None {
            cell.accessoryType = .Checkmark
            selectedRows.append(contact.id)
        } else {
            cell.accessoryType = .None
            selectedRows.removeObject(contact.id)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Private methods
    
    private func buildUpdateRequest() {
        // if a contact is selected and was already in the group, do nothing
        // if a contact is selected and was not in the group, add it to the group
        // if a contact is not selected and was in the group, remove it from the group
        
        // removing an object mid loop messes with for-each loop
        var toRemove: [NSNumber] = []
        for contactId in selectedRows {
            for i in 0..<contactsAlreadyInGroupContentsArray.count {
                if contactId.isEqualToNumber(contactsAlreadyInGroupContentsArray[i]) {
                    toRemove.append(contactId)
                    self.contactsAlreadyInGroupContentsArray!.removeAtIndex(i)
                    break
                }
            }
        }
        
        for contactId in toRemove {
            selectedRows.removeObject(contactId)
        }
        
        // remove all the contacts that were in the groups and are not now
        // remove contacts from group -> add contacts to group
        updateGroupNameWithServer()
    }
    
    private func getContactListFromServer() {
        // get all the contacts in the database
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact" // table name
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            // only need to get the contactId and full contact name
            // set the fields param to give us just the fields we need
            let queryParams: [String: AnyObject] = ["fields": "id,first_name,last_name"]
            
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            
            api.restPath(restApiPath, method: "GET", queryParams: queryParams, body: nil, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error getting all the contacts data: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                } else {
                    // put the contact ids into an array
                    let records = response!["resource"] as! JSONArray
                    for recordInfo in records {
                        let newRecord = ContactRecord(json: recordInfo)
                        
                        if !newRecord.lastName.isEmpty {
                            var found = false
                            for key in self.contactSectionsDictionary.keys {
                                // want to group by last name regardless of case
                                if key.caseInsensitiveCompare(newRecord.lastName.substringToIndex(newRecord.lastName.startIndex.advancedBy(1))) == .OrderedSame {
                                    var section = self.contactSectionsDictionary[key]!
                                    section.append(newRecord)
                                    self.contactSectionsDictionary[key] = section
                                    found = true
                                    break
                                }
                            }
                            
                            if !found {
                                // contact doesn't fit in any of the other buckets, make a new one
                                let key = newRecord.lastName.substringToIndex(newRecord.lastName.startIndex.advancedBy(1))
                                self.contactSectionsDictionary[key] = [newRecord]
                            }
                        }
                    }
                    
                    var tmp: [String: [ContactRecord]] = [:]
                    // sort the sections alphabetically by last name, first name
                    for key in self.contactSectionsDictionary.keys {
                        let unsorted = self.contactSectionsDictionary[key]!
                        let sorted = unsorted.sort({ (one, two) -> Bool in
                            if one.lastName.caseInsensitiveCompare(two.lastName) == .OrderedSame {
                                return one.firstName.compare(two.firstName) == NSComparisonResult.OrderedAscending
                            }
                            return one.lastName.compare(two.lastName) == NSComparisonResult.OrderedAscending
                        })
                        tmp[key] = sorted
                    }
                    self.contactSectionsDictionary = tmp
                    self.alphabetArray = Array(self.contactSectionsDictionary.keys).sort()
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.waitReady = true
                        self.waitLock.signal()
                        self.waitLock.unlock()
                        
                        self.groupAddTableView.reloadData()
                    }
                }
            })
        }
    }
    
    private func addNewGroupToServer() {
        // created a new group, add it to the server
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact_group" // table name
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            // build request body, just need to post the name
            let requestBody: [String: AnyObject] = ["name": groupNameTextField.text!]
            
            // the DB success response will contain the id of the new record
            api.restPath(restApiPath, method: "POST", queryParams: nil, body: requestBody, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error adding group to server: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                } else {
                    // get the id of the new group, then add the relations
                    let records = response!["resource"] as! JSONArray
                    for recordInfo in records {
                        self.addGroupContactRelations(recordInfo["id"] as! NSNumber)
                    }
                }
            })
        }
    }
    
    private func addGroupContactRelations(groupId: NSNumber) {
        // create any new contact-group relations
        
        // make sure there are contacts to add
        if selectedRows.count == 0 {
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationController?.popViewControllerAnimated(true)
            }
            return
        }
        
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact_group_relationship" // table name
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            
            // build request body
            /*
            *  structure of request is:
            *  {
            *      "resource":[
            *          {
            *             "contact_group_id":id,
            *             "contact_id":id"
            *          },
            *          {...}
            *      ]
            *  }
            */
            var records: JSONArray = []
            for contactId in selectedRows {
                records.append(["contact_group_id": groupId,
                                "contact_id": contactId])
            }
            
            let requestBody: [String: AnyObject] = ["resource": records]
            
            api.restPath(restApiPath, method: "POST", queryParams: nil, body: requestBody, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error adding contact group relation to server from group add: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        // go to previous screen
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }
            })
        }
    }
    
    private func updateGroupNameWithServer() {
        // Update a changed group name with the server
        
        if groupNameTextField.text == groupRecord?.name {
            removeContactGroupRelationsFromServer()
            return
        }
        
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact_group"
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            let queryParams: JSON = ["ids": groupRecord!.id.stringValue]
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            
            let requestBody: [String: AnyObject] = ["name": groupNameTextField.text!]
            
            // update the contact
            groupRecord!.name = groupNameTextField.text!
            
            api.restPath(restApiPath, method: "PATCH", queryParams: queryParams, body: requestBody, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error updating contact info with server: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                } else {
                    self.removeContactGroupRelationsFromServer()
                }
            })
        }
    }
    
    private func getContactGroupRelationListFromServer() {
        // get the list of contacts already in the group
        
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact_group_relationship"
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            // create filter to get only the contact in the group
            let queryParams: JSON = ["filter": "contact_group_id=\(groupRecord!.id)"]
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            
            api.restPath(restApiPath, method: "GET", queryParams: queryParams, body: nil, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error getting contact group relations list: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                } else {
                    self.contactsAlreadyInGroupContentsArray.removeAll()
                    let records = response!["resource"] as! JSONArray
                    for recordInfo in records {
                        let contactId = recordInfo["contact_id"] as! NSNumber
                        self.contactsAlreadyInGroupContentsArray.append(contactId)
                        self.selectedRows.append(contactId)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.groupAddTableView.reloadData()
                    }
                }
            })
        }
    }
    
    private func removeContactGroupRelationsFromServer() {
        // make sure we should be removing contacts
        if groupRecord == nil || contactsAlreadyInGroupContentsArray.count == 0 {
            NSLog("\nDidn't remove any contacts, adding added contacts\n");
            if let groupRecord = groupRecord {
                addGroupContactRelations(groupRecord.id)
            }
            return
        }
        
        let swgSessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
        if swgSessionToken?.characters.count > 0 {
            
            let api = NIKApiInvoker.sharedInstance
            // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
            let serviceName = kDbServiceName
            let tableName = "contact_group_relationship"
            
            let restApiPath = "\(baseUrl)/\(serviceName)/\(tableName)"
            NSLog("\n\(restApiPath)\n")
            
            // do not know the ID of the record to remove
            // one value for groupId, but many values for contactId
            // instead of making a long SQL query, change what we use as identifiers
            let queryParams: JSON = ["id_field": "contact_group_id,contact_id"]
            
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey,
                "X-DreamFactory-Session-Token": swgSessionToken!]
            let contentType = "application/json"
            
            /*
            * Form of request is:
            *  {
            *      "resource":[
            *          {
            *              "contactGroupId":id,
            *              "contactId":id
            *          },
            *          {...}
            *      ]
            *  }
            */
            var records: JSONArray = []
            for contactId in contactsAlreadyInGroupContentsArray {
                records.append(["contact_group_id": groupRecord!.id,
                    "contact_id": contactId])
            }
            
            let requestBody: [String: AnyObject] = ["resource": records]
            
            api.restPath(restApiPath, method: "DELETE", queryParams: queryParams, body: requestBody, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error removing contact group relation: \(error)")
                }
                self.addGroupContactRelations(self.groupRecord!.id)
            })
        }
    }
}

// helper extension to remove objects from array
extension Array where Element: Equatable {
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}
