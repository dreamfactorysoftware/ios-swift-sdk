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
        
        navBar.backButton.addTarget(self, action: "hitBackButton", forControlEvents: .TouchDown)
    }
    
    func hitBackButton() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showBackButton(false)
        navBar.showAddButton(false)
        navBar.showEditButton(false)
        navBar.showDoneButton(false)
    }
    
    @IBAction func RegisterActionEvent(sender: AnyObject) {
        showRegisterViewController()
    }
    
    @IBAction func SubmitActionEvent(sender: AnyObject) {
        self.view.endEditing(true)
        
        //log in using the generic API
        if emailTextField.text?.characters.count > 0 && passwordTextField.text?.characters.count > 0 {
            
            // use the generic API invoker
            let api = NIKApiInvoker.sharedInstance
            let baseUrl = kBaseInstanceUrl // <base instance url>/api/v2
            
            // build rest path for request
            let resourceName = "user/session"
            let restApiPath = "\(baseUrl)/\(resourceName)"
            NSLog("\n\(restApiPath)\n")
            
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey]
            let contentType = "application/json"
            let requestBody: AnyObject = ["email": emailTextField.text!,
                                          "password": passwordTextField.text!]
            
            api.restPath(restApiPath, method: "POST", queryParams: nil, body: requestBody, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error logging in user: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        let alert = UIAlertController(title: nil, message: "Error, invalid password", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "ok", style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setValue(baseUrl, forKey: kBaseInstanceUrl)
                    defaults.setValue(response!["session_token"] as! String, forKey: kSessionTokenKey)
                    defaults.setValue(self.emailTextField.text!, forKey: kUserEmail)
                    defaults.setValue(self.passwordTextField.text!, forKey: kPassword)
                    defaults.synchronize()
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.showAddressBookViewController()
                    }
                }
            })
        } else {
            let alert = UIAlertController(title: nil, message: "Error, invalid password", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "ok", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func showAddressBookViewController() {
        let addressBookViewController = self.storyboard?.instantiateViewControllerWithIdentifier("AddressBookViewController")
        self.navigationController?.pushViewController(addressBookViewController!, animated: true)
    }
    
    private func showRegisterViewController() {
        let registerViewController = self.storyboard?.instantiateViewControllerWithIdentifier("RegisterViewController")
        self.navigationController?.pushViewController(registerViewController!, animated: true)
    }
}
