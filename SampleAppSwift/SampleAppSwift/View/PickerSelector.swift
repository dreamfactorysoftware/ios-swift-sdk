//
//  PickerSelector.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/15/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

protocol PickerSelectorDelegate: class {
    func pickerSelector(selector: PickerSelector, selectedValue value: String, index: Int)
}

class PickerSelector: UIViewController, UIPickerViewDataSource {
    @IBOutlet private weak var pickerView: UIPickerView!
    @IBOutlet private weak var cancelButton: UIBarButtonItem!
    @IBOutlet private weak var doneButton: UIBarButtonItem!
    @IBOutlet private weak var optionsToolBar: UIToolbar!
    
    var pickerData: [String] = []
    weak var delegate: PickerSelectorDelegate!
    private var background: UIView!
    private var origin: CGPoint!
    
    convenience init() {
        self.init(nibName: "PickerSelector", bundle: NSBundle(forClass: self.dynamicType))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.view.addSubview(pickerView)
        var frame = pickerView.frame
        frame.origin.y = CGRectGetMaxY(optionsToolBar.frame)
        pickerView.frame = frame
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showPickerOver(parent: UIViewController) {
        let window = UIApplication.sharedApplication().keyWindow!
        
        background = UIView(frame: window.bounds)
        background.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.0)
        window.addSubview(background)
        window.addSubview(self.view)
        parent.addChildViewController(self)
        
        var frame = self.view.frame
        let rotateAngle: CGFloat = 0.0
        let screenSize = CGSizeMake(window.frame.size.width, pickerSize.height)
        origin = CGPointMake(0, CGRectGetMaxY(window.bounds))
        let target = CGPointMake(0, origin.y - CGRectGetHeight(frame))
        
        self.view.transform = CGAffineTransformMakeRotation(rotateAngle)
        frame = self.view.frame
        frame.size = screenSize
        frame.origin = origin
        self.view.frame = frame
        
        UIView.animateWithDuration(0.3) {
            self.background.backgroundColor = self.background.backgroundColor?.colorWithAlphaComponent(0.5)
            frame = self.view.frame
            frame.origin = target
            self.view.frame = frame
        }
        pickerView.reloadAllComponents()
    }
    
    private var pickerSize: CGSize {
        var size = view.frame.size
        size.height = CGRectGetHeight(optionsToolBar.frame) + CGRectGetHeight(pickerView.frame)
        size.width = CGRectGetWidth(pickerView.frame)
        return size
    }
    
    @IBAction func setAction(sender: AnyObject) {
        if let delegate = delegate where pickerData.count > 0 {
            let index = pickerView.selectedRowInComponent(0)
            delegate.pickerSelector(self, selectedValue: pickerData[index], index: index)
        }
        dismissPicker()
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        dismissPicker()
    }
    
    private func dismissPicker() {
        UIView.animateWithDuration(0.3, animations: {
            self.background.backgroundColor = self.background.backgroundColor?.colorWithAlphaComponent(0.0)
            var frame = self.view.frame
            frame.origin = self.origin
            self.view.frame = frame
        }, completion: { _ in
            self.background.removeFromSuperview()
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        })
    }
    
    //MARK: - Picker datasource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
}
