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
        return emailTest.evaluateWithObject(self)
    }
}

protocol ContactInfoDelegate: class {
    func onContactTypeClick(view: ContactInfoView, withTypes types:[String])
}

class ContactInfoView: UIView, UITextFieldDelegate {
    var record: ContactDetailRecord!
    private var textFields: [String: UITextField]!
    private let contactTypes: [String]
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
        var contectRect = CGRectZero
        for view in subviews {
            contectRect = CGRectUnion(contectRect, view.frame)
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
    func validateInfoWithResult(result: (Bool, String?) -> Void) {
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
                "country": record.country]
        if record.id != 0 {
            json["id"] = record.id
        }
        return json
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
    
    private func textValueForKey(key: String) -> String {
        return textFields[key]!.text!
    }
    
    private func putFieldIn(value: String, key: String) {
        if !value.isEmpty {
            textFields[key]?.text = value
        } else {
            textFields[key]?.text = ""
        }
    }
    
    private func buildContactTextFields(names: [String]) {
        var y: CGFloat = 0
        
        textFields = [:]
        
        for field in names {
            let textField = UITextField(frame: CGRectMake(frame.size.width * 0.05, y, frame.size.width * 0.9, 35))
            textField.placeholder = field
            textField.font = UIFont(name: "Helvetica Neue", size: 20.0)
            textField.backgroundColor = UIColor.whiteColor()
            textField.layer.cornerRadius = 5
            addSubview(textField)
            
            textFields[field] = textField
            y += 40
            
            if field == "Type" {
                textField.enabled = false
                let button = UIButton(type: .System)
                button.frame = textField.frame
                button.setTitle("", forState: .Normal)
                button.backgroundColor = UIColor.clearColor()
                button.addTarget(self, action: #selector(onContactTypeClick), forControlEvents: .TouchDown)
                self.addSubview(button)
                textField.text = contactTypes[0]
            }
        }
    }
    
    func onContactTypeClick() {
        delegate.onContactTypeClick(self, withTypes: self.contactTypes)
    }
    
    func setTextFieldsDelegate(delegate: UITextFieldDelegate) {
        for textField in textFields.values {
            textField.delegate = delegate
        }
    }
}
