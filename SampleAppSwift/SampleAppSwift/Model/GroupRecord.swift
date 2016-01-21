//
//  GroupRecord.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

typealias JSON = [String: AnyObject]
typealias JSONArray = [JSON]

/**
 Group model
*/
class GroupRecord {
    let id: NSNumber
    var name: String
    
    init(json: JSON) {
        id = json["id"] as! NSNumber
        name = json["name"] as! String
    }
}
