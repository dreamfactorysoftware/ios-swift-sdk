//
//  MasterViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class MasterViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // check if login credentials are already stored
        let baseInstanceUrl = NSUserDefaults.standardUserDefaults().valueForKey(kBaseInstanceUrl) as? String
        let userEmail = NSUserDefaults.standardUserDefaults().valueForKey(kUserEmail) as? String
        let userPassword = NSUserDefaults.standardUserDefaults().valueForKey(kPassword) as? String
        
        emailTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        passwordTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        
        if baseInstanceUrl?.characters.count > 0 && userEmail?.characters.count > 0 && userPassword?.characters.count > 0 {
            emailTextField.text = userEmail
            passwordTextField.text = userPassword
        }
    }
    
    @IBAction func RegisterActionEvent(sender: AnyObject) {
        
    }
    
    @IBAction func SubmitActionEvent(sender: AnyObject) {
        
    }
}
