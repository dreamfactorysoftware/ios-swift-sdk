//
//  NIKFile.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

/**
 Use this object when building a request with a file. Pass it
 in as the body of the request to ensure that the file is built
 and sent up properly, especially with images.
*/
class NIKFile {
    let name: String
    let mimeType: String
    let data: Data
    
    init(name: String, mimeType: String, data: Data) {
        self.name = name
        self.mimeType = mimeType
        self.data = data
    }
}
