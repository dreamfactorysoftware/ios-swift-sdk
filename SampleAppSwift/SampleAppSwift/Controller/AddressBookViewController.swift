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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showAdd()
        navBar.showBackButton(true)
        navBar.addButton.addTarget(self, action: #selector(hitAddGroupButton), for: .touchDown)
        navBar.enableAllTouch()
        
        getAddressBookContentFromServer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.addButton.removeTarget(self, action: #selector(hitAddGroupButton), for: .touchDown)
    }
    
    func hitAddGroupButton() {
        showGroupAddViewController()
    }
    
    //MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addressBookContentArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addressBookTableViewCell", for: indexPath)
        
        let record = addressBookContentArray[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = record.name
        
        return cell
    }
    
    //MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // allow swipe to delete
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let record = addressBookContentArray[(indexPath as NSIndexPath).row]
            
            // can not delete group until all references to it are removed
            // remove relations -> remove group
            // pass record ID so it knows what group we are removing
            removeGroupFromServer(record.id)
            
            addressBookContentArray.remove(at: (indexPath as NSIndexPath).row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let record = addressBookContentArray[(indexPath as NSIndexPath).row]
        
        contactListViewController = self.storyboard?.instantiateViewController(withIdentifier: "ContactListViewController") as! ContactListViewController
        contactListViewController.groupRecord = record
        contactListViewController.prefetch()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showContactListViewController()
    }
    
    //MARK: - Private functions
    
    fileprivate func getAddressBookContentFromServer() {
        // get all the groups
        RESTEngine.sharedEngine.getAddressBookContentFromServerWithSuccess({ response in
            self.addressBookContentArray.removeAll()
            let records = response!["resource"] as! JSONArray
            for recordInfo in records {
                let newRecord = GroupRecord(json: recordInfo)
                self.addressBookContentArray.append(newRecord)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            }, failure: { error in
                NSLog("Error getting address book data: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
    
    fileprivate func removeGroupFromServer(_ groupId: NSNumber) {
        RESTEngine.sharedEngine.removeGroupFromServerWithGroupId(groupId, success: nil, failure: { error in
            NSLog("Error deleting group: \(error)")
            DispatchQueue.main.async {
                Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                _ = self.navigationController?.popToRootViewController(animated: true)
            }
        })
    }
    
    fileprivate func showContactListViewController() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            // already fetching so just wait until the data gets back
            self.contactListViewController.waitToReady()
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(self.contactListViewController, animated: true)
            }
        }
    }
    
    fileprivate func showGroupAddViewController() {
        let groupAddViewController = self.storyboard?.instantiateViewController(withIdentifier: "GroupAddViewController") as! GroupAddViewController
        // tell the viewController we are creating a new group
        groupAddViewController.prefetch()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            // already fetching so just wait until the data gets back
            groupAddViewController.waitToReady()
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(groupAddViewController, animated: true)
            }
        }
    }
}
