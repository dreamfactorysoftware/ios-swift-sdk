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
    
    var didPrecall = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    func prefetch() {
        
    }
    
    func cancelPrefetch() {
        
    }
    
    func waitToReady() {
        
    }
    
}
