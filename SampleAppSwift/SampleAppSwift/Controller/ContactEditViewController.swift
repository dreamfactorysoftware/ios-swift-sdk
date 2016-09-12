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
    fileprivate var textFields: [String: UITextField] = [:]
    
    // holds all new contact info fields
    fileprivate var addedContactInfo: [ContactDetailRecord] = []
    
    // for handling a profile image set up for a new user
    fileprivate var imageURL = ""
    fileprivate var profileImage: UIImage?
    
    fileprivate weak var selectedContactInfoView: ContactInfoView!
    fileprivate weak var addButtonRef: UIButton! // reference to bottom AddButton
    fileprivate weak var activeTextField: UITextField?
    fileprivate var contactInfoViewHeight: CGFloat = 0 // stores contact view height
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactEditScrollView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        contactEditScrollView.backgroundColor = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1.0)
        
        buildContactFields()
        
        // resize scrollview
        var contentRect = CGRect.zero
        for view in contactEditScrollView.subviews {
            contentRect = contentRect.union(view.frame)
        }
        
        contactEditScrollView.contentSize = contentRect.size
        registerForKeyboardNotifications()
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
    }
    
    fileprivate func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWasShown(_ notification: Notification) {
        if activeTextField == nil {
            return
        }
        
        let info = (notification as NSNotification).userInfo
        let kbSize = (info![UIKeyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue.size
        
        let contentInsets = UIEdgeInsetsMake(contactEditScrollView.contentInset.top, 0, kbSize.height, 0)
        contactEditScrollView.contentInset = contentInsets
        contactEditScrollView.scrollIndicatorInsets = contentInsets
        
        var aRect = view.frame
        aRect.size.height -= kbSize.height
        if !aRect.contains(activeTextField!.frame.origin) {
            contactEditScrollView.scrollRectToVisible(activeTextField!.frame, animated: true)
        }
    }
    
    func keyboardWillBeHidden(_ notification: Notification) {
        let contentInsets = UIEdgeInsetsMake(contactEditScrollView.contentInset.top, 0, 0, 0)
        contactEditScrollView.contentInset = contentInsets
        contactEditScrollView.scrollIndicatorInsets = contentInsets
    }
    
    func onDoneButtonClick() {
        let firstNameOptional = textFields["First Name"]?.text
        let lastNameOptional = textFields["Last Name"]?.text
        
        guard let firstName = firstNameOptional , !firstName.isEmpty,
            let lastName = lastNameOptional , !lastName.isEmpty
            else {
                let alert = UIAlertController(title: nil, message: "Please enter a first and last name for the contact", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
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
        var translation = CGRect.zero
        
        translation.origin.y = y + height + 30
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.25)
        
        // move the button down
        addButtonRef.center = CGPoint(x: contactEditScrollView.frame.size.width * 0.5, y: translation.origin.y + addButtonRef.frame.size.height * 0.5)
        
        // make the view scroll down too
        var contentRect = contactEditScrollView.contentSize
        contentRect.height = addButtonRef.frame.origin.y + addButtonRef.frame.size.height
        contactEditScrollView.contentSize = contentRect
        
        let bottomOffset = CGPoint(x: 0, y: translation.origin.y + addButtonRef.frame.size.height - contactEditScrollView.frame.size.height)
        contactEditScrollView.setContentOffset(bottomOffset, animated: true)
        
        UIView.commitAnimations()
        
        // build new view
        let contactInfoView = ContactInfoView(frame: CGRect(x: 0, y: y, width: contactEditScrollView.frame.size.width, height: 0))
        contactInfoView.delegate = self
        contactInfoView.setTextFieldsDelegate(self)
        
        let record = ContactDetailRecord()
        addedContactInfo.append(record)
        contactEditScrollView.addSubview(contactInfoView)
        contactInfoView.record = record
    }
    
    func onChangeImageClick() {
        let profileImagePickerViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileImagePickerViewController") as! ProfileImagePickerViewController
        profileImagePickerViewController.delegate = self
        profileImagePickerViewController.record = contactRecord!
        
        self.navigationController?.pushViewController(profileImagePickerViewController, animated: true)
    }
    
    // Profile image picker delegate
    
    func didSelectItem(_ item: String) {
        _ = self.navigationController?.popViewController(animated: true)
        // gets info passed back up from the image picker
        self.contactRecord!.imageURL = item
    }
    
    func didSelectItem(_ item: String, withImage image: UIImage) {
        _ = self.navigationController?.popViewController(animated: true)
        // gets info passed back up from the image picker
        self.imageURL = item
        self.profileImage = image
    }
    
    // MARK: - Text field delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
    
    // MARK: - ContactInfo delegate
    func onContactTypeClick(_ view: ContactInfoView, withTypes types: [String]) {
        let picker = PickerSelector()
        picker.pickerData = types
        picker.delegate = self
        picker.showPickerOver(self)
        selectedContactInfoView = view
    }
    
    // MARK: - Picker delegate
    
    func pickerSelector(_ selector: PickerSelector, selectedValue value: String, index: Int) {
        selectedContactInfoView.contactType = value
    }
    
    // MARK: - Private methods
    
    fileprivate func putValueIn(_ value: String, forKey key: String) {
        if !value.isEmpty {
            textFields[key]?.text = value
        }
    }
    
    // build ui programmatically
    fileprivate func buildContactFields() {
        buildContactTextFields("Contact Details", names: ["First Name", "Last Name", "Twitter", "Skype", "Notes"])
        
        // populate contact fields if editing
        if let contactRecord = contactRecord {
            putValueIn(contactRecord.firstName, forKey: "First Name")
            putValueIn(contactRecord.lastName, forKey: "Last Name")
            putValueIn(contactRecord.twitter, forKey: "Twitter")
            putValueIn(contactRecord.skype, forKey: "Skype")
            putValueIn(contactRecord.notes, forKey: "Notes")
        }
        
        let changeImageButton = UIButton(type: .system)
        var y = contactEditScrollView.subviews.last!.frame.maxY
        changeImageButton.frame = CGRect(x: 0, y: y + 10, width: view.frame.size.width, height: 40)
        changeImageButton.titleLabel?.textAlignment = .center
        changeImageButton.setTitle("Change image", for: UIControlState())
        changeImageButton.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 20.0)
        changeImageButton.setTitleColor(UIColor(red: 107/255.0, green: 170/255.0, blue: 178/255.0, alpha: 1.0), for: UIControlState())
        
        changeImageButton.addTarget(self, action: #selector(onChangeImageClick), for: .touchUpInside)
        //contactEditScrollView.addSubview(changeImageButton)
        
        // add all the contact info views
        if let contactDetails = contactDetails {
            
            for record in contactDetails {
                let y = contactEditScrollView.subviews.last!.frame.maxY
                let contactInfoView = ContactInfoView(frame: CGRect(x: 0, y: y, width: view.frame.size.width, height: 40))
                contactInfoView.delegate = self
                contactInfoView.setTextFieldsDelegate(self)
                
                contactInfoView.record = record
                contactInfoView.updateFields()
                
                contactEditScrollView.addSubview(contactInfoView)
                contactInfoViewHeight = contactInfoView.frame.size.height
            }
        }
        
        // create button to add a new address
        y = contactEditScrollView.subviews.last!.frame.maxY
        let addButton = UIButton(type: .system)
        addButton.frame = CGRect(x: 0, y: y + 10, width: view.frame.size.width, height: 40)
        addButton.backgroundColor = UIColor(red: 107/255.0, green: 170/255.0, blue: 178/255.0, alpha: 1.0)
        
        addButton.titleLabel?.textAlignment = .center
        addButton.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 20.0)
        addButton.setTitleColor(UIColor(red: 254/255.0, green: 254/255.0, blue: 254/255.0, alpha: 1.0), for: UIControlState())
        addButton.setTitle("Add new address", for: UIControlState())
        addButton.addTarget(self, action: #selector(onAddNewAddressClick), for: .touchUpInside)
        
        contactEditScrollView.addSubview(addButton)
        addButtonRef = addButton
    }
    
    fileprivate func buildContactTextFields(_ title: String, names: [String]) {
        var y: CGFloat = 30
        for field in names {
            let textField = UITextField(frame: CGRect(x: view.frame.size.width * 0.05, y: y, width: view.frame.size.width*0.9, height: 35))
            textField.placeholder = field
            textField.font = UIFont(name: "Helvetica Neue", size: 20.0)
            textField.backgroundColor = UIColor.white
            textField.layer.cornerRadius = 5
            textField.delegate = self;
            contactEditScrollView.addSubview(textField)
            textFields[field] = textField
            
            y += 40
        }
    }
    
    fileprivate func addContactToServer() {
        // set up the contact image filename
        var fileName = ""
        if !imageURL.isEmpty {
            fileName = "\(imageURL).jpg"
        }
        
        let requestBody: [String: AnyObject] = [
            "first_name": textFields["First Name"]!.text! as AnyObject,
            "last_name": textFields["Last Name"]!.text! as AnyObject,
            "filename": fileName as AnyObject,
            "notes": textFields["Notes"]!.text! as AnyObject,
            "twitter": textFields["Twitter"]!.text! as AnyObject,
            "skype": textFields["Skype"]!.text! as AnyObject]
        
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
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navBar.enableAllTouch()
                }
        })
    }
    
    fileprivate func addContactGroupRelationToServer() {
        RESTEngine.sharedEngine.addContactGroupRelationToServerWithContactId(contactRecord!.id, groupId: contactGroupId, success: {  _ in
            self.addContactInfoToServer()
            
            }, failure: { error in
                NSLog("Error adding contact group relation to server from contact edit: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
    
    fileprivate func addContactInfoToServer() {
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
                if view.record?.id == nil || view.record?.id == 0 {
                    view.record.id = NSNumber(value: 0 as Int)
                    view.record.contactId = contactRecord!.id
                    
                    var shouldBreak = false
                    view.validateInfoWithResult { success, message in
                        shouldBreak = !success
                        if !success {
                            DispatchQueue.main.async {
                                Alert.showAlertWithMessage(message!, fromViewController: self)
                                self.navBar.enableAllTouch()
                            }
                        }
                    }
                    if shouldBreak {
                        return
                    }
                    
                    view.updateRecord()
                    records.append(view.buildToDiciontary())
                    contactDetails?.append(view.record)
                }
            }
        }
        
        // make sure we don't try to put contact info up on the server if we don't have any
        // need to check down here because of the way they are set up
        if records.isEmpty {
            DispatchQueue.main.async {
                self.waitToGoBack()
            }
            return
        }
        
        RESTEngine.sharedEngine.addContactInfoToServer(records, success: { _ in
            // head back up only once all the data has been loaded
            DispatchQueue.main.async {
                self.waitToGoBack()
            }
            }, failure: { error in
                NSLog("Error putting contact details back up on server: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navBar.enableAllTouch()
                }
        })
    }
    
    fileprivate func createProfileImageOnServer() {
        var fileName = "UserFile1.jpg" // default file name
        if !imageURL.isEmpty {
            fileName = "\(imageURL).jpg"
        }
        
        RESTEngine.sharedEngine.addContactImageWithContactId(contactRecord!.id, image: self.profileImage!, imageName: fileName, success: { _in in
                self.addContactGroupRelationToServer()
            }, failure: { error in
                NSLog("Error creating new profile image folder on server: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navBar.enableAllTouch()
                }
        })
    }
    
    fileprivate func putLocalImageOnServer(_ image: UIImage) {
        var fileName = "UserFile1.jpg" // default file name
        if !imageURL.isEmpty {
            fileName = "\(imageURL).jpg"
        }
        
        RESTEngine.sharedEngine.putImageToFolderWithPath("\(contactRecord!.id)", image: image, fileName: fileName, success: { _ in
            self.contactRecord?.imageURL = fileName
            self.updateContactWithServer()
            
            }, failure: { error in
                NSLog("Error creating image on server: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navBar.enableAllTouch()
            }
        })
    }
    
    fileprivate func updateContactWithServer() {
        let requestBody: [String: AnyObject] = ["first_name": textFields["First Name"]!.text! as AnyObject,
            "last_name": textFields["Last Name"]!.text! as AnyObject,
            "notes": textFields["Notes"]!.text! as AnyObject,
            "twitter": textFields["Twitter"]!.text! as AnyObject,
            "skype": textFields["Skype"]!.text! as AnyObject]
        
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
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navBar.enableAllTouch()
                }
        })
    }
    
    fileprivate func updateContactInfoWithServer() {
        // build request body
        var records: JSONArray = []
        
        for view in contactEditScrollView.subviews {
            if let view = view as? ContactInfoView {
                if !view.record.contactId.isEqual(to: -1) {
                    
                    var shouldBreak = false
                    view.validateInfoWithResult { success, message in
                        shouldBreak = !success
                        if !success {
                            DispatchQueue.main.async {
                                Alert.showAlertWithMessage(message!, fromViewController: self)
                                self.navBar.enableAllTouch()
                            }
                        }
                    }
                    if shouldBreak {
                        return
                    }
                    
                    view.updateRecord()
                    if view.record.id != 0 {
                        records.append(view.buildToDiciontary())
                    }
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
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navBar.enableAllTouch()
                }
        })
    }
    
    fileprivate func waitToGoBack() {
        if let contactViewController = contactViewController {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                contactViewController.prefetch()
                contactViewController.waitToReady()
                self.contactViewController = nil
                DispatchQueue.main.async {
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
}
