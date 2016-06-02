//
//  CustomNavBar.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

class CustomNavBar: UIToolbar {
    var backButton: UIButton!
    var addButton: UIButton!
    var editButton: UIButton!
    var doneButton: UIButton!
    
    private var isShowEdit = false
    private var isShowAdd = false
    private var isShowDone = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
        self.opaque = true
        self.setBackgroundImage(UIImage(named: "phone1"), forToolbarPosition: .Top, barMetrics: .Default)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildLogo() {
        let dfLogo = UIImage(named: "DreamFactory-logo-horiz-filled")!
        let resizable = dfLogo.resizableImageWithCapInsets(UIEdgeInsetsZero, resizingMode: .Stretch)
        let logoView = UIImageView(image: resizable)
        logoView.frame = CGRectMake(0, 0, frame.size.width * 0.45, dfLogo.size.height * dfLogo.size.width / (frame.size.width * 0.5))
        logoView.contentMode = .ScaleAspectFit
        logoView.center = CGPointMake(frame.size.width * 0.48, frame.size.height * 0.6)
        addSubview(logoView)
    }
    
    func buildButtons() {
        backButton = UIButton(type: .System)
        backButton.frame = CGRectMake(frame.size.width * 0.1, 20, 50, 20)
        backButton.setTitleColor(UIColor(red: 216/255.0, green: 122/255.0, blue: 39/255.0, alpha: 1.0), forState: .Normal)
        backButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Regular", size: 17.0)
        backButton.setTitle("Back", forState: .Normal)
        backButton.center = CGPointMake(frame.size.width * 0.1, 40)
        addSubview(backButton)
        showBackButton(false)
        
        addButton = UIButton(type: .System)
        addButton.frame = CGRectMake(frame.size.width * 0.85, 20, 50, 40)
        addButton.setTitleColor(UIColor(red: 107/255.0, green: 170/255.0, blue: 178/255.0, alpha: 1.0), forState: .Normal)
        addButton.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 30.0)
        addButton.setTitle("+", forState: .Normal)
        addButton.center = CGPointMake(frame.size.width * 0.82, 38)
        addSubview(addButton)
        showAddButton(false)
        
        editButton = UIButton(type: .System)
        editButton.frame = CGRectMake(frame.size.width * 0.8, 20, 50, 40)
        editButton.setTitleColor(UIColor(red: 241/255.0, green: 141/255.0, blue: 42/255.0, alpha: 1.0), forState: .Normal)
        editButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Regular", size: 17.0)
        editButton.setTitle("Edit", forState: .Normal)
        editButton.center = CGPointMake(frame.size.width * 0.93, 40)
        addSubview(editButton)
        showEditButton(false)
        
        doneButton = UIButton(type: .System)
        doneButton.frame = CGRectMake(frame.size.width * 0.8, 20, 50, 40)
        doneButton.setTitleColor(UIColor(red: 241/255.0, green: 141/255.0, blue: 42/255.0, alpha: 1.0), forState: .Normal)
        doneButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Regular", size: 17.0)
        doneButton.setTitle("Done", forState: .Normal)
        doneButton.center = CGPointMake(frame.size.width * 0.93, 40)
        addSubview(doneButton)
        showDoneButton(false)
    }
    
    func showEditAndAdd() {
        showAddButton(true)
        showDoneButton(false)
        showEditButton(true)
    }
    
    func showAdd() {
        showAddButton(true)
        showDoneButton(false)
        showEditButton(false)
    }
    
    func showEdit() {
        showAddButton(false)
        showDoneButton(false)
        showEditButton(true)
    }
    
    func showDone() {
        showAddButton(false)
        showDoneButton(true)
        showEditButton(false)
    }
    
    func showEditButton(show: Bool) {
        editButton.hidden = !show
    }
    
    func showAddButton(show: Bool) {
        addButton.hidden = !show
    }
    
    func showBackButton(show: Bool) {
        backButton.hidden = !show
    }
    
    func showDoneButton(show: Bool) {
        doneButton.hidden = !show
    }
    
    func disableAllTouch() {
        userInteractionEnabled = false
    }
    
    func enableAllTouch() {
        userInteractionEnabled = true
    }
}
