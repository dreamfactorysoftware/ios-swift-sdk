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
        if let errorMessage = (self.userInfo["error"] as? [String : Any])?["message"] as? String {
            return errorMessage
        }
        return "Unknown error occurred"
    }
}

/**
 Routing to different type of API resources
 */
enum Routing {
    case user(resourseName: String)
    case service(tableName: String)
    case resourceFolder(folderPath: String)
    case resourceFile(folderPath: String, fileName: String)
    
    var path: String {
        switch self {
            //rest path for request, form is <base instance url>/api/v2/user/resourceName
        case let .user(resourceName):
            return "\(kBaseInstanceUrl)/user/\(resourceName)"
            
            //rest path for request, form is <base instance url>/api/v2/<serviceName>/<tableName>
        case let .service(tableName):
            return "\(kBaseInstanceUrl)/\(kDbServiceName)/\(tableName)"
            
            // rest path for request, form is <base instance url>/api/v2/files/container/<folder path>/
        case let .resourceFolder(folderPath):
            return "\(kBaseInstanceUrl)/files/\(kContainerName)/\(folderPath)/"
            
            //rest path for request, form is <base instance url>/api/v2/files/container/<folder path>/filename
        case let .resourceFile(folderPath, fileName):
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
                _sessionToken = UserDefaults.standard.value(forKey: kSessionTokenKey) as? String
            }
            return _sessionToken
        }
        set {
            if let value = newValue {
                UserDefaults.standard.setValue(value, forKey: kSessionTokenKey)
                UserDefaults.standard.synchronize()
                _sessionToken = value
            } else {
                UserDefaults.standard.removeObject(forKey: kSessionTokenKey)
                UserDefaults.standard.synchronize()
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
    
    fileprivate let api = NIKApiInvoker.sharedInstance
    
    fileprivate init() {
    }
    func isConfigured() -> Bool {
        return kApiKey != ""
    }
    fileprivate func callApiWithPath(_ restApiPath: String, method: String, queryParams: [String: AnyObject]?, body: AnyObject?, headerParams: [String: String]?, success: SuccessClosure?, failure: ErrorClosure?) {
        api.restPath(restApiPath, method: method, queryParams: queryParams, body: body, headerParams: headerParams, contentType: "application/json", completionBlock: { (response, error) -> Void in
            if let error = error , failure != nil {
                failure!(error)
            } else if let success = success {
                success(response)
            }
        })
    }
    
    // MARK: Helpers for POST/PUT/PATCH entity wrapping
 
    fileprivate func toResourceArray(_ entity:JSON) -> JSON {
        let jsonResource: JSON = ["resource" : [entity] as AnyObject] // DreamFactory REST API body with {"resource" = [ { record } ] }
        return jsonResource
    }
    fileprivate func toResourceArray(_ jsonArray:JSONArray) -> JSON {
        let jsonResource: JSON = ["resource" : jsonArray as AnyObject] // DreamFactory REST API body with {"resource" = [ { record } ] }
        return jsonResource
    }
    
    //MARK: - Authorization methods

    /**
    Sign in user
    */
    func loginWithEmail(_ email: String, password: String, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        let requestBody: [String: AnyObject] = ["email": email as AnyObject,
            "password": password as AnyObject]
        
        callApiWithPath(Routing.user(resourseName: "session").path, method: "POST", queryParams: nil, body: requestBody as AnyObject?, headerParams: headerParams, success: success, failure: failure)
    }
    
    /**
     Register new user
     */
    func registerWithEmail(_ email: String, password: String, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        //login after signup
        let queryParams: [String: AnyObject] = ["login": "1" as AnyObject]
        let requestBody: [String: AnyObject] = ["email": email as AnyObject,
            "password": password as AnyObject,
            "first_name": "Address" as AnyObject,
            "last_name": "Book" as AnyObject,
            "name": "Address Book User" as AnyObject]
        
        callApiWithPath(Routing.user(resourseName: "register").path, method: "POST", queryParams: queryParams, body: requestBody as AnyObject?, headerParams: headerParams, success: success, failure: failure)
    }
    
    //MARK: - Group methods
    
    /**
    Get all the groups from the database
    */
    func getAddressBookContentFromServerWithSuccess(_ success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        callApiWithPath(Routing.service(tableName: "contact_group").path, method: "GET", queryParams: nil, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    fileprivate func removeContactGroupRelationsForGroupId(_ groupId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        // remove all contact-group relations for the group being deleted
        
        // create filter to select all contact_group_relationship records that
        // reference the group being deleted
        let queryParams: [String: AnyObject] = ["filter": "contact_group_id=\(groupId)" as AnyObject]
        
        callApiWithPath(Routing.service(tableName: "contact_group_relationship").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Remove group from server
     */
    func removeGroupFromServerWithGroupId(_ groupId: NSNumber, success: SuccessClosure? = nil, failure: @escaping ErrorClosure) {
        // can not delete group until all references to it are removed
        // remove relations -> remove group
        // pass record ID so it knows what group we are removing
        
        removeContactGroupRelationsForGroupId(groupId, success: { _ in
            // delete the record by the record ID
            // form is "ids":"1,2,3"
            let queryParams: [String: AnyObject] = ["ids": "\(groupId)" as AnyObject]
            
            self.callApiWithPath(Routing.service(tableName: "contact_group").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: self.sessionHeaderParams, success: success, failure: failure)
            
            }, failure: failure)
    }
    
    /**
     Add new group with name and contacts
     */
    func addGroupToServerWithName(_ name: String, contactIds: [NSNumber]?, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        let requestBody = toResourceArray(["name": name as AnyObject])
        
        callApiWithPath(Routing.service(tableName: "contact_group").path, method: "POST", queryParams: nil, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: { response in
            // get the id of the new group, then add the relations
            let records = response!["resource"] as! JSONArray
            for recordInfo in records {
                self.addGroupContactRelationsForGroupWithId(recordInfo["id"] as! NSNumber, contactIds: contactIds, success: success, failure: failure)
            }
            }, failure: failure)
    }
    
    fileprivate func addGroupContactRelationsForGroupWithId(_ groupId: NSNumber, contactIds: [NSNumber]?, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
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
        
        let requestBody: [String: AnyObject] = ["resource": records as AnyObject]
        
        callApiWithPath(Routing.service(tableName: "contact_group_relationship").path, method: "POST", queryParams: nil, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Update group with new name and contacts
     */
    func updateGroupWithId(_ groupId: NSNumber, name: String, oldName: String, removedContactIds: [NSNumber]?, addedContactIds: [NSNumber]?, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        //if name didn't change skip server update
        if name == oldName {
            removeGroupContactRelationsForGroupWithId(groupId, contactIds: removedContactIds, success: { _ in
                self.addGroupContactRelationsForGroupWithId(groupId, contactIds: addedContactIds, success: success, failure: failure)
                }, failure: failure)
            return
        }
        
        // update name
        let queryParams: [String: AnyObject] = ["ids": groupId.stringValue as AnyObject]
        let requestBody = toResourceArray(["name": name as AnyObject])
        
        callApiWithPath(Routing.service(tableName: "contact_group").path, method: "PATCH", queryParams: queryParams, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: { _ in
            self.removeGroupContactRelationsForGroupWithId(groupId, contactIds: removedContactIds, success: { _ in
                self.addGroupContactRelationsForGroupWithId(groupId, contactIds: addedContactIds, success: success, failure: failure)
                }, failure: failure)
            }, failure: failure)
    }
    
    fileprivate func removeGroupContactRelationsForGroupWithId(_ groupId: NSNumber, contactIds: [NSNumber]?, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // if there are no contacts to remove skip server update
        if contactIds == nil || contactIds!.count == 0 {
            success(nil)
            return
        }
        
        // remove contact-group relations
        
        // do not know the ID of the record to remove
        // one value for groupId, but many values for contactId
        // instead of making a long SQL query, change what we use as identifiers
        let queryParams: [String: AnyObject] = ["id_field": "contact_group_id,contact_id" as AnyObject]
        
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
        
        let requestBody: [String: AnyObject] = ["resource": records as AnyObject]
        
        callApiWithPath(Routing.service(tableName: "contact_group_relationship").path, method: "DELETE", queryParams: queryParams, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    //MARK: - Contact methods
    
    /**
    Get all the contacts from the database
    */
    func getContactListFromServerWithSuccess(_ success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        // only need to get the contactId and full contact name
        // set the fields param to give us just the fields we need
        let queryParams: [String: AnyObject] = ["fields": "id,first_name,last_name" as AnyObject]
        
        callApiWithPath(Routing.service(tableName: "contact").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get the list of contacts related to the group
     */
    func getContactGroupRelationListFromServerWithGroupId(_ groupId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        // create filter to get only the contact in the group
        let queryParams: [String: AnyObject] = ["filter": "contact_group_id=\(groupId)" as AnyObject]
        
        callApiWithPath(Routing.service(tableName: "contact_group_relationship").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get all the contacts in the group using relational queries
     */
    func getContactsListFromServerWithRelationWithGroupId(_ groupId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        // only get contact_group_relationships for this group
        var queryParams: [String: AnyObject] = ["filter": "contact_group_id=\(groupId)" as AnyObject]
        
        // request without related would return just {id, groupId, contactId}
        // set the related field to go get the contact records referenced by
        // each contact_group_relationship record
        queryParams["related"] = "contact_by_contact_id" as AnyObject?
        
        callApiWithPath(Routing.service(tableName: "contact_group_relationship").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Remove contact from server
     */
    func removeContactWithContactId(_ contactId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        // need to delete everything with references to contact before we can delete the contact
        // delete contact relation -> delete contact info -> delete profile images -> delete contact
        // remove contact by record ID
        
        removeContactRelationWithContactId(contactId, success: { _ in
            self.removeContactInfoWithContactId(contactId, success: { _ in
                self.removeContactImageFolderWithContactId(contactId, success: { _ in
                    
                    let queryParams: [String: AnyObject] = ["ids": "\(contactId)" as AnyObject]
                    
                    self.callApiWithPath(Routing.service(tableName: "contact").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: self.sessionHeaderParams, success: success, failure: failure)
                    
                    }, failure: failure)
                }, failure: failure)
            }, failure: failure)
    }
    
    fileprivate func removeContactRelationWithContactId(_ contactId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        // remove only contact-group relationships where contact is the contact to remove
        let queryParams: [String: AnyObject] = ["filter": "contact_id=\(contactId)" as AnyObject]
        
        callApiWithPath(Routing.service(tableName: "contact_group_relationship").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    fileprivate func removeContactInfoWithContactId(_ contactId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        // remove only contact info for the contact we want to remove
        let queryParams: [String: AnyObject] = ["filter": "contact_id=\(contactId)" as AnyObject]
        
        callApiWithPath(Routing.service(tableName: "contact_info").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    fileprivate func removeContactImageFolderWithContactId(_ contactId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // delete all files and folders in the target folder
        let queryParams: [String: AnyObject] = ["force": "1" as AnyObject]
        
        callApiWithPath(Routing.resourceFolder(folderPath: "\(contactId)").path, method: "DELETE", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get contact info from server
    */
    func getContactInfoFromServerWithContactId(_ contactId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // create filter to get info only for this contact
        let queryParams: [String: AnyObject] = ["filter": "contact_id=\(contactId)" as AnyObject]
        
        callApiWithPath(Routing.service(tableName: "contact_info").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get profile image for contact
    */
    func getProfileImageFromServerWithContactId(_ contactId: NSNumber, fileName: String, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // request a download from the file
        let queryParams: [String: AnyObject] = ["include_properties": "1" as AnyObject,
            "content": "1" as AnyObject,
            "download": "1" as AnyObject]
        
        callApiWithPath(Routing.resourceFile(folderPath: "/\(contactId)", fileName: fileName).path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Get all the group the contact is in using relational queries
    */
    func getContactGroupsWithContactId(_ contactId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // only get contact_group_relationships for this contact
        var queryParams: [String: AnyObject] = ["filter": "contact_id=\(contactId)" as AnyObject]
        
        // request without related would return just {id, groupId, contactId}
        // set the related field to go get the group records referenced by
        // each contact_group_relationship record
        queryParams["related"] = "contact_group_by_contact_group_id" as AnyObject?
        
        callApiWithPath(Routing.service(tableName: "contact_group_relationship").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    func addContactToServerWithDetails(_ contactDetails: JSON, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        // need to create contact first, then can add contactInfo and group relationships
        
        let requestBody = toResourceArray(contactDetails)
        
        callApiWithPath(Routing.service(tableName: "contact").path, method: "POST", queryParams: nil, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    func addContactGroupRelationToServerWithContactId(_ contactId: NSNumber, groupId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // build request body
        // need to put in any extra field-key pair and avoid NSUrl timeout issue
        // otherwise it drops connection
        let requestBody = toResourceArray(["contact_group_id": groupId, "contact_id": contactId])
        
        callApiWithPath(Routing.service(tableName: "contact_group_relationship").path, method: "POST", queryParams: nil, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    func addContactInfoToServer(_ info: JSONArray, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        let requestBody = toResourceArray(info)
        
        callApiWithPath(Routing.service(tableName: "contact_info").path, method: "POST", queryParams: nil, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Create contact image on server
    */
    func addContactImageWithContactId(_ contactId: NSNumber, image: UIImage, imageName: String, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // first we need to create folder, then image
        callApiWithPath(Routing.resourceFolder(folderPath: "\(contactId)").path, method: "POST", queryParams: nil, body: nil, headerParams: sessionHeaderParams, success: { _ in
            
            self.putImageToFolderWithPath("\(contactId)", image: image, fileName: imageName, success: success, failure: failure)
            }, failure: failure)
    }
    
    func putImageToFolderWithPath(_ folderPath: String, image: UIImage, fileName: String, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        let imageData = UIImageJPEGRepresentation(image, 0.1)
        let file = NIKFile(name: fileName, mimeType: "application/octet-stream", data: imageData!)
        
        callApiWithPath(Routing.resourceFile(folderPath: folderPath, fileName: fileName).path, method: "POST", queryParams: nil, body: file, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    
    /**
     Update an existing contact with the server
    */
    func updateContactWithContactId(_ contactId: NSNumber, contactDetails: JSON, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // set the id of the contact we are looking at
        let queryParams: [String: AnyObject] = ["ids": "\(contactId)" as AnyObject]
        let requestBody = toResourceArray(contactDetails)
        
        callApiWithPath(Routing.service(tableName: "contact").path, method: "PATCH", queryParams: queryParams, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    /**
     Update an existing contact info with the server
    */
    func updateContactInfo(_ info: JSONArray, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        let requestBody = toResourceArray(info)
        
        callApiWithPath(Routing.service(tableName: "contact_info").path, method: "PATCH", queryParams: nil, body: requestBody as AnyObject?, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
    
    func getImageListFromServerWithContactId(_ contactId: NSNumber, success: @escaping SuccessClosure, failure: @escaping ErrorClosure) {
        
        // only want to get files, not any sub folders
        let queryParams: [String: AnyObject] = ["include_folders": "0" as AnyObject,
            "include_files": "1" as AnyObject]
        
        callApiWithPath(Routing.resourceFolder(folderPath: "\(contactId)").path, method: "GET", queryParams: queryParams, body: nil, headerParams: sessionHeaderParams, success: success, failure: failure)
    }
}
