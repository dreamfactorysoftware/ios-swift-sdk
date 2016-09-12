//
//  ProfileImagePickerViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

protocol ProfileImagePickerDelegate: class {
    func didSelectItem(_ item: String)
    func didSelectItem(_ item: String, withImage image: UIImage)
}

class ProfileImagePickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var imageNameTextField: UITextField!
    
    // set only when editing an existing contact
    // the contact we are choosing a profile image for
    var record: ContactRecord!
    
    // holds image picked from the camera roll
    var imageToUpload: UIImage?
    
    // list of available profile images
    var imageListContentArray: [String] = []
    
    weak var delegate: ProfileImagePickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getImageListFromServer()
        
        imageNameTextField.setValue(UIColor(red: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")
        tableView.contentInset = UIEdgeInsetsMake(-70, 0, -20, 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showDone()
        self.navBar.doneButton.addTarget(self, action: #selector(onDoneButtonClick), for: .touchDown)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.doneButton.removeTarget(self, action: #selector(onDoneButtonClick), for: .touchDown)
    }
    
    @IBAction func onChooseImageClick() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func onDoneButtonClick() {
        // actually put image up on the server when the contact gets created
        if let imageToUpload = imageToUpload {
            // if we chose an image to upload
            var imageName: String!
            if imageNameTextField.text!.isEmpty {
                imageName = "profileImage"
            } else {
                imageName = imageNameTextField.text!
            }
            delegate?.didSelectItem(imageName, withImage: imageToUpload)
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    //MARK: - Image picker delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageToUpload = image
        
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Tableview data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageListContentArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileImageTableViewCell", for: indexPath)
        cell.textLabel?.text = imageListContentArray[(indexPath as NSIndexPath).row]
        
        return cell
    }
    
    //MARK: - Tableview delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let toPass = imageListContentArray[(indexPath as NSIndexPath).row]
        delegate?.didSelectItem(toPass)
    }
    
    //MARK: - Private methods
    
    fileprivate func getImageListFromServer() {
        
        RESTEngine.sharedEngine.getImageListFromServerWithContactId(record.id, success: { response in
            self.imageListContentArray.removeAll()
            let records = response!["file"] as! JSONArray
            for record in records {
                if let record = record["name"] as? String {
                    self.imageListContentArray.append(record)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            }, failure: { error in
                // check if the error is file not found
                if error.code == 404 {
                    let decode = (error.userInfo["error"] as AnyObject).firstItem as? JSON
                    let message = decode?["message"] as? String
                    if message != nil && message!.contains("does not exist in storage") {
                        NSLog("Warning: Error getting profile image list data from server: \(message)")
                        return
                    }
                }
                // else report normally
                NSLog("Error getting profile image list data from server: \(error)")
                DispatchQueue.main.async {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
        })
    }
}
