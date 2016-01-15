//
//  ContactListViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class ContactListViewController: UITableViewController, UISearchBarDelegate {
    // which group is being viewed
    var groupRecord: GroupRecord!
    
    private var searchBar: UISearchBar!
    
    // if there is a search going on
    private var isSearch = false
    
    // holds contents of a search
    private var displayContentArray: [ContactRecord] = []
    
    // contacts broken into groups by first letter of last name
    private var contactSectionsDictionary: [String: [ContactRecord]]!
    
    // header letters
    private var alphabetArray: [String]!
    
    // for prefetching data
    private var contactViewController: ContactViewController?
    private var goingToShowContactViewController = false
    private var didPrefetch = false
    private var viewLock: NSCondition!
    private var viewReady = false
    private var queue: dispatch_queue_t!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up the search bar programmatically
        searchBar = UISearchBar(frame: CGRectMake(0, 0, view.frame.size.width, 44))
        searchBar.delegate = self
        tableView.tableHeaderView = searchBar
        
        tableView.allowsMultipleSelectionDuringEditing = false
    }
    
    override func viewWillAppear(animated: Bool) {
        if !didPrefetch {
            dispatch_async(queue) {[weak self] in
                if let strongSelf = self {
                    strongSelf.getContactsListFromServerWithRelation()
                }
            }
        }
        
        super.viewWillAppear(animated)
        
        contactViewController = nil
        goingToShowContactViewController = false
        // reload the view
        isSearch = false
        searchBar.text = ""
        didPrefetch = false
        
        let navBar = self.navBar
        navBar.addButton.addTarget(self, action: "onAddButtonClick", forControlEvents: .TouchDown)
        navBar.editButton.addTarget(self, action: "onEditButtonClick", forControlEvents: .TouchDown)
        navBar.showEditAndAdd()
        navBar.enableAllTouch()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        let navBar = self.navBar
        navBar.addButton.removeTarget(self, action: "onAddButtonClick", forControlEvents: .TouchDown)
        navBar.editButton.removeTarget(self, action: "onEditButtonClick", forControlEvents: .TouchDown)
        
        if !goingToShowContactViewController && contactViewController != nil {
            contactViewController!.cancelPrefetch()
            contactViewController = nil
        }
    }
    
    func onAddButtonClick() {
        showContactEditViewController()
    }
    
    func onEditButtonClick() {
        showGroupEditViewController()
    }
    
    func prefetch() {
        if viewLock == nil {
            viewLock = NSCondition()
        }
        viewLock.lock()
        viewReady = false
        didPrefetch = true
        
        if queue == nil {
            queue = dispatch_queue_create("contactListQueue", nil)
        }
        
        dispatch_async(queue) {[weak self] in
            if let strongSelf = self {
                strongSelf.getContactsListFromServerWithRelation()
            }
        }
    }
    
    // blocks until the data has been fetched
    func waitToReady() {
        viewLock.lock()
        while !viewReady {
            viewLock.wait()
        }
        viewLock.unlock()
    }
    
    // MARK: - Search bar delegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        displayContentArray.removeAll()
        
        if searchText.isEmpty {
            // done with searching, show all the data
            isSearch = false
            tableView.reloadData()
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
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if isSearch {
            return 1
        }
        return alphabetArray.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearch {
            return displayContentArray.count
        }
        let sectionContacts = contactSectionsDictionary[alphabetArray[section]]!
        return sectionContacts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("contactListTableViewCell", forIndexPath: indexPath)
        
        let record = recordForIndexPath(indexPath)
        
        cell.textLabel?.text = record.fullName
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearch {
            let searchText = searchBar.text
            if searchText?.characters.count > 0 {
                return searchText!.substringToIndex(searchText!.startIndex.advancedBy(1)).uppercaseString
            }
        }
        return alphabetArray[section]
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red: 210/255.0, green: 225/255.0, blue: 239/255.0, alpha: 1.0)
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let record = recordForIndexPath(indexPath)
        
        if let contactViewController = contactViewController {
            contactViewController.cancelPrefetch()
        }
        
        contactViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ContactViewController") as? ContactViewController
        contactViewController!.contactRecord = record
        contactViewController!.prefetch()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let record = recordForIndexPath(indexPath)
        self.navBar.disableAllTouch()
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        showContactViewControllerForRecord(record)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if isSearch {
                let record = displayContentArray[indexPath.row]
                let index = record.lastName.substringToIndex(record.lastName.startIndex.advancedBy(1)).uppercaseString
                var displayArray = contactSectionsDictionary[index]!
                displayArray.removeObject(record)
                if displayArray.count == 0 {
                    // remove tile header if there are no more tiles in that group
                    alphabetArray.removeObject(index)
                }
                contactSectionsDictionary[index] = displayArray
                
                // need to delete everything with references to contact before
                // removing contact its self
                removeContactWithContactId(record.id)
                
                displayContentArray.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            } else {
                let sectionLetter = alphabetArray[indexPath.section]
                var sectionContacts = contactSectionsDictionary[sectionLetter]!
                let record = sectionContacts[indexPath.row]
                
                sectionContacts.removeAtIndex(indexPath.row)
                contactSectionsDictionary[sectionLetter] = sectionContacts
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                if sectionContacts.count == 0 {
                    alphabetArray.removeAtIndex(indexPath.section)
                }
                
                removeContactWithContactId(record.id)
            }
        }
    }
    
    // MARK: - Private methods
    
    private func recordForIndexPath(indexPath: NSIndexPath) -> ContactRecord {
        var record: ContactRecord!
        if isSearch {
            record = displayContentArray[indexPath.row]
        } else {
            let sectionContacts = contactSectionsDictionary[alphabetArray[indexPath.section]]!
            record = sectionContacts[indexPath.row]
        }
        return record
    }
    
    private func getContactsListFromServerWithRelation() {
        
        RESTEngine.sharedEngine.getContactsListFromServerWithRelationWithGroupId(groupRecord.id, success: { response in
            
            self.alphabetArray = []
            self.contactSectionsDictionary = [:]
            self.displayContentArray.removeAll()
            
            // handle repeat contact-group relationships
            var tmpContactIdList: [NSNumber] = []
            
            /*
            *  Structure of reply is:
            *  {
            *      record:[
            *          {
            *              <relation info>,
            *              contact_by_contact_id:{
            *                  <contact info>
            *              }
            *          },
            *          ...
            *      ]
            *  }
            */
            let records = response!["resource"] as! JSONArray
            for relationRecord in records {
                let recordInfo = relationRecord["contact_by_contact_id"] as! JSON
                let contactId = recordInfo["id"] as! NSNumber
                if tmpContactIdList.contains(contactId) {
                    // a different record already related the group-contact pair
                    continue
                }
                tmpContactIdList.append(contactId)
                
                let newRecord = ContactRecord(json: recordInfo)
                if !newRecord.lastName.isEmpty {
                    var found = false
                    for key in self.contactSectionsDictionary.keys {
                        // want to group by last name regardless of case
                        if key.caseInsensitiveCompare(newRecord.lastName.substringToIndex(newRecord.lastName.startIndex.advancedBy(1))) == .OrderedSame {
                            
                            // contact fits in one of the buckets already in the dictionary
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
                if !self.viewReady {
                    self.viewReady = true
                    self.viewLock.signal()
                    self.viewLock.unlock()
                } else {
                    self.tableView.reloadData()
                }
            }
            
            }, failure: { error in
                if error.code == 400 {
                    let decode = error.userInfo["error"]?.firstItem as? JSON
                    let message = decode?["message"] as? String
                    if message != nil && message!.containsString("Invalid relationship") {
                        NSLog("Error: table names in relational calls are case sensitive: \(message)")
                        dispatch_async(dispatch_get_main_queue()) {
                            Alert.showAlertWithMessage(message!, fromViewController: self)
                            self.navigationController?.popToRootViewControllerAnimated(true)
                        }
                        return
                    }
                }
                NSLog("Error getting contacts with relation: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func removeContactWithContactId(contactId: NSNumber) {
        // finally remove the contact from the database
        
        RESTEngine.sharedEngine.removeContactWithContactId(contactId, success: { _ in
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
            }, failure: { error in
                NSLog("Error deleting contact: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func showContactViewControllerForRecord(record: ContactRecord) {
        goingToShowContactViewController = true
        // give the calls on the other end just a little bit of time
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.contactViewController!.waitToReady()
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationController?.pushViewController(self.contactViewController!, animated: true)
            }
        }
    }
    
    private func showContactEditViewController() {
        let contactEditViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ContactEditViewController") as! ContactEditViewController
        // tell the contact list what group it is looking at
        contactEditViewController.contactGroupId = groupRecord.id
        
        self.navigationController?.pushViewController(contactEditViewController, animated: true)
    }
    
    private func showGroupEditViewController() {
        let groupAddViewController = self.storyboard?.instantiateViewControllerWithIdentifier("GroupAddViewController") as! GroupAddViewController
        groupAddViewController.groupRecord = groupRecord
        groupAddViewController.prefetch()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            groupAddViewController.waitToReady()
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationController?.pushViewController(groupAddViewController, animated: true)
            }
        }
    }
}
