//
//  RegisterViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        passwordTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showBackButton(true)
        navBar.showAddButton(false)
        navBar.showEditButton(false)
    }
    
    @IBAction func SubmitActionEvent(sender: AnyObject) {
        self.view.endEditing(true)
        if emailTextField.text?.characters.count > 0 && passwordTextField.text?.characters.count > 0 {
            
            // use the generic API invoker
            let api = NIKApiInvoker.sharedInstance
            let baseUrl = kBaseInstanceUrl // <base instance url>/api/v2
            
            // build rest path for request
            let resourceName = "user/register"
            let restApiPath = "\(baseUrl)/\(resourceName)"
            NSLog("\n\(restApiPath)\n")
            
            let queryParams: [String: AnyObject] = ["login": NSNumber(bool: true).stringValue]
            let headerParams = ["X-DreamFactory-Api-Key": kApiKey]
            let contentType = "application/json"
            let requestBody: AnyObject = ["email": emailTextField.text!,
                "password": passwordTextField.text!,
                "first_name": "Address",
                "last_name": "Book",
                "name": "Address Book User"]
            
            api.restPath(restApiPath, method: "POST", queryParams: queryParams, body: requestBody, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
                if let error = error {
                    NSLog("Error registering new user: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
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
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }

    private func showAddressBookViewController() {
        let addressBookViewController = self.storyboard?.instantiateViewControllerWithIdentifier("AddressBookViewController")
        self.navigationController?.pushViewController(addressBookViewController!, animated: true)
    }
    
}
