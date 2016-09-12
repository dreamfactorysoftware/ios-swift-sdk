//
//  GroupAddViewController.swift
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


class GroupAddViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate {
    @IBOutlet weak var groupAddTableView: UITableView!
    @IBOutlet weak var groupNameTextField: UITextField!
    
    // set groupRecord and contacts alreadyInGroup when editing an existing group
    // contacts already in the existing group
    var contactsAlreadyInGroupContentsArray: [NSNumber]!
    // record of the group being edited
    var groupRecord: GroupRecord?
    
    fileprivate var searchBar: UISearchBar!
    
    // if there is a search going on
    fileprivate var isSearch = false
    
    // holds contents of a search
    fileprivate var displayContentArray: [ContactRecord]!
    
    // array of contacts selected to be in the group
    fileprivate var selectedRows: [NSNumber]!
    
    // contacts broken into groups by first letter of last name
    fileprivate var contactSectionsDictionary: [String: [ContactRecord]]!
    
    // header letters
    fileprivate var alphabetArray: [String]!
    
    fileprivate var waitLock: NSCondition!
    fileprivate var waitReady = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupNameTextField.delegate = self
        groupNameTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        
        // set up the search bar programmatically
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 118, width: view.frame.size.width, height: 44))
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showDone()
        navBar.doneButton.addTarget(self, action: #selector(onDoneButtonClick), for: .touchDown)
        navBar.enableAllTouch()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.doneButton.removeTarget(self, action: #selector(onDoneButtonClick), for: .touchDown)
        navBar.disableAllTouch()
    }
    
    func onDoneButtonClick() {
        if groupNameTextField.text?.characters.count == 0 {
            let alert = UIAlertController(title: nil, message: "Please enter a group name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
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
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.getContactListFromServer()
            if self.groupRecord != nil {
                // if we are editing a group, get any existing group members
                self.getContactGroupRelationListFromServer()
            }
        }
        self.navBar.disableAllTouch()
    }
    
    func waitToReady() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.waitLock.lock()
            while !self.waitReady {
                self.waitLock.wait()
            }
            self.waitLock.unlock()
        }
    }
    
    //MARK: - Text field delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: - Search bar delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        displayContentArray.removeAll()
        
        if searchText.isEmpty {
            // done with searching, show all the data
            isSearch = false
            groupAddTableView.reloadData()
            return
        }
        isSearch = true
        let firstLetter = searchText.substring(to: searchText.index(searchText.startIndex, offsetBy: 1)).uppercased()
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
            groupAddTableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isSearch {
            return 1
        }
        return alphabetArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearch {
            return displayContentArray.count
        }
        let sectionContacts = contactSectionsDictionary[alphabetArray[section]]!
        return sectionContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addGroupContactTableViewCell", for: indexPath)
        
        var record: ContactRecord!
        if isSearch {
            record = displayContentArray[(indexPath as NSIndexPath).row]
        } else {
            let sectionContacts = contactSectionsDictionary[alphabetArray[(indexPath as NSIndexPath).section]]!
            record = sectionContacts[(indexPath as NSIndexPath).row]
        }
        
        cell.textLabel?.text = record.fullName
        
        // if the contact is selected to be in the group, mark it
        if selectedRows.contains(record.id) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    //MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearch {
            if let searchText = searchBar.text {
                if searchText.characters.count > 0 {
                    return searchText.substring(to: searchText.characters.index(searchText.startIndex, offsetBy: 1)).uppercased()
                }
            }
        }
        return alphabetArray[section]
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red: 210/255.0, green: 225/255.0, blue: 239/255.0, alpha: 1.0)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        var contact: ContactRecord!
        
        if isSearch {
            contact = displayContentArray[(indexPath as NSIndexPath).row]
        } else {
            let sectionContacts = contactSectionsDictionary[alphabetArray[(indexPath as NSIndexPath).section]]!
            contact = sectionContacts[(indexPath as NSIndexPath).row]
        }
        
        if cell.accessoryType == .none {
            cell.accessoryType = .checkmark
            selectedRows.append(contact.id)
        } else {
            cell.accessoryType = .none
            selectedRows.removeObject(contact.id)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Private methods
    
    fileprivate func buildUpdateRequest() {
        // if a contact is selected and was already in the group, do nothing
        // if a contact is selected and was not in the group, add it to the group
        // if a contact is not selected and was in the group, remove it from the group
        
        // removing an object mid loop messes with for-each loop
        var toRemove: [NSNumber] = []
        for contactId in selectedRows {
            for i in 0..<contactsAlreadyInGroupContentsArray.count {
                if contactId.isEqual(to: contactsAlreadyInGroupContentsArray[i]) {
                    toRemove.append(contactId)
                    self.contactsAlreadyInGroupContentsArray!.remove(at: i)
                    break
                }
            }
        }
        
        for contactId in toRemove {
            selectedRows.removeObject(contactId)
        }
        
        // remove all the contacts that were in the groups and are not now
        // remove contacts from group -> add contacts to group
        updateGroupWithServer()
    }
    
    fileprivate func getContactListFromServer() {
        
        RESTEngine.sharedEngine.getContactListFromServerWithSuccess({ response in
            // put the contact ids into an array
            let records = response!["resource"] as! JSONArray
            for recordInfo in records {
                let newRecord = ContactRecord(json: recordInfo)
                
                if !newRecord.lastName.isEmpty {
                    var found = false
                    for key in self.contactSectionsDictionary.keys {
                        // want to group by last name regardless of case
                        if key.caseInsensitiveCompare(newRecord.lastName.substring(to: newRecord.lastName.index(newRecord.lastName.startIndex, offsetBy: 1))) == .orderedSame {
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
                self.waitReady = true
                self.waitLock.signal()
                self.waitLock.unlock()
                
                self.groupAddTableView.reloadData()
            }
            
            }, failure: { error in
                NSLog("Error getting all the contacts data: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
    
    fileprivate func addNewGroupToServer() {
        RESTEngine.sharedEngine.addGroupToServerWithName(groupNameTextField.text!, contactIds: selectedRows, success: {_ in
            DispatchQueue.main.async {
                // go to previous screen
                _ = self.navigationController?.popViewController(animated: true)
            }
            }, failure: { error in
                NSLog("Error adding group to server: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
    
    fileprivate func updateGroupWithServer() {
        RESTEngine.sharedEngine.updateGroupWithId(groupRecord!.id, name: groupNameTextField.text!, oldName: groupRecord!.name, removedContactIds: contactsAlreadyInGroupContentsArray, addedContactIds: selectedRows, success: { _ in
            
            self.groupRecord!.name = self.groupNameTextField.text!
            DispatchQueue.main.async {
                _ = self.navigationController?.popViewController(animated: true)
            }
            }, failure: { error in
                NSLog("Error updating contact info with server: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
    
    fileprivate func getContactGroupRelationListFromServer() {
        RESTEngine.sharedEngine.getContactGroupRelationListFromServerWithGroupId(groupRecord!.id, success: { response in
            
            self.contactsAlreadyInGroupContentsArray.removeAll()
            let records = response!["resource"] as! JSONArray
            for recordInfo in records {
                let contactId = recordInfo["contact_id"] as! NSNumber
                self.contactsAlreadyInGroupContentsArray.append(contactId)
                self.selectedRows.append(contactId)
            }
            DispatchQueue.main.async {
                self.groupAddTableView.reloadData()
            }
            
            }, failure: { error in
                NSLog("Error getting contact group relations list: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
}

// helper extension to remove objects from array
extension Array where Element: Equatable {
    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
}
