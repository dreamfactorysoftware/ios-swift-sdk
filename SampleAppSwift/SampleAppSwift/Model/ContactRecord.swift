//
//  ContactRecord.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

/**
 Contact model
 */
struct ContactRecord {
    let id: NSNumber
    var firstName: String
    var lastName: String
    var notes: String?
    var skype: String?
    var twitter: String?
    var imageURL: String?
}
