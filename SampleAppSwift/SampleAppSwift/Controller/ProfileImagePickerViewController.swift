//
//  ProfileImagePickerViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

protocol ProfileImagePickerDelegate: class {
    
}

class ProfileImagePickerViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var imageNameTextField: UITextField!
    
    // set only when editing an existing contact
    // the contact we are choosing a profile image for
    var record: ContactRecord!
    
    weak var delegate: ProfileImagePickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onChooseImageClick() {
        
    }
}
