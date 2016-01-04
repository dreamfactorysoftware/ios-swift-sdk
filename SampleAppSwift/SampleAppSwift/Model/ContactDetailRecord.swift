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
struct ContactDetailRecord {
    let id: NSNumber
    var type: String
    var phone: String
    var email: String
    var state: String
    var zipCode: String
    var country: String
    var city: String
    var address: String
    let contactId: NSNumber
}
