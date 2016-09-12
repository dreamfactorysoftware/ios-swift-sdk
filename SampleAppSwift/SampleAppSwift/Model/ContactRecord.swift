//
//  ContactRecord.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

extension Dictionary {
    
    func nonNull(_ key: Key) -> String {
        let value = self[key]
        
        if let sValue = value as? String {
            return sValue
        }
        else if value is NSNull {
            return ""
        } else {
            return value as! String
        }
    }
}

/**
 Contact model
 */
class ContactRecord: Equatable {
    var id: NSNumber = 0
    var firstName: String = ""
    var lastName: String = ""
    var notes: String = ""
    var skype: String = ""
    var twitter: String = ""
    var imageURL: String = ""
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    init() {
    }
    
    init(json: JSON) {
        id = json["id"] as! NSNumber
        firstName = json.nonNull("first_name")
        lastName = json.nonNull("last_name")
        
        if json["notes"] != nil {
            notes = json.nonNull("notes")
        }
        if json["skype"] != nil {
            skype = json.nonNull("skype")
        }
        if json["twitter"] != nil {
            twitter = json.nonNull("twitter")
        }
        if json["image_url"] != nil {
            imageURL = json.nonNull("image_url")
        }
    }
}

func ==(lhs: ContactRecord, rhs: ContactRecord) -> Bool {
    return lhs.id.isEqual(to: rhs.id)
}
