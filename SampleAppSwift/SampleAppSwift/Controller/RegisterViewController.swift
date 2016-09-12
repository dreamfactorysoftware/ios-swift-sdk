//
//  RegisterViewController.swift
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


class RegisterViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        passwordTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showBackButton(true)
        navBar.showAddButton(false)
        navBar.showEditButton(false)
    }
    
    @IBAction func onSubmitClick(_ sender: AnyObject) {
        self.view.endEditing(true)
        if emailTextField.text?.characters.count > 0 && passwordTextField.text?.characters.count > 0 {
            
            RESTEngine.sharedEngine.registerWithEmail(emailTextField.text!, password: passwordTextField.text!, success: { response in
                RESTEngine.sharedEngine.sessionToken = response!["session_token"] as? String
                let defaults = UserDefaults.standard
                defaults.setValue(self.emailTextField.text!, forKey: kUserEmail)
                defaults.setValue(self.passwordTextField.text!, forKey: kPassword)
                defaults.synchronize()
                
                DispatchQueue.main.async {
                    self.showAddressBookViewController()
                }
                }, failure: { error in
                    NSLog("Error registering new user: \(error)")
                    DispatchQueue.main.async {
                        Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    }
            })
        } else {
            let alert = UIAlertController(title: nil, message: "Enter email and password", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func showAddressBookViewController() {
        let addressBookViewController = self.storyboard?.instantiateViewController(withIdentifier: "AddressBookViewController")
        self.navigationController?.pushViewController(addressBookViewController!, animated: true)
    }
}
