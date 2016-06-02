//
//  ContactDetailRecord.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

/**
 Contact info model
 */
class ContactDetailRecord {
    var id: NSNumber = NSNumber(integer: 0)
    var type: String!
    var phone: String!
    var email: String!
    var state: String!
    var zipCode: String!
    var country: String!
    var city: String!
    var address: String!
    var contactId: NSNumber!
    
    init() {
    }
    
    init(json: JSON) {
        id = json["id"] as! NSNumber
        address = json.nonNull("address")
        city = json.nonNull("city")
        country = json.nonNull("country")
        email = json.nonNull("email")
        state = json.nonNull("state")
        zipCode = json.nonNull("zip")
        type = json.nonNull("info_type")
        phone = json.nonNull("phone")
        contactId = json["contact_id"] as! NSNumber
    }
}
