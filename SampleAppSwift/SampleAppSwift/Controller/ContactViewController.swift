//
//  ContactViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class ContactViewController: UIViewController {
    @IBOutlet weak var contactDetailScrollView: UIScrollView!
    
    // the contact being looked at
    var contactRecord: ContactRecord!

    // holds contact info records
    private var contactDetails: [ContactDetailRecord]!
    
    private var contactGroups: [String]!
    
    private var queue: dispatch_queue_t!
    
    private var groupLock: NSCondition!
    private var groupReady = false
    
    private var viewLock: NSCondition!
    private var viewReady = false
    
    private var waitLock: NSCondition!
    private var waitReady = false
    
    private var canceled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactDetailScrollView.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)
        contactDetailScrollView.backgroundColor = UIColor(red: 254/255.0, green: 254/255.0, blue: 254/255.0, alpha: 1.0)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if !viewReady {
            // only unlock the view if it is locked
            viewReady = true
            viewLock.signal()
            viewLock.unlock()
        }
        
        let navBar = self.navBar
        navBar.showEdit()
        navBar.editButton.addTarget(self, action: "onEditButtonClick", forControlEvents: .TouchDown)
        navBar.enableAllTouch()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.editButton.removeTarget(self, action: "onEditButtonClick", forControlEvents: .TouchDown)
    }

    func onEditButtonClick() {
        let contactEditViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ContactEditViewController") as! ContactEditViewController
        // tell the contact list what group it is looking at
        contactEditViewController.contactRecord = contactRecord
        contactEditViewController.contactViewController = self
        contactEditViewController.contactDetails = contactDetails
        
        self.navigationController?.pushViewController(contactEditViewController, animated: true)
    }
    
    func prefetch() {
        contactDetails = []
        contactGroups = []
        
        groupLock = NSCondition()
        waitLock = NSCondition()
        viewLock = NSCondition()
        
        groupReady = false
        waitReady = false
        viewReady = false
        canceled = false
        
        dispatch_async(dispatch_get_main_queue()) {
            self.waitLock.lock()
            self.groupLock.lock()
            self.viewLock.lock()
        }
        
        queue = dispatch_queue_create("contactViewQueue", nil)
        dispatch_async(queue) {[weak self] in
            if let strongSelf = self {
                strongSelf.getContactInfoFromServerForRecord(strongSelf.contactRecord)
            }
        }
        dispatch_async(queue) {[weak self] in
            if let strongSelf = self {
                strongSelf.getContactsListFromServerWithRelation()
            }
        }
        dispatch_async(queue) {[weak self] in
            if let strongSelf = self {
                strongSelf.buildContactView()
            }
        }
    }
    
    func cancelPrefetch() {
        canceled = true
        dispatch_async(dispatch_get_main_queue()) {
            self.viewReady = true
            self.viewLock.signal()
            self.viewLock.unlock()
        }
    }
    
    func waitToReady() {
        waitLock.lock()
        while !waitReady {
            waitLock.wait()
        }
        waitLock.signal()
        waitLock.unlock()
    }
    
    // MARK: - Private methods
    
    // build the address boxes
    private func buildAddressViewForRecord(record: ContactDetailRecord, y: CGFloat, buffer: CGFloat) -> UIView {
        
        let subView = UIView(frame: CGRectMake(0, y + buffer, view.frame.size.width, 20))
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        let typeLabel = UILabel(frame: CGRectMake(25, 10, subView.frame.size.width - 25, 30))
        typeLabel.text = record.type
        typeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 23.0)
        typeLabel.textColor = UIColor(red: 253/255.0, green: 253/255.0, blue: 250/255.0, alpha: 1.0)
        subView.addSubview(typeLabel)
        
        var next_y: CGFloat = 40 // track where the lowest item is
        if !record.email.isEmpty {
            let label = UILabel(frame: CGRectMake(50, 40, subView.frame.size.width - 50, 30))
            label.text = record.email
            label.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)
            label.textColor = UIColor(red: 249/255.0, green: 249/255.0, blue: 249/255.0, alpha: 1.0)
            subView.addSubview(label)
            
            let imageView = UIImageView(frame: CGRectMake(25, 45, 20, 20))
            imageView.image = UIImage(named: "mail")
            imageView.contentMode = .ScaleAspectFit
            subView.addSubview(imageView)
            
            next_y += 60
        }
        
        if !record.phone.isEmpty {
            let label = UILabel(frame: CGRectMake(50, next_y, subView.frame.size.width - 50, 20))
            label.text = record.phone
            label.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)
            label.textColor = UIColor(red: 253/255.0, green: 253/255.0, blue: 250/255.0, alpha: 1.0)
            subView.addSubview(label)
            
            let imageView = UIImageView(frame: CGRectMake(25, next_y, 20, 20))
            imageView.image = UIImage(named: "phone1")
            imageView.contentMode = .ScaleAspectFit
            subView.addSubview(imageView)
            
            next_y += 60
        }
        
        if !record.address.isEmpty && !record.city.isEmpty && !record.state.isEmpty && !record.zipCode.isEmpty {
            let label = UILabel(frame: CGRectMake(50, next_y, subView.frame.size.width - 50, 20))
            label.font = UIFont(name: "HelveticaNeue-Light", size: 19.0)
            label.numberOfLines = 0
            label.textColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1.0)
            
            var addressText = "\(record.address)\n\(record.city), \(record.state) \(record.zipCode)"
            if !record.country.isEmpty {
                addressText += "\n\(record.country)"
            }
            label.text = addressText
            label.sizeToFit()
            subView.addSubview(label)
            
            let imageView = UIImageView(frame: CGRectMake(25, next_y, 20, 20))
            imageView.image = UIImage(named: "home")
            imageView.contentMode = .ScaleAspectFit
            subView.addSubview(imageView)
            
            next_y += label.frame.size.height
        }
        
        // resize the subview
        var viewFrame = subView.frame
        viewFrame.size.height = next_y + 20
        viewFrame.origin.x = view.frame.size.width * 0.06
        viewFrame.size.width = view.frame.size.width * 0.88
        subView.frame = viewFrame
        
        return subView
    }
    
    private func makeListOfGroupsContactBelongsTo() -> UIView {
        let subView = UIView(frame: CGRectMake(0, 0, view.frame.size.width, 20))
        
        let typeLabel = UILabel(frame: CGRectMake(0, 10, subView.frame.size.width - 25, 30))
        typeLabel.text = "Groups:"
        typeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 23.0)
        subView.addSubview(typeLabel)
        
        var y: CGFloat = 50
        for groupName in contactGroups {
            let label = UILabel(frame: CGRectMake(25, y, subView.frame.size.width - 75, 30))
            label.text = groupName
            label.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)
            
            y += 30
            
            subView.addSubview(label)
        }
        
        // resize the subview
        var viewFrame = subView.frame
        viewFrame.size.height = y + 20
        view.frame.origin.x = view.frame.size.width * 0.06
        view.frame.size.width = view.frame.size.width * 0.88
        subView.frame = viewFrame
        
        return subView
    }
    
    private func buildContactView() {
        viewLock.lock()
        while !viewReady {
            viewLock.wait()
        }
        viewLock.unlock()
        
        if canceled {
            return
        }
        
        // clear out the view
        dispatch_sync(dispatch_get_main_queue()) {
            for view in self.contactDetailScrollView.subviews {
                view.removeFromSuperview()
            }
        }
        
        // get the profile image
        let profileImageView = UIImageView(frame: CGRectMake(0, 0, view.frame.size.width * 0.6, view.frame.size.width * 0.5))
        getProfileImageFromServerToImageView(profileImageView)
        
        // track the y of the furthest item down in the view
        var y: CGFloat = 0
        dispatch_async(dispatch_get_main_queue()) {
            profileImageView.center = CGPointMake(self.view.frame.size.width * 0.5, profileImageView.frame.size.height * 0.5)
            y = profileImageView.frame.size.height + 5.0
            
            // add the name label
            let nameLabel = UILabel(frame: CGRectMake(0, y, self.view.frame.size.width, 35))
            nameLabel.text = self.contactRecord.fullName
            nameLabel.font = UIFont(name: "HelveticaNeue-Light", size: 25.0)
            nameLabel.textAlignment = .Center
            self.contactDetailScrollView.addSubview(nameLabel)
            y += 40
            
            if !self.contactRecord.twitter.isEmpty {
                let label = UILabel(frame: CGRectMake(40, y, self.view.frame.size.width - 40, 20))
                label.font = UIFont(name: "Helvetica Neue", size: 17.0)
                label.text = self.contactRecord.twitter
                self.contactDetailScrollView.addSubview(label)
                
                let imageView = UIImageView(frame: CGRectMake(10, y, 20, 20))
                imageView.image = UIImage(named: "twitter2")
                imageView.contentMode = .ScaleAspectFit
                self.contactDetailScrollView.addSubview(imageView)
                
                y += 30
            }
            
            if !self.contactRecord.skype.isEmpty {
                let label = UILabel(frame: CGRectMake(40, y, self.view.frame.size.width - 40, 20))
                label.font = UIFont(name: "Helvetica Neue", size: 17.0)
                label.text = self.contactRecord.skype
                self.contactDetailScrollView.addSubview(label)
                
                let imageView = UIImageView(frame: CGRectMake(10, y, 20, 20))
                imageView.image = UIImage(named: "skype")
                imageView.contentMode = .ScaleAspectFit
                self.contactDetailScrollView.addSubview(imageView)
                
                y += 30
            }
            
            if !self.contactRecord.notes.isEmpty {
                let label = UILabel(frame: CGRectMake(10, y, 80, 25))
                label.font = UIFont(name: "HelveticaNeue-Light", size: 19.0)
                label.text = "Notes"
                self.contactDetailScrollView.addSubview(label)
                y += 20
                
                let notesLabel = UILabel(frame: CGRectMake(self.view.frame.size.width * 0.05, y, self.view.frame.size.width * 0.9, 80))
                notesLabel.autoresizesSubviews = false
                notesLabel.font = UIFont(name: "Helvetica Neue", size: 16.0)
                notesLabel.numberOfLines = 0
                notesLabel.text = self.contactRecord.notes
                notesLabel.sizeToFit()
                self.contactDetailScrollView.addSubview(notesLabel)
                
                y += notesLabel.frame.size.height + 10
            }
        }
        
        // add all the addresses
        dispatch_async(dispatch_get_main_queue()) {
            for record in self.contactDetails {
                let toAdd = self.buildAddressViewForRecord(record, y: y, buffer: 25)
                toAdd.backgroundColor = UIColor(red: 112/255.0, green: 147/255.0, blue: 181/255.0, alpha: 1.0)
                y += toAdd.frame.size.height + 25
                self.contactDetailScrollView.addSubview(toAdd)
            }
        }
        
        dispatch_sync(dispatch_get_main_queue()) {
            self.contactDetailScrollView.reloadInputViews()
        }
        
        // wait until the group is ready to build group list subviews
        groupLock.lock()
        while !groupReady {
            groupLock.wait()
        }
        groupLock.unlock()
        
        dispatch_sync(dispatch_get_main_queue()) {
            let toAdd = self.makeListOfGroupsContactBelongsTo()
            var frame = toAdd.frame
            frame.origin.y = y + 20
            toAdd.frame = frame
            
            self.contactDetailScrollView.addSubview(toAdd)
        }
        
        // resize the scroll view content
        
        dispatch_async(dispatch_get_main_queue()) {
            var contectRect = CGRectZero
            for view in self.contactDetailScrollView.subviews {
                contectRect = CGRectUnion(contectRect, view.frame)
            }
            self.contactDetailScrollView.contentSize = contectRect.size
            self.contactDetailScrollView.reloadInputViews()
        }
    }
    
    private func getContactInfoFromServerForRecord(record: ContactRecord) {
        RESTEngine.sharedEngine.getContactInfoFromServerWithContactId(record.id, success: { response in
            // put the contact ids into an array
            var array: [ContactDetailRecord] = []
            
            // double check we don't fetch any repeats
            var existingIds: [NSNumber: Bool] = [:]
            
            let records = response!["resource"] as! JSONArray
            for recordInfo in records {
                let recordId = recordInfo["id"] as! NSNumber
                if existingIds[recordId] != nil {
                    continue
                }
                existingIds[recordId] = true
                
                let newRecord = ContactDetailRecord(json: recordInfo)
                array.append(newRecord)
            }
            
            self.contactDetails = array
            dispatch_async(dispatch_get_main_queue()) {
                self.waitReady = true
                self.waitLock.signal()
                self.waitLock.unlock()
            }
            
            }, failure: { error in
                NSLog("Error getting contact info: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
    
    private func getProfileImageFromServerToImageView(imageView: UIImageView) {
        if contactRecord.imageURL == nil || contactRecord.imageURL.isEmpty {
            dispatch_async(dispatch_get_main_queue()) {
                imageView.image = UIImage(named: "default_portrait")
                imageView.contentMode = .ScaleAspectFit
                self.contactDetailScrollView.addSubview(imageView)
            }
            return
        }
        
        RESTEngine.sharedEngine.getProfileImageFromServerWithContactId(contactRecord.id, fileName: contactRecord.imageURL, success: { response in
            dispatch_async(dispatch_get_main_queue()) {
                var image: UIImage!
                guard let content = response?["content"] as? String,
                    let fileData = NSData(base64EncodedString: content, options: [NSDataBase64DecodingOptions.IgnoreUnknownCharacters])
                    else {
                        NSLog("\nWARN: Could not load image off of server, loading default\n");
                        image = UIImage(named: "default_portrait")
                        imageView.image = image
                        imageView.contentMode = .ScaleAspectFit
                        self.contactDetailScrollView.addSubview(imageView)
                        return
                }
                
                image = UIImage(data: fileData)
                imageView.image = image
                imageView.contentMode = .ScaleAspectFit
                self.contactDetailScrollView.addSubview(imageView)
            }

            }, failure: { error in
                NSLog("Error getting profile image data from server: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    NSLog("\nWARN: Could not load image off of server, loading default\n");
                    let image = UIImage(named: "default_portrait")
                    imageView.image = image
                    imageView.contentMode = .ScaleAspectFit
                    self.contactDetailScrollView.addSubview(imageView)
                }
            })
    }
    
    private func getContactsListFromServerWithRelation() {
        
        RESTEngine.sharedEngine.getContactGroupsWithContactId(contactRecord.id, success: { response in
            self.contactGroups.removeAll()
            
            // handle repeat contact-group relationships
            var tmpGroupIdMap: [NSNumber: Bool] = [:]
            
            /*
            *  Structure of reply is:
            *  {
            *      record:[
            *          {
            *              <relation info>,
            *              contact_group_by_contactGroupId:{
            *                  <group info>
            *              }
            *          },
            *          ...
            *      ]
            *  }
            */
            
            let records = response!["resource"] as! JSONArray
            for relationalRecord in records {
                let recordInfo = relationalRecord["contact_group_by_contact_group_id"] as! JSON
                let contactId = recordInfo["id"] as! NSNumber
                if tmpGroupIdMap[contactId] != nil {
                    // a different record already related the group-contact pair
                    continue
                }
                tmpGroupIdMap[contactId] = true
                let groupName = recordInfo["name"] as! String
                self.contactGroups.append(groupName)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.groupReady = true
                self.groupLock.signal()
                self.groupLock.unlock()
            }

            }, failure: { error in
                NSLog("Error getting groups with relation: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
}
