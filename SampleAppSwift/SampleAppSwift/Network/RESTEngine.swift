//
//  RESTEngine.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/8/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

// change these values to match your instance
// API key for your app goes here, see apps tab in admin console
let kApiKey = "47f611bfd5da6bc33e01a473142ea048409adb970839c95fa32af28e4c002e79"
let kSessionTokenKey = "SessionToken"
let kBaseInstanceUrl = "https://df-test-gm.enterprise.dreamfactory.com/api/v2"
let kDbServiceName = "db/_table"
let kUserEmail = "UserEmail"
let kPassword = "UserPassword"
let kContainerName = "profile_images"

typealias SuccessClosure = (JSON?) -> Void
typealias ErrorClosure = (NSError) -> Void

final class RESTEngine {
    static let sharedEngine = RESTEngine()
    
    var _sessionToken: String?
    var sessionToken: String? {
        get {
            if _sessionToken == nil {
                _sessionToken = NSUserDefaults.standardUserDefaults().valueForKey(kSessionTokenKey) as? String
            }
            return _sessionToken
        }
        set {
            if let value = newValue {
                NSUserDefaults.standardUserDefaults().setValue(value, forKey: kSessionTokenKey)
                NSUserDefaults.standardUserDefaults().synchronize()
                _sessionToken = value
            } else {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(kSessionTokenKey)
                NSUserDefaults.standardUserDefaults().synchronize()
                _sessionToken = nil
            }
        }
    }
    
    let headerParams: [String: String] = {
        let dict = ["X-DreamFactory-Api-Key": kApiKey]
        return dict
    }()
    
    var sessionHeaderParams: [String: String] {
        var dict = headerParams
        dict["X-DreamFactory-Session-Token"] = sessionToken
        return dict
    }
    
    private let api = NIKApiInvoker.sharedInstance
    
    private init() {
    }
    
    private func callApiWithPath(restApiPath: String, method: String, queryParams: [String: AnyObject]?, body: AnyObject?, headerParams: [String: String]?, contentType: String?, success: SuccessClosure?, failure: ErrorClosure?) {
        api.restPath(restApiPath, method: method, queryParams: queryParams, body: body, headerParams: headerParams, contentType: contentType, completionBlock: { (response, error) -> Void in
            if let error = error where failure != nil {
                failure!(error)
            } else if let success = success {
                success(response)
            }
        })
    }
    
    //MARK: - Authorization methods
    
    func loginWithEmail(email: String, password: String, success: SuccessClosure, failure: ErrorClosure) {
        let resourceName = "user/session"
        let restApiPath = "\(kBaseInstanceUrl)/\(resourceName)"
        let contentType = "application/json"
        let requestBody: AnyObject = ["email": email,
                                      "password": password]
        
        callApiWithPath(restApiPath, method: "POST", queryParams: nil, body: requestBody, headerParams: headerParams, contentType: contentType, success: success, failure: failure)
    }
    
    func registerWithEmail(email: String, password: String, success: SuccessClosure, failure: ErrorClosure) {
        let resourceName = "user/register"
        let restApiPath = "\(kBaseInstanceUrl)/\(resourceName)"
        let contentType = "application/json"
        
        //login after signup
        let queryParams: [String: AnyObject] = ["login": "1"]
        let requestBody: AnyObject = ["email": email,
                                      "password": password,
                                      "first_name": "Address",
                                      "last_name": "Book",
                                      "name": "Address Book User"]
        
        callApiWithPath(restApiPath, method: "POST", queryParams: queryParams, body: requestBody, headerParams: headerParams, contentType: contentType, success: success, failure: failure)
    }
    
    //MARK: - Group methods
    
    func getAddressBookContentFromServerWithSuccess(success: SuccessClosure, failure: ErrorClosure) {
        let serviceName = kDbServiceName
        let tableName = "contact_group"
        let restApiPath = "\(kBaseInstanceUrl)/\(serviceName)/\(tableName)"
        
        let contentType = "application/json"
        
        callApiWithPath(restApiPath, method: "GET", queryParams: nil, body: nil, headerParams: sessionHeaderParams, contentType: contentType, success: success, failure: failure)
    }
    
    private func removeContactGroupRelationsForGroupId(groupId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        // remove all contact-group relations for the group being deleted
        
        // build rest path for request, form is <base instance url>/api/v2/<serviceName>/_table/<tableName>
        let serviceName = kDbServiceName
        let tableName = "contact_group_relationship"
        let restApiPath = "\(kBaseInstanceUrl)/\(serviceName)/\(tableName)"
        
        // create filter to select all contact_group_relationship records that
        // reference the group being deleted
        let queryParams: [String: AnyObject] = ["filter": "contact_group_id=\(groupId)"]
        
        let contentType = "application/json"
        
        callApiWithPath(restApiPath, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, contentType: contentType, success: success, failure: failure)
    }
    
    func removeGroupFromServerWithGroupId(groupId: NSNumber, success: SuccessClosure? = nil, failure: ErrorClosure) {
        // can not delete group until all references to it are removed
        // remove relations -> remove group
        // pass record ID so it knows what group we are removing
        
        removeContactGroupRelationsForGroupId(groupId, success: { _ in
            
            let serviceName = kDbServiceName
            let tableName = "contact_group"
            let restApiPath = "\(kBaseInstanceUrl)/\(serviceName)/\(tableName)"
            
            // delete the record by the record ID
            // form is "ids":"1,2,3"
            let queryParams: [String: AnyObject] = ["ids": "\(groupId)"]
            
            let contentType = "application/json"
            
            self.callApiWithPath(restApiPath, method: "DELETE", queryParams: queryParams, body: nil, headerParams: self.sessionHeaderParams, contentType: contentType, success: success, failure: failure)
            
        }, failure: failure)
    }
}
