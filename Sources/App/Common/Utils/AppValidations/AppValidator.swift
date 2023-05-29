//
//  AppValidator.swift
//  
//
//  Created by Ido on 28/11/2022.
//

import Foundation
#if VAPOR
import Vapor

public typealias AppValidator = Vapor.Validator

#else
public struct AppValidator<T: Decodable> {
    public let validate: (_ data: T) -> AppValidatorResult
    public init(validate: @escaping (_ data: T) -> AppValidatorResult) {
        self.validate = validate
    }
}
#endif

