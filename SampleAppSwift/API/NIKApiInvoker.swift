//
//  NIKApiInvoker.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

final class NIKApiInvoker {

    let queue = OperationQueue()
    let cachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy
    
    /**
     get the shared singleton
    */
    static let sharedInstance = NIKApiInvoker()
    static var __LoadingObjectsCount = 0
    fileprivate init() {
    }
    
    fileprivate func updateLoadCountWithDelta(_ countDelta: Int) {
        objc_sync_enter(self)
        NIKApiInvoker.__LoadingObjectsCount += countDelta
        NIKApiInvoker.__LoadingObjectsCount = max(0, NIKApiInvoker.__LoadingObjectsCount)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = NIKApiInvoker.__LoadingObjectsCount > 0
        
        objc_sync_exit(self)
    }
    
    fileprivate func startLoad() {
        updateLoadCountWithDelta(1)
    }
    
    fileprivate func stopLoad() {
        updateLoadCountWithDelta(-1)
    }
    
    /**
     primary way to access and use the API
     builds and sends an async NSUrl request
     
     - Parameter path: url to service, general form is <base instance url>/api/v2/<service>/<path>
     - Parameter method: http verb
     - Parameter queryParams: varies by call, can be put into path instead of here
     - Parameter body: request body, varies by call
     - Parameter headerParams: user should pass in the app api key and a session token
     - Parameter contentType: json or xml
     - Parameter completionBlock: block to be executed once call is done
    */
    func restPath(_ path: String, method: String, queryParams: [String: AnyObject]?, body: AnyObject?, headerParams: [String: String]?, contentType: String?, completionBlock: @escaping ([String: AnyObject]?, NSError?) -> Void) {
        let request = NIKRequestBuilder.restPath(path, method: method, queryParams: queryParams, body: body, headerParams: headerParams, contentType: contentType)
        
        /*******************************************************************
        *
        *  NOTE: apple added App Transport Security in iOS 9.0+ to improve
        *          security. As of this writing (7/15) all plain text http
        *          connections fail by default. For more info about App
        *          Transport Security and how to handle this issue here:
        *          https://developer.apple.com/library/prerelease/ios/technotes/App-Transport-Security-Technote/index.html
        *
        *******************************************************************/
        
        // Handle caching on GET requests

        if (cachePolicy == .returnCacheDataElseLoad || cachePolicy == .returnCacheDataDontLoad) && method == "GET" {
            let cacheResponse = URLCache.shared.cachedResponse(for: request)
            let data = cacheResponse?.data
            if let data = data {
                let results = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                completionBlock(results!, nil)
            }
        }
        
        if cachePolicy == .returnCacheDataDontLoad {
            return
        }
        startLoad() // for network activity indicator
        
        let date = Date()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) {(response, response_data, response_error) -> Void in
            self.stopLoad()
            if let response_error = response_error {
                if let response_data = response_data {
                    let results = try? JSONSerialization.jsonObject(with: response_data, options: [])
                    if let results = results as? [String: AnyObject] {
                        completionBlock(nil, NSError(domain: response_error._domain, code: response_error._code, userInfo: results))
                    } else {
                        completionBlock(nil, response_error as NSError?)
                    }
                } else {
                    completionBlock(nil, response_error as NSError?)
                }
                return
            } else {
                let statusCode = (response as! HTTPURLResponse).statusCode
                if !NSLocationInRange(statusCode, NSMakeRange(200, 99)) {
                    let response_error = NSError(domain: "swagger", code: statusCode, userInfo: try! JSONSerialization.jsonObject(with: response_data!, options: []) as? [AnyHashable: Any])
                    completionBlock(nil, response_error)
                    return
                } else {
                    let results = try! JSONSerialization.jsonObject(with: response_data!, options: []) as! [String: AnyObject]
                    if UserDefaults.standard.bool(forKey: "RVBLogging") {
                        NSLog("fetched results (\(Date().timeIntervalSince(date)) seconds): \(results)")
                    }
                    completionBlock(results, nil)
                }
            }
        }
    }
}

final class NIKRequestBuilder {
    
    /**
     Builds NSURLRequests with the format for the DreamFactory Rest API
     
     This will play nice if you want to roll your own set up or use a
     third party library like AFNetworking to send the REST requests
     
     - Parameter path: url to service, general form is <base instance url>/api/v2/<service>/<path>
     - Parameter method: http verb
     - Parameter queryParams: varies by call, can be put into path instead of here
     - Parameter body: request body, varies by call
     - Parameter headerParams: user should pass in the app api key and a session token
     - Parameter contentType: json or xml
     */
    static func restPath(_ path: String, method: String, queryParams: [String: AnyObject]?, body: AnyObject?, headerParams: [String: String]?, contentType: String?) -> URLRequest {
        let request = NSMutableURLRequest()
        var requestUrl = path
        if let queryParams = queryParams {
            // build the query params into the URL
            // ie @"filter" = "id=5" becomes "<url>?filter=id=5
            let parameterString = queryParams.stringFromHttpParameters()
            requestUrl = "\(path)?\(parameterString)"
        }
        
        if UserDefaults.standard.bool(forKey: "RVBLogging") {
            NSLog("request url: \(requestUrl)")
        }
        
        let URL = Foundation.URL(string: requestUrl)!
        request.url = URL
        // The cache settings get set by the ApiInvoker
        request.timeoutInterval = 30
        
        if let headerParams = headerParams {
            for (key, value) in headerParams {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        request.httpMethod = method
        if let body = body {
            // build the body into JSON
            var data: Data!
            if body is [String: AnyObject] || body is [AnyObject] {
                data = try? JSONSerialization.data(withJSONObject: body, options: [])
            } else if let body = body as? NIKFile {
                data = body.data as Data!
            } else {
                //data = body.data(using: String.Encoding.utf8) What is this object type?
                data = "".data(using: String.Encoding.utf8)
            }
            let postLength = "\(data.count)"
            request.setValue(postLength, forHTTPHeaderField: "Content-Length")
            request.httpBody = data
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        return request as URLRequest
    }
}

extension String {
    
    /** Percent escape value to be added to a URL query value as specified in RFC 3986
    - Returns: Percent escaped string.
    */
    
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-._~")
        
        return self.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)
    }
}

extension Dictionary {
    
    /** Build string representation of HTTP parameter dictionary of keys and objects
        This percent escapes in compliance with RFC 3986
    - Returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    */
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
}
