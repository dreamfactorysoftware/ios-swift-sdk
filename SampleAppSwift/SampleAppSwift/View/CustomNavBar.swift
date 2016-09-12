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
    
    fileprivate var isShowEdit = false
    fileprivate var isShowAdd = false
    fileprivate var isShowDone = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
        self.isOpaque = true
        self.setBackgroundImage(UIImage(named: "phone1"), forToolbarPosition: .top, barMetrics: .default)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildLogo() {
        let dfLogo = UIImage(named: "DreamFactory-logo-horiz-filled")!
        let resizable = dfLogo.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
        let logoView = UIImageView(image: resizable)
        logoView.frame = CGRect(x: 0, y: 0, width: frame.size.width * 0.45, height: dfLogo.size.height * dfLogo.size.width / (frame.size.width * 0.5))
        logoView.contentMode = .scaleAspectFit
        logoView.center = CGPoint(x: frame.size.width * 0.48, y: frame.size.height * 0.6)
        addSubview(logoView)
    }
    
    func buildButtons() {
        backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: frame.size.width * 0.1, y: 20, width: 50, height: 20)
        backButton.setTitleColor(UIColor(red: 216/255.0, green: 122/255.0, blue: 39/255.0, alpha: 1.0), for: UIControlState())
        backButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Regular", size: 17.0)
        backButton.setTitle("Back", for: UIControlState())
        backButton.center = CGPoint(x: frame.size.width * 0.1, y: 40)
        addSubview(backButton)
        showBackButton(false)
        
        addButton = UIButton(type: .system)
        addButton.frame = CGRect(x: frame.size.width * 0.85, y: 20, width: 50, height: 40)
        addButton.setTitleColor(UIColor(red: 107/255.0, green: 170/255.0, blue: 178/255.0, alpha: 1.0), for: UIControlState())
        addButton.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 30.0)
        addButton.setTitle("+", for: UIControlState())
        addButton.center = CGPoint(x: frame.size.width * 0.82, y: 38)
        addSubview(addButton)
        showAddButton(false)
        
        editButton = UIButton(type: .system)
        editButton.frame = CGRect(x: frame.size.width * 0.8, y: 20, width: 50, height: 40)
        editButton.setTitleColor(UIColor(red: 241/255.0, green: 141/255.0, blue: 42/255.0, alpha: 1.0), for: UIControlState())
        editButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Regular", size: 17.0)
        editButton.setTitle("Edit", for: UIControlState())
        editButton.center = CGPoint(x: frame.size.width * 0.93, y: 40)
        addSubview(editButton)
        showEditButton(false)
        
        doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: frame.size.width * 0.8, y: 20, width: 50, height: 40)
        doneButton.setTitleColor(UIColor(red: 241/255.0, green: 141/255.0, blue: 42/255.0, alpha: 1.0), for: UIControlState())
        doneButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Regular", size: 17.0)
        doneButton.setTitle("Done", for: UIControlState())
        doneButton.center = CGPoint(x: frame.size.width * 0.93, y: 40)
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
    
    func showEditButton(_ show: Bool) {
        editButton.isHidden = !show
    }
    
    func showAddButton(_ show: Bool) {
        addButton.isHidden = !show
    }
    
    func showBackButton(_ show: Bool) {
        backButton.isHidden = !show
    }
    
    func showDoneButton(_ show: Bool) {
        doneButton.isHidden = !show
    }
    
    func disableAllTouch() {
        isUserInteractionEnabled = false
    }
    
    func enableAllTouch() {
        isUserInteractionEnabled = true
    }
}
