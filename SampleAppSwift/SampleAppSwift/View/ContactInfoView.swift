//
//  ContactInfoView.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class ContactInfoView: UIView {
    var record: ContactDetailRecord!
    private var textFields: [String: UITextField]!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        buildContactTextFields(["Type", "Phone", "Email", "Address", "City", "State", "Zip", "Country"], y: 0)
        
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
    
    func buildToDiciontary() -> [String: AnyObject] {
        return [:]
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
    
    private func buildContactTextFields(names: [String], var y: CGFloat) {
        y += 30
        
        textFields = [:]
        
        for field in names {
            let textField = UITextField(frame: CGRectMake(frame.size.width * 0.05, y, frame.size.width * 0.9, 35))
            textField.placeholder = field
            textField.font = UIFont(name: "HelveticaNeue-Regular", size: 20.0)
            textField.backgroundColor = UIColor.whiteColor()
            textField.layer.cornerRadius = 5
            addSubview(textField)
            
            textFields[field] = textField
            y += 40
        }
    }
}
