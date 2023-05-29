//
//  AppErrorable.swift
//  
//
//  Created by Ido on 16/03/2023.
//

import Foundation

/// Allows converting between NSError, error and AppError
protocol AppErrorable : Error, CustomDebugStringConvertible, CustomStringConvertible {
    
    var desc : String { get }
    var domain : String { get }
    var code : AppErrorInt { get }
    
    var domainCodeDesc : String { get }
    
    var reason : String { get }
}

extension AppErrorable /* default implementation */ {
    
    var domainCodeDesc : String {
        return "\(self.domain).\(self.code)"
    }
    
    /// CustomStringConvertible
    /// We have the same description and debugDescription to avoid confusion
    public var description: String { // CustomStringConvertible
        var res : String = ""
        if (res.count == 0) {
            // Convert to string failed:
            // Minimal response:
            res = self.domainCodeDesc + " | " + (self.reason);
        }
        return res.replacingOccurrences(ofFromTo: ["\"" : "'"], caseSensitive: true)
    }
    
    /// CustomDebugStringConvertible
    /// We have the same description and debugDescription to avoid confusion
    public var debugDescription: String {
        return self.description
    }
}
