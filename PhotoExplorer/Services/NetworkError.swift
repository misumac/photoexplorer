//
//  NetworkError.swift
//  PhotoExplorer
//
//  Created by Mihai on 3/16/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation

public enum NetworkError: Error, CustomStringConvertible {
    /// Unknown or not supported error.
    case unknown
    
    /// Not connected to the internet.
    case notConnectedToInternet
    
    /// International data roaming turned off.
    case internationalRoamingOff
    
    /// Cannot reach the server.
    case notReachedServer
    
    /// Connection is lost.
    case connectionLost
    
    /// Incorrect data returned from the server.
    case incorrectDataReturned
    
    init(error: NSError) {
        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorUnknown:
                self = .unknown
            case NSURLErrorCancelled:
                self = .unknown // Cancellation is not used in this project.
            case NSURLErrorBadURL:
                self = .incorrectDataReturned // Because it is caused by a bad URL returned in a JSON response from the server.
            case NSURLErrorTimedOut:
                self = .notReachedServer
            case NSURLErrorUnsupportedURL:
                self = .incorrectDataReturned
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                self = .notReachedServer
            case NSURLErrorDataLengthExceedsMaximum:
                self = .incorrectDataReturned
            case NSURLErrorNetworkConnectionLost:
                self = .connectionLost
            case NSURLErrorDNSLookupFailed:
                self = .notReachedServer
            case NSURLErrorHTTPTooManyRedirects:
                self = .unknown
            case NSURLErrorResourceUnavailable:
                self = .incorrectDataReturned
            case NSURLErrorNotConnectedToInternet:
                self = .notConnectedToInternet
            case NSURLErrorRedirectToNonExistentLocation, NSURLErrorBadServerResponse:
                self = .incorrectDataReturned
            case NSURLErrorUserCancelledAuthentication, NSURLErrorUserAuthenticationRequired:
                self = .unknown
            case NSURLErrorZeroByteResource, NSURLErrorCannotDecodeRawData, NSURLErrorCannotDecodeContentData:
                self = .incorrectDataReturned
            case NSURLErrorCannotParseResponse:
                self = .incorrectDataReturned
            case NSURLErrorInternationalRoamingOff:
                self = .internationalRoamingOff
            case NSURLErrorCallIsActive, NSURLErrorDataNotAllowed, NSURLErrorRequestBodyStreamExhausted:
                self = .unknown
            case NSURLErrorFileDoesNotExist, NSURLErrorFileIsDirectory:
                self = .incorrectDataReturned
            default:
                self = .unknown
            }
        } else {
            self = .unknown
        }
    }
    
    public var description: String {
        let text: String
        switch self {
        case .unknown:
            text = "NetworkError Unknown"
        case .notConnectedToInternet:
            text = "NetworkError NotConnectedToInternet"
        case .internationalRoamingOff:
            text = "NetworkError InternationalRoamingOff"
        case .notReachedServer:
            text = "NetworkError NotReachedServer"
        case .connectionLost:
            text = "NetworkError ConnectionLost"
        case .incorrectDataReturned:
            text = "NetworkError IncorrectDataReturned"
        }
        return text
    }
}
