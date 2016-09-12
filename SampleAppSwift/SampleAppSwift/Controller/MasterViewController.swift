//
//  MasterViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MasterViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionLabel.text = "Version \(kAppVersion)"
        
        // check if login credentials are already stored
        let userEmail = UserDefaults.standard.value(forKey: kUserEmail) as? String
        let userPassword = UserDefaults.standard.value(forKey: kPassword) as? String
        
        emailTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        passwordTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        
        if userEmail?.characters.count > 0 && userPassword?.characters.count > 0 {
            emailTextField.text = userEmail
            passwordTextField.text = userPassword
        }
        
        navBar.backButton.addTarget(self, action: #selector(onBackButtonClick), for: .touchDown)
    }
    
    func onBackButtonClick() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showBackButton(false)
        navBar.showAddButton(false)
        navBar.showEditButton(false)
        navBar.showDoneButton(false)
    }
    override func viewDidAppear(_ animated: Bool) {
        if !RESTEngine.sharedEngine.isConfigured() {
            Alert.showAlertWithMessage("RESTEngine is not configured.\n\nPlease see README.md.", fromViewController: self)
        }
    }

    @IBAction func onRegisterClick(_ sender: AnyObject) {
        showRegisterViewController()
    }
    
    @IBAction func onSignInClick(_ sender: AnyObject) {
        self.view.endEditing(true)
        
        //log in using the generic API
        if emailTextField.text?.characters.count > 0 && passwordTextField.text?.characters.count > 0 {
            
            RESTEngine.sharedEngine.loginWithEmail(emailTextField.text!, password: passwordTextField.text!,
                success: { response in
                    RESTEngine.sharedEngine.sessionToken = response!["session_token"] as? String
                    let defaults = UserDefaults.standard
                    defaults.setValue(self.emailTextField.text!, forKey: kUserEmail)
                    defaults.setValue(self.passwordTextField.text!, forKey: kPassword)
                    defaults.synchronize()
                    DispatchQueue.main.async {
                        self.showAddressBookViewController()
                    }
                }, failure: { error in
                    NSLog("Error logging in user: \(error)")
                    DispatchQueue.main.async {
                        Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    }
                })
        } else {
            Alert.showAlertWithMessage("Enter email and password", fromViewController: self)
        }
    }
    
    fileprivate func showAddressBookViewController() {
        let addressBookViewController = self.storyboard?.instantiateViewController(withIdentifier: "AddressBookViewController")
        self.navigationController?.pushViewController(addressBookViewController!, animated: true)
    }
    
    fileprivate func showRegisterViewController() {
        let registerViewController = self.storyboard?.instantiateViewController(withIdentifier: "RegisterViewController")
        self.navigationController?.pushViewController(registerViewController!, animated: true)
    }
}
