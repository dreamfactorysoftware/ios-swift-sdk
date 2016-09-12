//
//  ContactListViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ContactListViewController: UITableViewController, UISearchBarDelegate {
    // which group is being viewed
    var groupRecord: GroupRecord!
    
    fileprivate var searchBar: UISearchBar!
    
    // if there is a search going on
    fileprivate var isSearch = false
    
    // holds contents of a search
    fileprivate var displayContentArray: [ContactRecord] = []
    
    // contacts broken into groups by first letter of last name
    fileprivate var contactSectionsDictionary: [String: [ContactRecord]]!
    
    // header letters
    fileprivate var alphabetArray: [String]!
    
    // for prefetching data
    fileprivate var contactViewController: ContactViewController?
    fileprivate var goingToShowContactViewController = false
    fileprivate var didPrefetch = false
    fileprivate var viewLock: NSCondition!
    fileprivate var viewReady = false
    fileprivate var queue: DispatchQueue!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up the search bar programmatically
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        searchBar.delegate = self
        tableView.tableHeaderView = searchBar
        
        tableView.allowsMultipleSelectionDuringEditing = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !didPrefetch {
            queue.async {[weak self] in
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
        navBar.addButton.addTarget(self, action: #selector(onAddButtonClick), for: .touchDown)
        navBar.editButton.addTarget(self, action: #selector(onEditButtonClick), for: .touchDown)
        navBar.showEditAndAdd()
        navBar.enableAllTouch()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let navBar = self.navBar
        navBar.addButton.removeTarget(self, action: #selector(onAddButtonClick), for: .touchDown)
        navBar.editButton.removeTarget(self, action: #selector(onEditButtonClick), for: .touchDown)
        
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
            queue = DispatchQueue(label: "contactListQueue", attributes: [])
        }
        
        queue.async {[weak self] in
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
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        displayContentArray.removeAll()
        
        if searchText.isEmpty {
            // done with searching, show all the data
            isSearch = false
            tableView.reloadData()
            return
        }
        isSearch = true
        let firstLetter = searchText.substring(to: searchText.characters.index(searchText.startIndex, offsetBy: 1)).uppercased()
        let arrayAtLetter = contactSectionsDictionary[firstLetter]
        if let arrayAtLetter = arrayAtLetter {
            for record in arrayAtLetter {
                if record.lastName.characters.count < searchText.characters.count {
                    continue
                }
                let lastNameSubstring = record.lastName.substring(to: record.lastName.index(record.lastName.startIndex, offsetBy: searchText.characters.count))
                if lastNameSubstring.caseInsensitiveCompare(searchText) == .orderedSame {
                    displayContentArray.append(record)
                }
            }
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSearch {
            return 1
        }
        return alphabetArray.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearch {
            return displayContentArray.count
        }
        let sectionContacts = contactSectionsDictionary[alphabetArray[section]]!
        return sectionContacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactListTableViewCell", for: indexPath)
        
        let record = recordForIndexPath(indexPath)
        
        cell.textLabel?.text = record.fullName
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearch {
            if let searchText = searchBar.text {
                if searchText.characters.count > 0 {
                    return searchText.substring(to: searchText.characters.index(searchText.startIndex, offsetBy: 1)).uppercased()
                }
            }
        }
        return alphabetArray[section]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red: 210/255.0, green: 225/255.0, blue: 239/255.0, alpha: 1.0)
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let record = recordForIndexPath(indexPath)
        
        if let contactViewController = contactViewController {
            contactViewController.cancelPrefetch()
        }
        
        contactViewController = self.storyboard?.instantiateViewController(withIdentifier: "ContactViewController") as? ContactViewController
        contactViewController!.contactRecord = record
        contactViewController!.prefetch()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let record = recordForIndexPath(indexPath)
        self.navBar.disableAllTouch()
        
        tableView.deselectRow(at: indexPath, animated: true)
        showContactViewControllerForRecord(record)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if isSearch {
                let record = displayContentArray[(indexPath as NSIndexPath).row]
                let index = record.lastName.substring(to: record.lastName.index(record.lastName.startIndex, offsetBy: 1)).uppercased()
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
                
                displayContentArray.remove(at: (indexPath as NSIndexPath).row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } else {
                let sectionLetter = alphabetArray[(indexPath as NSIndexPath).section]
                var sectionContacts = contactSectionsDictionary[sectionLetter]!
                let record = sectionContacts[(indexPath as NSIndexPath).row]
                
                sectionContacts.remove(at: (indexPath as NSIndexPath).row)
                contactSectionsDictionary[sectionLetter] = sectionContacts
                
                tableView.deleteRows(at: [indexPath], with: .automatic)
                if sectionContacts.count == 0 {
                    alphabetArray.remove(at: (indexPath as NSIndexPath).section)
                }
                
                removeContactWithContactId(record.id)
            }
        }
    }
    
    // MARK: - Private methods
    
    fileprivate func recordForIndexPath(_ indexPath: IndexPath) -> ContactRecord {
        var record: ContactRecord!
        if isSearch {
            record = displayContentArray[(indexPath as NSIndexPath).row]
        } else {
            let sectionContacts = contactSectionsDictionary[alphabetArray[(indexPath as NSIndexPath).section]]!
            record = sectionContacts[(indexPath as NSIndexPath).row]
        }
        return record
    }
    
    fileprivate func getContactsListFromServerWithRelation() {
        
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
                        if key.caseInsensitiveCompare(newRecord.lastName.substring(to: newRecord.lastName.index(newRecord.lastName.startIndex, offsetBy: 1))) == .orderedSame {
                            
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
                        let key = newRecord.lastName.substring(to: newRecord.lastName.index(newRecord.lastName.startIndex, offsetBy: 1))
                        self.contactSectionsDictionary[key] = [newRecord]
                    }
                }
            }
            
            var tmp: [String: [ContactRecord]] = [:]
            // sort the sections alphabetically by last name, first name
            for key in self.contactSectionsDictionary.keys {
                let unsorted = self.contactSectionsDictionary[key]!
                let sorted = unsorted.sorted(by: { (one, two) -> Bool in
                    if one.lastName.caseInsensitiveCompare(two.lastName) == .orderedSame {
                        return one.firstName.compare(two.firstName) == ComparisonResult.orderedAscending
                    }
                    return one.lastName.compare(two.lastName) == ComparisonResult.orderedAscending
                })
                tmp[key] = sorted
            }
            self.contactSectionsDictionary = tmp
            self.alphabetArray = Array(self.contactSectionsDictionary.keys).sorted()
            
            DispatchQueue.main.async {
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
                    let decode = (error.userInfo["error"] as AnyObject).firstItem as? JSON
                    let message = decode?["message"] as? String
                    if message != nil && message!.contains("Invalid relationship") {
                        NSLog("Error: table names in relational calls are case sensitive: \(message)")
                        DispatchQueue.main.async {
                            Alert.showAlertWithMessage(message!, fromViewController: self)
                            _ = self.navigationController?.popToRootViewController(animated: true)
                        }
                        return
                    }
                }
                NSLog("Error getting contacts with relation: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
    
    fileprivate func removeContactWithContactId(_ contactId: NSNumber) {
        // finally remove the contact from the database
        
        RESTEngine.sharedEngine.removeContactWithContactId(contactId, success: { _ in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            }, failure: { error in
                NSLog("Error deleting contact: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                }
        })
    }
    
    fileprivate func showContactViewControllerForRecord(_ record: ContactRecord) {
        goingToShowContactViewController = true
        // give the calls on the other end just a little bit of time
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.contactViewController!.waitToReady()
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(self.contactViewController!, animated: true)
            }
        }
    }
    
    fileprivate func showContactEditViewController() {
        let contactEditViewController = self.storyboard?.instantiateViewController(withIdentifier: "ContactEditViewController") as! ContactEditViewController
        // tell the contact list what group it is looking at
        contactEditViewController.contactGroupId = groupRecord.id
        
        self.navigationController?.pushViewController(contactEditViewController, animated: true)
    }
    
    fileprivate func showGroupEditViewController() {
        let groupAddViewController = self.storyboard?.instantiateViewController(withIdentifier: "GroupAddViewController") as! GroupAddViewController
        groupAddViewController.groupRecord = groupRecord
        groupAddViewController.prefetch()
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            
            groupAddViewController.waitToReady()
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(groupAddViewController, animated: true)
            }
        }
    }
}
