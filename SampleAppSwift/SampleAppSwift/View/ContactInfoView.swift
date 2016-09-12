//
//  ContactInfoView.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

private extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
        let emailTest = NSPredicate(format: "SELF MATCHES %@", argumentArray: [emailRegex])
        return emailTest.evaluate(with: self)
    }
}

protocol ContactInfoDelegate: class {
    func onContactTypeClick(_ view: ContactInfoView, withTypes types:[String])
}

class ContactInfoView: UIView, UITextFieldDelegate {
    var record: ContactDetailRecord!
    fileprivate var textFields: [String: UITextField]!
    fileprivate let contactTypes: [String]
    weak var delegate: ContactInfoDelegate!
    var contactType: String! {
        didSet {
            self.textFields["Type"]?.text = contactType
        }
    }
    
    override init(frame: CGRect) {
        self.contactTypes = ["work", "home", "mobile", "other"]
        super.init(frame: frame)
        
        buildContactTextFields(["Type", "Phone", "Email", "Address", "City", "State", "Zip", "Country"])
        
        //resize
        var contectRect = CGRect.zero
        for view in subviews {
            contectRect = contectRect.union(view.frame)
        }
        var oldFrame = self.frame
        oldFrame.size.height = contectRect.size.height
        self.frame = oldFrame
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateRecord() {
        record.type = textValueForKey("Type")
        record.phone = textValueForKey("Phone")
        record.email = textValueForKey("Email")
        record.address = textValueForKey("Address")
        record.city = textValueForKey("City")
        record.state = textValueForKey("State")
        record.zipCode = textValueForKey("Zip")
        record.country = textValueForKey("Country")
    }

    /**
     Validate email only
     other validations can be added, e.g. phone number, address
    */
    func validateInfoWithResult(_ result: (Bool, String?) -> Void) {
        let email = textValueForKey("Email")
        if !email.isEmpty && !email.isValidEmail() {
            return result(false, "Not a valid email")
        }
        
        return result(true, nil)
    }
    
    func buildToDiciontary() -> [String: AnyObject] {
        var json = [
                "contact_id": record.contactId,
                "info_type": record.type,
                "phone": record.phone,
                "email": record.email,
                "address": record.address,
                "city": record.city,
                "state": record.state,
                "zip": record.zipCode,
                "country": record.country] as [String : Any]
        if record.id != 0 {
            json["id"] = record.id
        }
        return json as [String : AnyObject]
    }
    
    func updateFields() {
        putFieldIn(record.type, key: "Type")
        putFieldIn(record.phone, key: "Phone")
        putFieldIn(record.email, key: "Email")
        putFieldIn(record.address, key: "Address")
        putFieldIn(record.city, key: "City")
        putFieldIn(record.state, key: "State")
        putFieldIn(record.zipCode, key: "Zip")
        putFieldIn(record.country, key: "Country")
        
        reloadInputViews()
        setNeedsDisplay()
    }
    
    fileprivate func textValueForKey(_ key: String) -> String {
        return textFields[key]!.text!
    }
    
    fileprivate func putFieldIn(_ value: String, key: String) {
        if !value.isEmpty {
            textFields[key]?.text = value
        } else {
            textFields[key]?.text = ""
        }
    }
    
    fileprivate func buildContactTextFields(_ names: [String]) {
        var y: CGFloat = 0
        
        textFields = [:]
        
        for field in names {
            let textField = UITextField(frame: CGRect(x: frame.size.width * 0.05, y: y, width: frame.size.width * 0.9, height: 35))
            textField.placeholder = field
            textField.font = UIFont(name: "Helvetica Neue", size: 20.0)
            textField.backgroundColor = UIColor.white
            textField.layer.cornerRadius = 5
            addSubview(textField)
            
            textFields[field] = textField
            y += 40
            
            if field == "Type" {
                textField.isEnabled = false
                let button = UIButton(type: .system)
                button.frame = textField.frame
                button.setTitle("", for: UIControlState())
                button.backgroundColor = UIColor.clear
                button.addTarget(self, action: #selector(onContactTypeClick), for: .touchDown)
                self.addSubview(button)
                textField.text = contactTypes[0]
            }
        }
    }
    
    func onContactTypeClick() {
        delegate.onContactTypeClick(self, withTypes: self.contactTypes)
    }
    
    func setTextFieldsDelegate(_ delegate: UITextFieldDelegate) {
        for textField in textFields.values {
            textField.delegate = delegate
        }
    }
}
