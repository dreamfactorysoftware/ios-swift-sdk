//
//  ContactRecord.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

extension Dictionary {
    
    func nonNull(key: Key) -> String {
        let value = self[key]
        if value is NSNull {
            return ""
        } else {
            return value as! String
        }
    }
}

/**
 Contact model
 */
class ContactRecord {
    let id: NSNumber
    var firstName: String
    var lastName: String
    var notes: String?
    var skype: String?
    var twitter: String?
    var imageURL: String?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    init(json: JSON) {
        id = json["id"] as! NSNumber
        firstName = json.nonNull("first_name")
        lastName = json.nonNull("last_name")
    }
}
