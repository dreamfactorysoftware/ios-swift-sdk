//
//  UIUtils.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/15/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class Alert {
    
    static func showAlertWithMessage(message: String, fromViewController vc: UIViewController) {
        let alert = UIAlertView(title: nil, message: message, delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
}