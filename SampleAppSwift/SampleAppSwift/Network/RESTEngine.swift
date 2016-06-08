//
//  RESTEngine.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/8/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

let kAppVersion = "1.0.2"

// change kApiKey and kBaseInstanceUrl to match your app and instance

// API key for your app goes here. See README.md or https://github.com/dreamfactorysoftware/ios-swift-sdk
private let kApiKey = ""
private let kBaseInstanceUrl = "http://localhost:8080/api/v2"
private let kSessionTokenKey = "SessionToken"
private let kDbServiceName = "db/_table"
private let kContainerName = "profile_images"

let kUserEmail = "UserEmail"
let kPassword = "UserPassword"

typealias SuccessClosure = (JSON?) -> Void
typealias ErrorClosure = (NSError) -> Void

extension NSError {
    
    var errorMessage: String {
        if let errorMessage = self.userInfo["error"]?["message"] as? String {
            return errorMessage
        }
        return "Unknown error occurred"
    }
}

/**
 Routing to different type of API resources
 */
enum Routing {
    case User(resourseName: String)
    case Service(tableName: String)
    case ResourceFolder(folderPath: String)
    case ResourceFile(folderPath: String, fileName: String)
    
    var path: String {
        switch self {
            //rest path for request, form is <base instance url>/api/v2/user/resourceName
        case let .User(resourceName):
            return "\(kBaseInstanceUrl)/user/\(resourceName)"
            
            //rest path for request, form is <base instance url>/api/v2/<serviceName>/<tableName>
        case let .Service(tableName):
            return "\(kBaseInstanceUrl)/\(kDbServiceName)/\(tableName)"
            
            // rest path for request, form is <base instance url>/api/v2/files/container/<folder path>/
        case let .ResourceFolder(folderPath):
            return "\(kBaseInstanceUrl)/files/\(kContainerName)/\(folderPath)/"
            
            //rest path for request, form is <base instance url>/api/v2/files/container/<folder path>/filename
        case let .ResourceFile(folderPath, fileName):
            return "\(kBaseInstanceUrl)/files/\(kContainerName)/\(folderPath)/\(fileName)"
        }
    }
}

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
    func isConfigured() -> Bool {
        return kApiKey != ""
    }
    private func callApiWithPath(restApiPath: String, method: String, queryParams: [String: AnyObject]?, body: AnyObject?, headerParams: [String: String]?, success: SuccessClosure?, failure: ErrorClosure?) {
        api.restPath(restApiPath, method: method, queryParams: queryParams, body: body, headerParams: headerParams, contentType: "application/json", completionBlock: { (response, error) -> Void in
            if let error = error where failure != nil {
                failure!(error)
            } else if let success = success {
                success(response)
            }
        })
    }
    
    // MARK: Helpers for POST/PUT/PATCH entity wrapping
 
    private func toResourceArray(entity:JSON) -> JSON {
        let jsonResource: JSON = ["resource" : [entity]] // DreamFactory REST API body with {"resource" = [ { record } ] }
        return jsonResource
    }
    private func toResourceArray(jsonArray:JSONArray) -> JSON {
        let jsonResource: JSON = ["resource" : jsonArray] // DreamFactory REST API body with {"resource" = [ { record } ] }
        return jsonResource
    }
    
    //MARK: - Authorization methods

    /**
    Sign in user
    */
    func loginWithEmail(email: String, password: String, success: SuccessClosure, failure: ErrorClosure) {
        
        let requestBody: [String: AnyObject] = ["email": email,
            "password": password]
        
        callApiWithPath(Routing.User(resourseName: "session").path, method: "POST", queryParams: nil, body: requestBody, headerParams: headerParams, success: success, failure: failure)
    }
    
    /**
     Register new user
     */
    func registerWithEmail(email: String, password: String, success: SuccessClosure, failure: ErrorClosure) {
        
        //login after signup
        let queryParams: [String: AnyObject] = ["login": "1"]
        let requestBody: [String: AnyObject] = ["email": email,
            "password": password,
            "first_name": "Address",
            "last_name": "Book",
            "name": "Address Book User"]
        
        callApiWithPath(Routing.User(resourseName: "register").path, method: "POST", queryParams: queryParams, body: requestBody, headerParams: headerParams, success: success, failure: failure)
    }
    
    //MARK: - Group methods
    
    /**
    Get all the groups from the database
    */
    func getAddressBookContentFromServerWithSuccess(success: SuccessClosure, failure: ErrorClosure) {
        
        callApiWithPath(Routing.Service(tableName: "contact_group").path, method: "GET", queryParams: nil, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    private func removeContactGroupRelationsForGroupId(groupId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        // remove all contact-group relations for the group being deleted
        
        // create filter to select all contact_group_relationship records that
        // reference the group being deleted
        let queryParams: [String: AnyObject] = ["filter": "contact_group_id=\(groupId)"]
        
        callApiWithPath(Routing.Service(tableName: "contact_group_relationship").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Remove group from server
     */
    func removeGroupFromServerWithGroupId(groupId: NSNumber, success: SuccessClosure? = nil, failure: ErrorClosure) {
        // can not delete group until all references to it are removed
        // remove relations -> remove group
        // pass record ID so it knows what group we are removing
        
        removeContactGroupRelationsForGroupId(groupId, success: { _ in
            // delete the record by the record ID
            // form is "ids":"1,2,3"
            let queryParams: [String: AnyObject] = ["ids": "\(groupId)"]
            
            self.callApiWithPath(Routing.Service(tableName: "contact_group").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: self.sessionHeaderParams, success: success, failure: failure)
            
            }, failure: failure)
    }
    
    /**
     Add new group with name and contacts
     */
    func addGroupToServerWithName(name: String, contactIds: [NSNumber]?, success: SuccessClosure, failure: ErrorClosure) {
        let requestBody = toResourceArray(["name": name])
        
        callApiWithPath(Routing.Service(tableName: "contact_group").path, method: "POST", queryParams: nil, body: requestBody, headerParams: sessionHeaderParams, success: { response in
            // get the id of the new group, then add the relations
            let records = response!["resource"] as! JSONArray
            for recordInfo in records {
                self.addGroupContactRelationsForGroupWithId(recordInfo["id"] as! NSNumber, contactIds: contactIds, success: success, failure: failure)
            }
            }, failure: failure)
    }
    
    private func addGroupContactRelationsForGroupWithId(groupId: NSNumber, contactIds: [NSNumber]?, success: SuccessClosure, failure: ErrorClosure) {
        
        // if there are contacts to add skip server update
        if contactIds == nil || contactIds!.count == 0 {
            success(nil)
            return
        }
        
        // build request body
        /*
        *  structure of request is:
        *  {
        *      "resource":[
        *          {
        *             "contact_group_id":id,
        *             "contact_id":id"
        *          },
        *          {...}
        *      ]
        *  }
        */
        var records: JSONArray = []
        for contactId in contactIds! {
            records.append(["contact_group_id": groupId,
                "contact_id": contactId])
        }
        
        let requestBody: [String: AnyObject] = ["resource": records]
        
        callApiWithPath(Routing.Service(tableName: "contact_group_relationship").path, method: "POST", queryParams: nil, body: requestBody, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Update group with new name and contacts
     */
    func updateGroupWithId(groupId: NSNumber, name: String, oldName: String, removedContactIds: [NSNumber]?, addedContactIds: [NSNumber]?, success: SuccessClosure, failure: ErrorClosure) {
        
        //if name didn't change skip server update
        if name == oldName {
            removeGroupContactRelationsForGroupWithId(groupId, contactIds: removedContactIds, success: { _ in
                self.addGroupContactRelationsForGroupWithId(groupId, contactIds: addedContactIds, success: success, failure: failure)
                }, failure: failure)
            return
        }
        
        // update name
        let queryParams: [String: AnyObject] = ["ids": groupId.stringValue]
        let requestBody = toResourceArray(["name": name])
        
        callApiWithPath(Routing.Service(tableName: "contact_group").path, method: "PATCH", queryParams: queryParams, body: requestBody, headerParams: sessionHeaderParams, success: { _ in
            self.removeGroupContactRelationsForGroupWithId(groupId, contactIds: removedContactIds, success: { _ in
                self.addGroupContactRelationsForGroupWithId(groupId, contactIds: addedContactIds, success: success, failure: failure)
                }, failure: failure)
            }, failure: failure)
    }
    
    private func removeGroupContactRelationsForGroupWithId(groupId: NSNumber, contactIds: [NSNumber]?, success: SuccessClosure, failure: ErrorClosure) {
        
        // if there are no contacts to remove skip server update
        if contactIds == nil || contactIds!.count == 0 {
            success(nil)
            return
        }
        
        // remove contact-group relations
        
        // do not know the ID of the record to remove
        // one value for groupId, but many values for contactId
        // instead of making a long SQL query, change what we use as identifiers
        let queryParams: [String: AnyObject] = ["id_field": "contact_group_id,contact_id"]
        
        // build request body
        /*
        *  structure of request is:
        *  {
        *      "resource":[
        *          {
        *             "contact_group_id":id,
        *             "contact_id":id"
        *          },
        *          {...}
        *      ]
        *  }
        */
        var records: JSONArray = []
        for contactId in contactIds! {
            records.append(["contact_group_id": groupId,
                "contact_id": contactId])
        }
        
        let requestBody: [String: AnyObject] = ["resource": records]
        
        callApiWithPath(Routing.Service(tableName: "contact_group_relationship").path, method: "DELETE", queryParams: queryParams, body: requestBody, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    //MARK: - Contact methods
    
    /**
    Get all the contacts from the database
    */
    func getContactListFromServerWithSuccess(success: SuccessClosure, failure: ErrorClosure) {
        // only need to get the contactId and full contact name
        // set the fields param to give us just the fields we need
        let queryParams: [String: AnyObject] = ["fields": "id,first_name,last_name"]
        
        callApiWithPath(Routing.Service(tableName: "contact").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get the list of contacts related to the group
     */
    func getContactGroupRelationListFromServerWithGroupId(groupId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        // create filter to get only the contact in the group
        let queryParams: [String: AnyObject] = ["filter": "contact_group_id=\(groupId)"]
        
        callApiWithPath(Routing.Service(tableName: "contact_group_relationship").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get all the contacts in the group using relational queries
     */
    func getContactsListFromServerWithRelationWithGroupId(groupId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        // only get contact_group_relationships for this group
        var queryParams: [String: AnyObject] = ["filter": "contact_group_id=\(groupId)"]
        
        // request without related would return just {id, groupId, contactId}
        // set the related field to go get the contact records referenced by
        // each contact_group_relationship record
        queryParams["related"] = "contact_by_contact_id"
        
        callApiWithPath(Routing.Service(tableName: "contact_group_relationship").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Remove contact from server
     */
    func removeContactWithContactId(contactId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        // need to delete everything with references to contact before we can delete the contact
        // delete contact relation -> delete contact info -> delete profile images -> delete contact
        // remove contact by record ID
        
        removeContactRelationWithContactId(contactId, success: { _ in
            self.removeContactInfoWithContactId(contactId, success: { _ in
                self.removeContactImageFolderWithContactId(contactId, success: { _ in
                    
                    let queryParams: [String: AnyObject] = ["ids": "\(contactId)"]
                    
                    self.callApiWithPath(Routing.Service(tableName: "contact").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: self.sessionHeaderParams, success: success, failure: failure)
                    
                    }, failure: failure)
                }, failure: failure)
            }, failure: failure)
    }
    
    private func removeContactRelationWithContactId(contactId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        // remove only contact-group relationships where contact is the contact to remove
        let queryParams: [String: AnyObject] = ["filter": "contact_id=\(contactId)"]
        
        callApiWithPath(Routing.Service(tableName: "contact_group_relationship").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    private func removeContactInfoWithContactId(contactId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        // remove only contact info for the contact we want to remove
        let queryParams: [String: AnyObject] = ["filter": "contact_id=\(contactId)"]
        
        callApiWithPath(Routing.Service(tableName: "contact_info").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    private func removeContactImageFolderWithContactId(contactId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        
        // delete all files and folders in the target folder
        let queryParams: [String: AnyObject] = ["force": "1"]
        
        callApiWithPath(Routing.ResourceFolder(folderPath: "\(contactId)").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get contact info from server
    */
    func getContactInfoFromServerWithContactId(contactId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        
        // create filter to get info only for this contact
        let queryParams: [String: AnyObject] = ["filter": "contact_id=\(contactId)"]
        
        callApiWithPath(Routing.Service(tableName: "contact_info").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get profile image for contact
    */
    func getProfileImageFromServerWithContactId(contactId: NSNumber, fileName: String, success: SuccessClosure, failure: ErrorClosure) {
        
        // request a download from the file
        let queryParams: [String: AnyObject] = ["include_properties": "1",
            "content": "1",
            "download": "1"]
        
        callApiWithPath(Routing.ResourceFile(folderPath: "/\(contactId)", fileName: fileName).path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get all the group the contact is in using relational queries
    */
    func getContactGroupsWithContactId(contactId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        
        // only get contact_group_relationships for this contact
        var queryParams: [String: AnyObject] = ["filter": "contact_id=\(contactId)"]
        
        // request without related would return just {id, groupId, contactId}
        // set the related field to go get the group records referenced by
        // each contact_group_relationship record
        queryParams["related"] = "contact_group_by_contact_group_id"
        
        callApiWithPath(Routing.Service(tableName: "contact_group_relationship").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    func addContactToServerWithDetails(contactDetails: JSON, success: SuccessClosure, failure: ErrorClosure) {
        // need to create contact first, then can add contactInfo and group relationships
        
        let requestBody = toResourceArray(contactDetails)
        
        callApiWithPath(Routing.Service(tableName: "contact").path, method: "POST", queryParams: nil, body: requestBody, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    func addContactGroupRelationToServerWithContactId(contactId: NSNumber, groupId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        
        // build request body
        // need to put in any extra field-key pair and avoid NSUrl timeout issue
        // otherwise it drops connection
        let requestBody = toResourceArray(["contact_group_id": groupId, "contact_id": contactId])
        
        callApiWithPath(Routing.Service(tableName: "contact_group_relationship").path, method: "POST", queryParams: nil, body: requestBody, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    func addContactInfoToServer(info: JSONArray, success: SuccessClosure, failure: ErrorClosure) {
        
        let requestBody = toResourceArray(info)
        
        callApiWithPath(Routing.Service(tableName: "contact_info").path, method: "POST", queryParams: nil, body: requestBody, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Create contact image on server
    */
    func addContactImageWithContactId(contactId: NSNumber, image: UIImage, imageName: String, success: SuccessClosure, failure: ErrorClosure) {
        
        // first we need to create folder, then image
        callApiWithPath(Routing.ResourceFolder(folderPath: "\(contactId)").path, method: "POST", queryParams: nil, body: nil, headerParams: sessionHeaderParams, success: { _ in
            
            self.putImageToFolderWithPath("\(contactId)", image: image, fileName: imageName, success: success, failure: failure)
            }, failure: failure)
    }
    
    func putImageToFolderWithPath(folderPath: String, image: UIImage, fileName: String, success: SuccessClosure, failure: ErrorClosure) {
        
        let imageData = UIImageJPEGRepresentation(image, 0.1)
        let file = NIKFile(name: fileName, mimeType: "application/octet-stream", data: imageData!)
        
        callApiWithPath(Routing.ResourceFile(folderPath: folderPath, fileName: fileName).path, method: "POST", queryParams: nil, body: file, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    
    /**
     Update an existing contact with the server
    */
    func updateContactWithContactId(contactId: NSNumber, contactDetails: JSON, success: SuccessClosure, failure: ErrorClosure) {
        
        // set the id of the contact we are looking at
        let queryParams: [String: AnyObject] = ["ids": "\(contactId)"]
        let requestBody = toResourceArray(contactDetails)
        
        callApiWithPath(Routing.Service(tableName: "contact").path, method: "PATCH", queryParams: queryParams, body: requestBody, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Update an existing contact info with the server
    */
    func updateContactInfo(info: JSONArray, success: SuccessClosure, failure: ErrorClosure) {
        
        let requestBody = toResourceArray(info)
        
        callApiWithPath(Routing.Service(tableName: "contact_info").path, method: "PATCH", queryParams: nil, body: requestBody, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    func getImageListFromServerWithContactId(contactId: NSNumber, success: SuccessClosure, failure: ErrorClosure) {
        
        // only want to get files, not any sub folders
        let queryParams: [String: AnyObject] = ["include_folders": "0",
            "include_files": "1"]
        
        callApiWithPath(Routing.ResourceFolder(folderPath: "\(contactId)").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
}
