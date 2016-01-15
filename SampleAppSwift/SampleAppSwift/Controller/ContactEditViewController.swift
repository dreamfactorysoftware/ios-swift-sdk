//
//  ContactEditViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class ContactEditViewController: UIViewController, ProfileImagePickerDelegate, UITextFieldDelegate, ContactInfoDelegate, PickerSelectorDelegate {
    @IBOutlet weak var contactEditScrollView: UIScrollView!
    
    weak var contactViewController: ContactViewController?
    
    // the contact being looked at
    var contactRecord: ContactRecord?
    
    // set when editing an existing contact
    // list of contactinfo records
    var contactDetails: [ContactDetailRecord]?
    
    // set when creating a new contact
    // id of the group the contact is being created in
    var contactGroupId: NSNumber!
    
    // all the text fields we programmatically create
    private var textFields: [String: UITextField] = [:]
    
    // holds all new contact info fields
    private var addedContactInfo: [ContactDetailRecord] = []
    
    // for handling a profile image set up for a new user
    private var imageURL = ""
    private var profileImage: UIImage?
    
    private weak var selectedContactInfoView: ContactInfoView!
    private weak var addButtonRef: UIButton! // reference to bottom AddButton
    private var contactInfoViewHeight: CGFloat = 0 // stores contact view height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactEditScrollView.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)
        contactEditScrollView.backgroundColor = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1.0)
        
        buildContactFields()
        
        // resize scrollview
        var contentRect = CGRectZero
        for view in contactEditScrollView.subviews {
            contentRect = CGRectUnion(contentRect, view.frame)
        }
        
        contactEditScrollView.contentSize = contentRect.size
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
    }
    
    func onDoneButtonClick() {
        let firstNameOptional = textFields["First Name"]?.text
        let lastNameOptional = textFields["Last Name"]?.text
        
        guard let firstName = firstNameOptional where !firstName.isEmpty,
            let lastName = lastNameOptional where !lastName.isEmpty
            else {
                let alert = UIAlertController(title: nil, message: "Please enter a first and last name for the contact", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
                return
        }
        
        self.navBar.disableAllTouch()
        
        if contactRecord != nil {
            //updating existing contact
            if !imageURL.isEmpty && profileImage != nil {
                putLocalImageOnServer(profileImage!)
            } else {
                updateContactWithServer()
            }
        } else {
            // need to create the contact before creating addresses or adding
            // the contact to any groups
            addContactToServer()
        }
    }
    
    func onAddNewAddressClick() {
        // make room for a new view and insert it
        let height: CGFloat = max(contactInfoViewHeight, 345.0)
        let y = addButtonRef.frame.origin.y
        var translation = CGRectZero
        
        translation.origin.y = y + height + 30
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.25)
        
        // move the button down
        addButtonRef.center = CGPointMake(contactEditScrollView.frame.size.width * 0.5, translation.origin.y + addButtonRef.frame.size.height * 0.5)
        
        // make the view scroll down too
        var contentRect = contactEditScrollView.contentSize
        contentRect.height = addButtonRef.frame.origin.y + addButtonRef.frame.size.height
        contactEditScrollView.contentSize = contentRect
        
        let bottomOffset = CGPointMake(0, translation.origin.y + addButtonRef.frame.size.height - contactEditScrollView.frame.size.height)
        contactEditScrollView.setContentOffset(bottomOffset, animated: true)
        
        UIView.commitAnimations()
        
        // build new view
        let contactInfoView = ContactInfoView(frame: CGRectMake(0, y, contactEditScrollView.frame.size.width, 0))
        contactInfoView.delegate = self
        
        let record = ContactDetailRecord()
        addedContactInfo.append(record)
        contactEditScrollView.addSubview(contactInfoView)
        contactInfoView.record = record
    }
    
    func onChangeImageClick() {
        let profileImagePickerViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ProfileImagePickerViewController") as! ProfileImagePickerViewController
        profileImagePickerViewController.delegate = self
        profileImagePickerViewController.record = contactRecord!
        
        self.navigationController?.pushViewController(profileImagePickerViewController, animated: true)
    }
    
    // Profile image picker delegate
    
    func didSelectItem(item: String) {
        self.navigationController?.popViewControllerAnimated(true)
        // gets info passed back up from the image picker
        self.contactRecord!.imageURL = item
    }
    
    func didSelectItem(item: String, withImage image: UIImage) {
        self.navigationController?.popViewControllerAnimated(true)
        // gets info passed back up from the image picker
        self.imageURL = item
        self.profileImage = image
    }
    
    // MARK: - Text field delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - ContactInfo delegate
    func onContactTypeClick(view: ContactInfoView, withTypes types: [String]) {
        let picker = PickerSelector()
        picker.pickerData = types
        picker.delegate = self
        picker.showPickerOver(self)
        selectedContactInfoView = view
    }
    
    // MARK: - Picker delegate
    
    func pickerSelector(selector: PickerSelector, selectedValue value: String, index: Int) {
        selectedContactInfoView.contactType = value
    }
    
    // MARK: - Private methods
    
    private func putValueIn(value: String, forKey key: String) {
        if !value.isEmpty {
            textFields[key]?.text = value
        }
    }
    
    // build ui programmatically
    private func buildContactFields() {
        buildContactTextFields("Contact Details", names: ["First Name", "Last Name", "Twitter", "Skype", "Notes"], y: 30)
        
        // populate contact fields if editing
        if let contactRecord = contactRecord {
            putValueIn(contactRecord.firstName, forKey: "First Name")
            putValueIn(contactRecord.lastName, forKey: "Last Name")
            putValueIn(contactRecord.twitter, forKey: "Twitter")
            putValueIn(contactRecord.skype, forKey: "Skype")
            putValueIn(contactRecord.notes, forKey: "Notes")
        }
        
        let changeImageButton = UIButton(type: .System)
        var y = CGRectGetMaxY(contactEditScrollView.subviews.last!.frame)
        changeImageButton.frame = CGRectMake(0, y + 10, view.frame.size.width, 40)
        changeImageButton.titleLabel?.textAlignment = .Center
        changeImageButton.setTitle("Change image", forState: .Normal)
        changeImageButton.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 20.0)
        changeImageButton.setTitleColor(UIColor(red: 107/255.0, green: 170/255.0, blue: 178/255.0, alpha: 1.0), forState: .Normal)
        
        changeImageButton.addTarget(self, action: "onChangeImageClick", forControlEvents: .TouchUpInside)
        //contactEditScrollView.addSubview(changeImageButton)
        
        // add all the contact info views
        if let contactDetails = contactDetails {
            
            for record in contactDetails {
                let y = CGRectGetMaxY(contactEditScrollView.subviews.last!.frame)
                let contactInfoView = ContactInfoView(frame: CGRectMake(0, y, view.frame.size.width, 40))
                contactInfoView.delegate = self
                
                contactInfoView.record = record
                contactInfoView.updateFields()
                
                contactEditScrollView.addSubview(contactInfoView)
                contactInfoViewHeight = contactInfoView.frame.size.height
            }
        }
        
        // create button to add a new address
        y = CGRectGetMaxY(contactEditScrollView.subviews.last!.frame)
        let addButton = UIButton(type: .System)
        addButton.frame = CGRectMake(0, y + 10, view.frame.size.width, 40)
        addButton.backgroundColor = UIColor(red: 107/255.0, green: 170/255.0, blue: 178/255.0, alpha: 1.0)
        
        addButton.titleLabel?.textAlignment = .Center
        addButton.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 20.0)
        addButton.setTitleColor(UIColor(red: 254/255.0, green: 254/255.0, blue: 254/255.0, alpha: 1.0), forState: .Normal)
        addButton.setTitle("Add new address", forState: .Normal)
        addButton.addTarget(self, action: "onAddNewAddressClick", forControlEvents: .TouchUpInside)
        
        contactEditScrollView.addSubview(addButton)
        addButtonRef = addButton
    }
    
    private func buildContactTextFields(title: String, names: [String], var y: CGFloat) {
        
        for field in names {
            let textField = UITextField(frame: CGRectMake(view.frame.size.width * 0.05, y, view.frame.size.width*0.9, 35))
            textField.placeholder = field
            textField.font = UIFont(name: "Helvetica Neue", size: 20.0)
            textField.backgroundColor = UIColor.whiteColor()
            textField.layer.cornerRadius = 5
            textField.delegate = self;
            contactEditScrollView.addSubview(textField)
            textFields[field] = textField
            
            y += 40
        }
    }
    
    private func addContactToServer() {
        // set up the contact image filename
        var fileName = ""
        if !imageURL.isEmpty {
            fileName = "\(imageURL).jpg"
        }
        
        let requestBody: [String: AnyObject] = ["first_name": textFields["First Name"]!.text!,
            "last_name": textFields["Last Name"]!.text!,
            "filename": fileName,
            "notes": textFields["Notes"]!.text!,
            "twitter": textFields["Twitter"]!.text!,
            "skype": textFields["Skype"]!.text!]
        
        // build the contact and fill it so we don't have to reload when we go up a level
        contactRecord = ContactRecord()
        
        RESTEngine.sharedEngine.addContactToServerWithDetails(requestBody, success: { response in
            let records = response!["resource"] as! JSONArray
            for recordInfo in records {
                self.contactRecord!.id = (recordInfo["id"] as! NSNumber)
            }
            if !self.imageURL.isEmpty && self.profileImage != nil {
                self.createProfileImageOnServer()
            } else {
                self.addContactGroupRelationToServer()
            }
            }, failure: { error in
                NSLog("Error adding new contact to server: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func addContactGroupRelationToServer() {
        RESTEngine.sharedEngine.addContactGroupRelationToServerWithContactId(contactRecord!.id, groupId: contactGroupId, success: {  _ in
            self.addContactInfoToServer()
            
            }, failure: { error in
                NSLog("Error adding contact group relation to server from contact edit: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func addContactInfoToServer() {
        // build request body
        var records: JSONArray = []
        /*
        * Format is:
        *  {
        *      "resource":[
        *          {...},
        *          {...}
        *      ]
        *  }
        *
        */
        
        // fill body with contact details
        for view in contactEditScrollView.subviews {
            if let view = view as? ContactInfoView {
                if view.record?.id == nil {
                    view.record.id = NSNumber(integer: 0)
                    view.record.contactId = contactRecord!.id
                    view.updateRecord()
                    records.append(view.buildToDiciontary())
                    contactDetails!.append(view.record)
                }
            }
        }
        
        // make sure we don't try to put contact info up on the server if we don't have any
        // need to check down here because of the way they are set up
        if records.isEmpty {
            dispatch_async(dispatch_get_main_queue()) {
                self.waitToGoBack()
            }
            return
        }
        
        RESTEngine.sharedEngine.addContactInfoToServer(records, success: { _ in
            // head back up only once all the data has been loaded
            dispatch_async(dispatch_get_main_queue()) {
                self.waitToGoBack()
            }
            }, failure: { error in
                NSLog("Error putting contact details back up on server: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func createProfileImageOnServer() {
        var fileName = "UserFile1.jpg" // default file name
        if !imageURL.isEmpty {
            fileName = "\(imageURL).jpg"
        }
        
        RESTEngine.sharedEngine.addContactImageWithContactId(contactRecord!.id, image: self.profileImage!, imageName: fileName, success: { _in in
                self.addContactGroupRelationToServer()
            }, failure: { error in
                NSLog("Error creating new profile image folder on server: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func putLocalImageOnServer(image: UIImage) {
        var fileName = "UserFile1.jpg" // default file name
        if !imageURL.isEmpty {
            fileName = "\(imageURL).jpg"
        }
        
        RESTEngine.sharedEngine.putImageToFolderWithPath("\(contactRecord!.id)", image: image, fileName: fileName, success: { _ in
            self.contactRecord?.imageURL = fileName
            self.updateContactWithServer()
            
            }, failure: { error in
                NSLog("Error creating image on server: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
            }
        })
    }
    
    private func updateContactWithServer() {
        let requestBody: [String: AnyObject] = ["first_name": textFields["First Name"]!.text!,
            "last_name": textFields["Last Name"]!.text!,
            "notes": textFields["Notes"]!.text!,
            "twitter": textFields["Twitter"]!.text!,
            "skype": textFields["Skype"]!.text!]
        
        // update the contact
        contactRecord!.firstName = requestBody["first_name"] as! String
        contactRecord!.lastName = requestBody["last_name"] as! String
        contactRecord!.notes = requestBody["notes"] as! String
        contactRecord!.twitter = requestBody["twitter"] as! String
        contactRecord!.skype = requestBody["skype"] as! String
        
        RESTEngine.sharedEngine.updateContactWithContactId(contactRecord!.id, contactDetails: requestBody, success: { _ in
            self.updateContactInfoWithServer()
            }, failure: { error in
                NSLog("Error updating contact info with server: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func updateContactInfoWithServer() {
        // build request body
        var records: JSONArray = []
        
        for view in contactEditScrollView.subviews {
            if let view = view as? ContactInfoView {
                if view.record.contactId != nil {
                    view.updateRecord()
                    records.append(view.buildToDiciontary())
                }
            }
        }
        
        if records.isEmpty {
            // if we have no records to update, check if we have any records to add
            addContactInfoToServer()
            return
        }
        
        RESTEngine.sharedEngine.updateContactInfo(records, success: { _ in
            self.addContactInfoToServer()
            }, failure: { error in
                NSLog("Error updating contact details on server: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func waitToGoBack() {
        if let contactViewController = contactViewController {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                contactViewController.prefetch()
                contactViewController.waitToReady()
                self.contactViewController = nil
                dispatch_async(dispatch_get_main_queue()) {
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
}
