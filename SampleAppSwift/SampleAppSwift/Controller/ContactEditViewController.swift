//
//  ContactEditViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class ContactEditViewController: UIViewController {
    @IBOutlet weak var contactEditScrollView: UIScrollView!

    weak var contactViewController: ContactViewController?
    
    // the contact being looked at
    var contactRecord: ContactRecord!
    
    // set when editing an existing contact
    // list of contactinfo records
    var contactDetails: [ContactDetailRecord]!
    
    // set when creating a new contact
    // id of the group the contact is being created in
    var contactGroupId: NSNumber!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
