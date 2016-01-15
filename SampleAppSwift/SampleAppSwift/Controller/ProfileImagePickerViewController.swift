//
//  ProfileImagePickerViewController.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/5/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

protocol ProfileImagePickerDelegate: class {
    func didSelectItem(item: String)
    func didSelectItem(item: String, withImage image: UIImage)
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let navBar = self.navBar
        navBar.showDone()
        self.navBar.doneButton.addTarget(self, action: "onDoneButtonClick", forControlEvents: .TouchDown)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navBar.doneButton.removeTarget(self, action: "onDoneButtonClick", forControlEvents: .TouchDown)
    }
    
    @IBAction func onChooseImageClick() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        presentViewController(imagePicker, animated: true, completion: nil)
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
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    //MARK: - Image picker delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageToUpload = image
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - Tableview data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageListContentArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("profileImageTableViewCell", forIndexPath: indexPath)
        cell.textLabel?.text = imageListContentArray[indexPath.row]
        
        return cell
    }
    
    //MARK: - Tableview delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let toPass = imageListContentArray[indexPath.row]
        delegate?.didSelectItem(toPass)
    }
    
    //MARK: - Private methods
    
    private func getImageListFromServer() {
        
        RESTEngine.sharedEngine.getImageListFromServerWithContactId(record.id, success: { response in
            self.imageListContentArray.removeAll()
            let records = response!["file"] as! JSONArray
            for record in records {
                if let record = record["name"] as? String {
                    self.imageListContentArray.append(record)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
            
            }, failure: { error in
                // check if the error is file not found
                if error.code == 404 {
                    let decode = error.userInfo["error"]?.firstItem as? JSON
                    let message = decode?["message"] as? String
                    if message != nil && message!.containsString("does not exist in storage") {
                        NSLog("Warning: Error getting profile image list data from server: \(message)")
                        return
                    }
                }
                // else report normally
                NSLog("Error getting profile image list data from server: \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    Alert.showAlertWithMessage(error.errorMessage, fromViewController: self)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        })
    }
}
