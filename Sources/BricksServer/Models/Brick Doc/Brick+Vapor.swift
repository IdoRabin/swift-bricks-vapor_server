//
//  Brick+Vapor.swift
//  
//
//  Created by Ido on 08/07/2022.
//

import Foundation

#if VAPOR
import Vapor
import Fluent
import FluentKit
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("Brick")

// Extensions requiring no implementations
extension Brick : Content {}
// extension Brick : @unchecked Sendable, Authenticatable {}
extension Brick : AsyncResponseEncodable {}

/// Keys for data stored in the Brick of Requests:
struct BrickStorageKey : ReqStorageKey {
    typealias Value = Brick
}

// MARK: Validatable Brick
extension Brick: Validatable {

    /// Validates all properties to be ok for saving into db.
    /// - Returns: success or the error saying why the User is not "valid"
    func propertiesValidation()->AppError? {
        let result : AppError? = nil
        // var
        
//        if Self.isValidInputString(name) == false {
//            result = Abort(.forbidden, reason: ".name too short or not allowed (required:\(Constants.MIN_NEW_USERNAME_LENGTH))")
//        }
//
//        if Self.isValidUsername(username) == false {
//            result = Abort(.forbidden, reason: ".username too short or not allowed (required:\(Constants.MIN_NEW_USERNAME_LENGTH))")
//        }
//
//        if let createdAt = self.createdAt, createdAt.isInTheFuture(safetyMargin: Date.SECONDS_IN_A_MINUTE) {
//            result = Abort(.forbidden, reason: "funky dates")
//            dlog?.warning("funky createdAt for user: [\(self.username)] id: \(self.id?.uuidString ?? "<no uuid>") date: \(createdAt.description)")
//        }
//
//        if let updatedAt = self.updatedAt, updatedAt.isInTheFuture(safetyMargin: Date.SECONDS_IN_A_MINUTE) {
//            result = Abort(.forbidden, reason: "funky dates")
//            dlog?.warning("funky updatedAt for user: [\(self.username)] id: \(self.id?.uuidString ?? "<no uuid>") date: \(updatedAt.description)")
//        }
        
        return result
    }
    
    static func validations(_ validations: inout Validations) {
        // Validations of requests BEFORE BEING DECODED
//        validations.add("name", as: String.self, is: !.empty && .count(3...) && .alphanumeric)
//        validations.add("name", as: String.self, is: .name) // see NameValidator
//        validations.add("username", as: String.self, is: !.empty && .count(3...) && .alphanumeric)
    }
}
#endif // #if VAPOR
