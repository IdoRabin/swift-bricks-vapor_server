//
//  VaporResponseEx.swift
//
//
//  Created by Ido on 24/01/2024.
//

import Foundation
import Vapor
import MNUtils
import MNVaporUtils
import Logging

fileprivate let dlog : Logger? = Logger(label:"AppResponseEx")

// Extension used by this app
// NOTE: This code is app-specific
public extension Vapor.Response {
    
    /// Returns header keys for the given request / session
    /// - Parameter with: request corresponding to the response
    /// - Returns: array of key,value, key, value strings to be places into the header keys of a response
    static func appEnrichedHeaderKeys(with:Request)->[String] {
        // TODO:
        return []
    }
}

public extension HTTPHeaders {
    
    /// Bulk replace multiple header names and their corresponding values:
    /// - Parameter dict: dictionary of [String:String] where key is the header name and value is the header value
    mutating func replaceOrAdd(namesValues dict:[String:String]) {
        dict.forEach { tuple in
            self.replaceOrAdd(name: tuple.0, value: tuple.1)
        }
    }
    
    /// Bulk replace multiple header names and their corresponding values:
    /// - Parameter tuples: tuples of header name and header value to add or replace in the headers
    mutating func replaceOrAdd(tuples:[(name: String, value: String)]) {
        tuples.forEach { tuple in
            self.replaceOrAdd(name: tuple.name, value: tuple.value)
        }
    }
}
