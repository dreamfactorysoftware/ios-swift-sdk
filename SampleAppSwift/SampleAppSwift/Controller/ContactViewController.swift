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
    fileprivate var contactDetails: [ContactDetailRecord]!
    
    fileprivate var contactGroups: [String]!
    
    fileprivate var queue: DispatchQueue!
    
    fileprivate var groupLock: NSCondition!
    fileprivate var groupReady = false
    
    fileprivate var viewLock: NSCondition!
    fileprivate var viewReady = false
    
    fileprivate var waitLock: NSCondition!
    fileprivate var waitReady = false
    
    fileprivate var canceled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactDetailScrollView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        contactDetailScrollView.backgroundColor = UIColor(red: 254/255.0, green: 254/255.0, blue: 254/255.0, alpha: 1.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewReady {
            // only unlock the view if it is locked
            viewReady = true
            viewLock.signal()
            viewLock.unlock()
        }
        
        let navBar = self.navBar
        navBar.showEdit()
        navBar.editButton.addTarget(self, action: #selector(onEditButtonClick), for: .touchDown)
        navBar.enableAllTouch()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.editButton.removeTarget(self, action: #selector(onEditButtonClick), for: .touchDown)
    }

    func onEditButtonClick() {
        let contactEditViewController = self.storyboard?.instantiateViewController(withIdentifier: "ContactEditViewController") as! ContactEditViewController
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
        
        DispatchQueue.main.async {
            self.waitLock.lock()
            self.groupLock.lock()
            self.viewLock.lock()
        }
        
        queue = DispatchQueue(label: "contactViewQueue", attributes: [])
        queue.async {[weak self] in
            if let strongSelf = self {
                strongSelf.getContactInfoFromServerForRecord(strongSelf.contactRecord)
            }
        }
        queue.async {[weak self] in
            if let strongSelf = self {
                strongSelf.getContactsListFromServerWithRelation()
            }
        }
        queue.async {[weak self] in
            if let strongSelf = self {
                strongSelf.buildContactView()
            }
        }
    }
    
    func cancelPrefetch() {
        canceled = true
        DispatchQueue.main.async {
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
    fileprivate func buildAddressViewForRecord(_ record: ContactDetailRecord, y: CGFloat, buffer: CGFloat) -> UIView {
        
        let subView = UIView(frame: CGRect(x: 0, y: y + buffer, width: view.frame.size.width, height: 20))
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        let typeLabel = UILabel(frame: CGRect(x: 25, y: 10, width: subView.frame.size.width - 25, height: 30))
        typeLabel.text = record.type
        typeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 23.0)
        typeLabel.textColor = UIColor(red: 253/255.0, green: 253/255.0, blue: 250/255.0, alpha: 1.0)
        subView.addSubview(typeLabel)
        
        var next_y: CGFloat = 40 // track where the lowest item is
        if !record.email.isEmpty {
            let label = UILabel(frame: CGRect(x: 50, y: 40, width: subView.frame.size.width - 50, height: 30))
            label.text = record.email
            label.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)
            label.textColor = UIColor(red: 249/255.0, green: 249/255.0, blue: 249/255.0, alpha: 1.0)
            subView.addSubview(label)
            
            let imageView = UIImageView(frame: CGRect(x: 25, y: 45, width: 20, height: 20))
            imageView.image = UIImage(named: "mail")
            imageView.contentMode = .scaleAspectFit
            subView.addSubview(imageView)
            
            next_y += 60
        }
        
        if !record.phone.isEmpty {
            let label = UILabel(frame: CGRect(x: 50, y: next_y, width: subView.frame.size.width - 50, height: 20))
            label.text = record.phone
            label.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)
            label.textColor = UIColor(red: 253/255.0, green: 253/255.0, blue: 250/255.0, alpha: 1.0)
            subView.addSubview(label)
            
            let imageView = UIImageView(frame: CGRect(x: 25, y: next_y, width: 20, height: 20))
            imageView.image = UIImage(named: "phone1")
            imageView.contentMode = .scaleAspectFit
            subView.addSubview(imageView)
            
            next_y += 60
        }
        
        if !record.address.isEmpty && !record.city.isEmpty && !record.state.isEmpty && !record.zipCode.isEmpty {
            let label = UILabel(frame: CGRect(x: 50, y: next_y, width: subView.frame.size.width - 50, height: 20))
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
            
            let imageView = UIImageView(frame: CGRect(x: 25, y: next_y, width: 20, height: 20))
            imageView.image = UIImage(named: "home")
            imageView.contentMode = .scaleAspectFit
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
    
    fileprivate func makeListOfGroupsContactBelongsTo() -> UIView {
        let subView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 20))
        
        let typeLabel = UILabel(frame: CGRect(x: 0, y: 10, width: subView.frame.size.width - 25, height: 30))
        typeLabel.text = "Groups:"
        typeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 23.0)
        subView.addSubview(typeLabel)
        
        var y: CGFloat = 50
        for groupName in contactGroups {
            let label = UILabel(frame: CGRect(x: 25, y: y, width: subView.frame.size.width - 75, height: 30))
            label.text = groupName
            label.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)
            
            y += 30
            
            subView.addSubview(label)
        }
        
        // resize the subview
        var viewFrame = subView.frame
        viewFrame.size.height = y + 20
        viewFrame.origin.x = view.frame.size.width * 0.06
        viewFrame.size.width = view.frame.size.width * 0.88
        subView.frame = viewFrame
        
        return subView
    }
    
    fileprivate func buildContactView() {
        // clear out the view
        DispatchQueue.main.sync {
            if let contactDetailScrollView = self.contactDetailScrollView {
                for view in contactDetailScrollView.subviews {
                    view.removeFromSuperview()
                }
            }
        }
        
        // get the profile image
        let profileImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width * 0.6, height: view.frame.size.width * 0.5))
        getProfileImageFromServerToImageView(profileImageView)
        
        viewLock.lock()
        while !viewReady {
            viewLock.wait()
        }
        viewLock.unlock()
        
        if canceled {
            return
        }
        
        // track the y of the furthest item down in the view
        var y: CGFloat = 0
        DispatchQueue.main.sync {
            profileImageView.center = CGPoint(x: self.view.frame.size.width * 0.5, y: profileImageView.frame.size.height * 0.5)
            y = profileImageView.frame.size.height + 5.0
            
            // add the name label
            let nameLabel = UILabel(frame: CGRect(x: 0, y: y, width: self.view.frame.size.width, height: 35))
            nameLabel.text = self.contactRecord.fullName
            nameLabel.font = UIFont(name: "HelveticaNeue-Light", size: 25.0)
            nameLabel.textAlignment = .center
            self.contactDetailScrollView.addSubview(nameLabel)
            y += 40
            
            if !self.contactRecord.twitter.isEmpty {
                let label = UILabel(frame: CGRect(x: 40, y: y, width: self.view.frame.size.width - 40, height: 20))
                label.font = UIFont(name: "Helvetica Neue", size: 17.0)
                label.text = self.contactRecord.twitter
                self.contactDetailScrollView.addSubview(label)
                
                let imageView = UIImageView(frame: CGRect(x: 10, y: y, width: 20, height: 20))
                imageView.image = UIImage(named: "twitter2")
                imageView.contentMode = .scaleAspectFit
                self.contactDetailScrollView.addSubview(imageView)
                
                y += 30
            }
            
            if !self.contactRecord.skype.isEmpty {
                let label = UILabel(frame: CGRect(x: 40, y: y, width: self.view.frame.size.width - 40, height: 20))
                label.font = UIFont(name: "Helvetica Neue", size: 17.0)
                label.text = self.contactRecord.skype
                self.contactDetailScrollView.addSubview(label)
                
                let imageView = UIImageView(frame: CGRect(x: 10, y: y, width: 20, height: 20))
                imageView.image = UIImage(named: "skype")
                imageView.contentMode = .scaleAspectFit
                self.contactDetailScrollView.addSubview(imageView)
                
                y += 30
            }
            
            if !self.contactRecord.notes.isEmpty {
                let label = UILabel(frame: CGRect(x: 10, y: y, width: 80, height: 25))
                label.font = UIFont(name: "HelveticaNeue-Light", size: 19.0)
                label.text = "Notes"
                self.contactDetailScrollView.addSubview(label)
                y += 20
                
                let notesLabel = UILabel(frame: CGRect(x: self.view.frame.size.width * 0.05, y: y, width: self.view.frame.size.width * 0.9, height: 80))
                notesLabel.autoresizesSubviews = false
                notesLabel.font = UIFont(name: "Helvetica Neue", size: 16.0)
                notesLabel.numberOfLines = 0
                notesLabel.text = self.contactRecord.notes
                notesLabel.sizeToFit()
                self.contactDetailScrollView.addSubview(notesLabel)
                
                y += notesLabel.frame.size.height + 10
            }
            
            // add all the addresses
            for record in self.contactDetails {
                let toAdd = self.buildAddressViewForRecord(record, y: y, buffer: 25)
                toAdd.backgroundColor = UIColor(red: 112/255.0, green: 147/255.0, blue: 181/255.0, alpha: 1.0)
                y += toAdd.frame.size.height + 25
                self.contactDetailScrollView.addSubview(toAdd)
            }
        }
        
        // wait until the group is ready to build group list subviews
        groupLock.lock()
        while !groupReady {
            groupLock.wait()
        }
        groupLock.unlock()
        
        DispatchQueue.main.sync {
            let toAdd = self.makeListOfGroupsContactBelongsTo()
            var frame = toAdd.frame
            frame.origin.y = y + 20
            toAdd.frame = frame
            
            self.contactDetailScrollView.addSubview(toAdd)
            
            // resize the scroll view content
            var contectRect = CGRect.zero
            for view in self.contactDetailScrollView.subviews {
                contectRect = contectRect.union(view.frame)
            }
            self.contactDetailScrollView.contentSize = CGSize(width: self.contactDetailScrollView.frame.size.width, height: contectRect.size.height)
            self.contactDetailScrollView.reloadInputViews()
        }
    }
    
    fileprivate func getContactInfoFromServerForRecord(_ record: ContactRecord) {
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
            DispatchQueue.main.async {
                self.waitReady = true
                self.waitLock.signal()
                self.waitLock.unlock()
            }
            
            }, failure: { error in
                NSLog("Error getting contact info: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
    
    fileprivate func getProfileImageFromServerToImageView(_ imageView: UIImageView) {
        if contactRecord.imageURL.isEmpty {
            DispatchQueue.main.async {
                imageView.image = UIImage(named: "default_portrait")
                imageView.contentMode = .scaleAspectFit
                self.contactDetailScrollView.addSubview(imageView)
            }
            return
        }
        
        RESTEngine.sharedEngine.getProfileImageFromServerWithContactId(contactRecord.id, fileName: contactRecord.imageURL, success: { response in
            DispatchQueue.main.async {
                var image: UIImage!
                guard let content = response?["content"] as? String,
                    let fileData = Data(base64Encoded: content, options: [NSData.Base64DecodingOptions.ignoreUnknownCharacters])
                    else {
                        NSLog("\nWARN: Could not load image off of server, loading default\n");
                        image = UIImage(named: "default_portrait")
                        imageView.image = image
                        imageView.contentMode = .scaleAspectFit
                        self.contactDetailScrollView.addSubview(imageView)
                        return
                }
                
                image = UIImage(data: fileData)
                imageView.image = image
                imageView.contentMode = .scaleAspectFit
                self.contactDetailScrollView.addSubview(imageView)
            }

            }, failure: { error in
                NSLog("Error getting profile image data from server: \(error)")
                DispatchQueue.main.async {
                    NSLog("\nWARN: Could not load image off of server, loading default\n");
                    let image = UIImage(named: "default_portrait")
                    imageView.image = image
                    imageView.contentMode = .scaleAspectFit
                    self.contactDetailScrollView.addSubview(imageView)
                }
            })
    }
    
    fileprivate func getContactsListFromServerWithRelation() {
        
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
            DispatchQueue.main.async {
                self.groupReady = true
                self.groupLock.signal()
                self.groupLock.unlock()
            }

            }, failure: { error in
                NSLog("Error getting groups with relation: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
}
