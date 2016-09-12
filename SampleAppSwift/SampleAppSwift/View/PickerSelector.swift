//
//  PickerSelector.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/15/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

protocol PickerSelectorDelegate: class {
    func pickerSelector(_ selector: PickerSelector, selectedValue value: String, index: Int)
}

class PickerSelector: UIViewController, UIPickerViewDataSource {
    @IBOutlet fileprivate weak var pickerView: UIPickerView!
    @IBOutlet fileprivate weak var cancelButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var doneButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var optionsToolBar: UIToolbar!
    
    var pickerData: [String] = []
    weak var delegate: PickerSelectorDelegate!
    fileprivate var background: UIView!
    fileprivate var origin: CGPoint!
    
    convenience init() {
        self.init(nibName: "PickerSelector", bundle: Bundle(for: type(of: self)))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.view.addSubview(pickerView)
        var frame = pickerView.frame
        frame.origin.y = optionsToolBar.frame.maxY
        pickerView.frame = frame
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showPickerOver(_ parent: UIViewController) {
        let window = UIApplication.shared.keyWindow!
        
        background = UIView(frame: window.bounds)
        background.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        window.addSubview(background)
        window.addSubview(self.view)
        parent.addChildViewController(self)
        
        var frame = self.view.frame
        let rotateAngle: CGFloat = 0.0
        let screenSize = CGSize(width: window.frame.size.width, height: pickerSize.height)
        origin = CGPoint(x: 0, y: window.bounds.maxY)
        let target = CGPoint(x: 0, y: origin.y - frame.height)
        
        self.view.transform = CGAffineTransform(rotationAngle: rotateAngle)
        frame = self.view.frame
        frame.size = screenSize
        frame.origin = origin
        self.view.frame = frame
        
        UIView.animate(withDuration: 0.3, animations: {
            self.background.backgroundColor = self.background.backgroundColor?.withAlphaComponent(0.5)
            frame = self.view.frame
            frame.origin = target
            self.view.frame = frame
        }) 
        pickerView.reloadAllComponents()
    }
    
    fileprivate var pickerSize: CGSize {
        var size = view.frame.size
        size.height = optionsToolBar.frame.height + pickerView.frame.height
        size.width = pickerView.frame.width
        return size
    }
    
    @IBAction func setAction(_ sender: AnyObject) {
        if let delegate = delegate , pickerData.count > 0 {
            let index = pickerView.selectedRow(inComponent: 0)
            delegate.pickerSelector(self, selectedValue: pickerData[index], index: index)
        }
        dismissPicker()
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        dismissPicker()
    }
    
    fileprivate func dismissPicker() {
        UIView.animate(withDuration: 0.3, animations: {
            self.background.backgroundColor = self.background.backgroundColor?.withAlphaComponent(0.0)
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
}
