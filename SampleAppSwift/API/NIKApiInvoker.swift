//
//  NIKApiInvoker.swift
//  SampleAppSwift
//
//  Created by Timur Umayev on 1/4/16.
//  Copyright © 2016 dreamfactory. All rights reserved.
//

import UIKit

final class NIKApiInvoker {

    let queue = NSOperationQueue()
    let cachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy
    
    /**
     get the shared singleton
    */
    static let sharedInstance = NIKApiInvoker()
    static var __LoadingObjectsCount = 0
    private init() {
    }
    
    private func updateLoadCountWithDelta(countDelta: Int) {
        objc_sync_enter(self)
        NIKApiInvoker.__LoadingObjectsCount += countDelta
        NIKApiInvoker.__LoadingObjectsCount = NIKApiInvoker.__LoadingObjectsCount < 0 ? 0 : NIKApiInvoker.__LoadingObjectsCount
        
#if (arch(i386) || arch(x86_64)) && os(iOS)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = NIKApiInvoker.__LoadingObjectsCount > 0
#endif
        objc_sync_exit(self)
    }
    
    private func startLoad() {
        updateLoadCountWithDelta(1)
    }
    
    private func stopLoad() {
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
    func restPath(path: String, method: String, queryParams: [String: AnyObject]?, body: AnyObject?, headerParams: [String: String]?, contentType: String?, completionBlock: ([String: AnyObject]?, NSError?) -> Void) {
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

        if (cachePolicy == .ReturnCacheDataElseLoad || cachePolicy == .ReturnCacheDataDontLoad) && method == "GET" {
            let cacheResponse = NSURLCache.sharedURLCache().cachedResponseForRequest(request)
            let data = cacheResponse?.data
            if let data = data {
                let results = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
                completionBlock(results!, nil)
            }
        }
        
        if cachePolicy == .ReturnCacheDataDontLoad {
            return
        }
        startLoad() // for network activity indicator
        
        let date = NSDate()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) {(response, response_data, var response_error) -> Void in
            self.stopLoad()
            let statusCode = (response as! NSHTTPURLResponse).statusCode
            if response_error != nil {
                completionBlock(nil, response_error)
                return
            } else if !NSLocationInRange(statusCode, NSMakeRange(200, 99)) {
                response_error = NSError(domain: "swagger", code: statusCode, userInfo: try! NSJSONSerialization.JSONObjectWithData(response_data!, options: []) as? [NSObject: AnyObject])
                completionBlock(nil, response_error)
                return
            } else {
                let results = try! NSJSONSerialization.JSONObjectWithData(response_data!, options: []) as! [String: AnyObject]
                if NSUserDefaults.standardUserDefaults().boolForKey("RVBLogging") {
                    NSLog("fetched results (\(NSDate().timeIntervalSinceDate(date)) seconds): \(results)")
                }
                completionBlock(results, nil)
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
    static func restPath(path: String, method: String, queryParams: [String: AnyObject]?, body: AnyObject?, headerParams: [String: String]?, contentType: String?) -> NSURLRequest {
        let request = NSMutableURLRequest()
        var requestUrl = path
        if let queryParams = queryParams {
            // build the query params into the URL
            // ie @"filter" = "id=5" becomes "<url>?filter=id=5
            let parameterString = queryParams.stringFromHttpParameters()
            requestUrl = "\(path)?\(parameterString)"
        }
        
        if NSUserDefaults.standardUserDefaults().boolForKey("RVBLogging") {
            NSLog("request url: \(requestUrl)")
        }
        
        let URL = NSURL(string: requestUrl)!
        request.URL = URL
        // The cache settings get set by the ApiInvoker
        request.timeoutInterval = 30
        
        if let headerParams = headerParams {
            for (key, value) in headerParams {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        request.HTTPMethod = method
        if let body = body {
            // build the body into JSON
            var data: NSData!
            if body is [String: AnyObject] || body is [AnyObject] {
                data = try? NSJSONSerialization.dataWithJSONObject(body, options: [])
            } else if let body = body as? NIKFile {
                data = body.data
            } else {
                data = body.dataUsingEncoding(NSUTF8StringEncoding)
            }
            let postLength = "\(data.length)"
            request.setValue(postLength, forKey: "Content-Length")
            request.HTTPBody = data
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
}

extension String {
    
    /** Percent escape value to be added to a URL query value as specified in RFC 3986
    - Returns: Percent escaped string.
    */
    
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        characterSet.addCharactersInString("-._~")
        
        return self.stringByAddingPercentEncodingWithAllowedCharacters(characterSet)
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
        
        return parameterArray.joinWithSeparator("&")
    }
}