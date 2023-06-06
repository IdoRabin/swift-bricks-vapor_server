//
//  AppValidations.swift
//  
//
//  Created by Ido on 28/11/2022.
//

import Foundation
import DSLogger
import MNUtils

#if VAPOR
import Vapor
typealias AppValidations = Vapor.Validations
#else

#endif

fileprivate let dlog : DSLogger? = DLog.forClass("AppValidations")

struct AppValidationsError: Error {
    let failures: [AppValidationResult]
}

struct AppValidationsResult {
    let results: [AppValidationResult]
    
    var error: AppValidationsError? {
        let failures = self.results.filter { appResult in
            return appResult.isFailed
        }
        
        if !failures.isEmpty {
            return AppValidationsError(failures: failures)
        } else {
            return nil
        }
    }
    
    func assert() throws {
        if let error = self.error {
            throw error
        }
    }
    
    private init() {
        results = []
    }
    static func empty()->AppValidationsResult {
        return AppValidationsResult()
    }
}

// AppValidations
/*
struct AppValidations {
    var storage: [AppValidation]
    
    public init() {
        self.storage = []
    }
    
    public func validate(request: Request) throws -> AppValidationsResult {
        dlog?.todo("IMPLEMENT validate(request:) !")
        return AppValidationsResult.empty()
    }
    
    public func validate(query: URI) throws -> AppValidationsResult {
        dlog?.todo("IMPLEMENT validate(query:URI) !")
        return AppValidationsResult.empty()
    }
    
    public func validate(json: String) throws -> AppValidationsResult {
        dlog?.todo("IMPLEMENT validate(json:String) !")
        return AppValidationsResult.empty()
    }
    
    public func validate(_ decoder: Decoder) throws -> AppValidationsResult {
        dlog?.todo("IMPLEMENT validate(decoder:Decoder) !")
        return AppValidationsResult.empty()
    }
    
    internal func validate(_ decoder: KeyedDecodingContainer<ValidationKey>) -> AppValidationsResult {
        dlog?.todo("IMPLEMENT validate(decoder:KeyedDecodingContainer) !")
        return AppValidationsResult.empty()
    }

    mutating func add<T>(
        _ key: ValidationKey,
        as type: T.Type = T.self,
        is validator: Validator<T> = .valid,
        required: Bool = true,
        customFailureDescription: String? = nil
    ) {
        let validation = Validation(key: key, required: required, validator: validator, customFailureDescription: customFailureDescription)
        self.storage.append(validation)
    }
    
    public mutating func add(
        _ key: ValidationKey,
        result: ValidatorResult,
        customFailureDescription: String? = nil
    ) {
        let validation = AppValidation(key: key, result: result, customFailureDescription: customFailureDescription)
        self.storage.append(validation)
    }

    public mutating func add(
        _ key: ValidationKey,
        required: Bool = true,
        customFailureDescription: String? = nil,
        _ nested: (inout Validations) -> ()
    ) {
        var validations = Validations()
        nested(&validations)
        let validation = AppValidation(nested: key, required: required, keyed: validations, customFailureDescription: customFailureDescription)
        self.storage.append(validation)
    }
    
    public mutating func add(
        each key: ValidationKey,
        required: Bool = true,
        customFailureDescription: String? = nil,
        _ handler: @escaping (Int, inout Validations) -> ()
    ) {
        let validation = AppValidation(nested: key, required: required, unkeyed: handler, customFailureDescription: customFailureDescription)
        self.storage.append(validation)
    }
     
}*/
