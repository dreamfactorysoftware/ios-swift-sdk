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
    @IBOutlet weak var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionLabel.text = "Version \(kAppVersion)"
        
        // check if login credentials are already stored
        let userEmail = NSUserDefaults.standardUserDefaults().valueForKey(kUserEmail) as? String
        let userPassword = NSUserDefaults.standardUserDefaults().valueForKey(kPassword) as? String
        
        emailTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        passwordTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        
        if userEmail?.characters.count > 0 && userPassword?.characters.count > 0 {
            emailTextField.text = userEmail
            passwordTextField.text = userPassword
        }
        
        navBar.backButton.addTarget(self, action: "onBackButtonClick", forControlEvents: .TouchDown)
    }
    
    func onBackButtonClick() {
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
    
    @IBAction func onRegisterClick(sender: AnyObject) {
        showRegisterViewController()
    }
    
    @IBAction func onSignInClick(sender: AnyObject) {
        self.view.endEditing(true)
        
        //log in using the generic API
        if emailTextField.text?.characters.count > 0 && passwordTextField.text?.characters.count > 0 {
            
            RESTEngine.sharedEngine.loginWithEmail(emailTextField.text!, password: passwordTextField.text!,
                success: { response in
                    RESTEngine.sharedEngine.sessionToken = response!["session_token"] as? String
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setValue(self.emailTextField.text!, forKey: kUserEmail)
                    defaults.setValue(self.passwordTextField.text!, forKey: kPassword)
                    defaults.synchronize()
                    dispatch_async(dispatch_get_main_queue()) {
                        self.showAddressBookViewController()
                    }
                }, failure: { error in
                    NSLog("Error logging in user: \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    }
                })
        } else {
            Alert.showAlertWithMessage("Enter email and password", fromViewController: self)
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
