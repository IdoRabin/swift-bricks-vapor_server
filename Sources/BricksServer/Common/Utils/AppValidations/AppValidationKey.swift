//
//  File.swift
//  
//
//  Created by Ido on 28/11/2022.
//

import Foundation

#if VAPOR
import Vapor

typealias AppValidationKey = Vapor.ValidationKey


#else

public enum AppValidationKey {
    case integer(Int)
    case string(String)
}

extension AppValidationKey: CodingKey {
    public var stringValue: String {
        switch self {
        case .integer(let integer):
            return integer.description
        case .string(let string):
            return string
        }
    }
    
    public var intValue: Int? {
        switch self {
        case .integer(let integer):
            return integer
        case .string:
            return nil
        }
    }
    
    public init?(stringValue: String) {
        self = .string(stringValue)
    }
    
    public init?(intValue: Int) {
        self = .integer(intValue)
    }
}

extension AppValidationKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AppValidationKey: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value)
    }
}

extension AppValidationKey: CustomStringConvertible {
    public var description: String {
        self.stringValue
    }
}

#endif
