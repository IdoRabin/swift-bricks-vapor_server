//
//  File.swift
//  
//
//  Created by Ido on 28/11/2022.
//

import Foundation

#if VAPOR
import Vapor
#endif

protocol AppValidatable {
    static func validations(_ validations: inout AppValidations)
}

extension AppValidatable {
    public static func validate(content request: Request) throws {
        try self.validations().validate(request: request).assert()
    }
    
    public static func validate(query request: Request) throws {
        try self.validations().validate(query: request.url).assert()
    }
    
    public static func validate(json: String) throws {
        try self.validations().validate(json: json).assert()
    }
    
    public static func validate(query: URI) throws {
        try self.validations().validate(query: query).assert()
    }
    
    public static func validate(_ decoder: Decoder) throws {
        try self.validations().validate(decoder).assert()
    }
    
    public static func validations() -> AppValidations {
        var validations = AppValidations()
        self.validations(&validations)
        return validations
    }
}


