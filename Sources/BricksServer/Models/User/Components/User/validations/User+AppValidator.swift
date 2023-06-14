//
//  User+AppValidator.swift
//  
//
//  Created by Ido on 17/07/2022.
//

import Fluent
#if VAPOR
import Vapor
#endif

//// All those are in lowercase
//static let FORBIDDEN_INPUT_STRINGS_IS        = ["dev"] // string component ("word") should not equal this
//static let FORBIDDEN_INPUT_STRINGS_CONTAINS  = ["admin", "master", "drop", "table", "select", " * ", " from ", "script"] // string component ("word") should not contain this
//static let FORBIDDEN_USER_NAME_CONTAINS     = ["username", "%20", "http", ".com", ".co.", ".org", ".us", ".uk", ".cn", ".ru", "hitler"] // string component ("word") should not contain this specifically for a name
//
//
/*
extension User : AppValidatable {
    
    // Length limits to validate fields:
    @AppSettable(name: "User.newUsernameLengthLimits", default: 6...64) static var newUsernameLengthLimits : CountableClosedRange<Int>
    @AppSettable(name: "User.existingUsernameLengthLimits", default: 6...64) static var existingUsernameLengthLimits : CountableClosedRange<Int>
    @AppSettable(name: "User.newPwdLengthLimits", default: 6...64) static var newPwdLengthLimits : CountableClosedRange<Int>
    @AppSettable(name: "User.existingPwdLengthLimits", default: 6...64) static var existingPwdLengthLimits : CountableClosedRange<Int>
    @AppSettable(name: "User.userDomain", default: 6...64) static var userDomainLengthLimits : CountableClosedRange<Int>
    
    static func validations(_ validations: inout AppValidations) {
        validations.add("username", as: String.self, is: !.empty && .count(Self.existingUsernameLengthLimits) && .characterSet(.usernameAllowedSet) )
        // No password property! validations.add("password", as: String.self, is: !.empty && .count(Self.existingUsernameLengthLimits) && !.characterSet(.whitespacesAndNewlines) )
        validations.add("passwordHash", as: String.self, is: !.empty && .count(Self.existingPwdLengthLimits))
        validations.add("createdAt", as: Date.self, is: .isInThePast)
        validations.add("updatedAt", as: Date.self, is: .isInThePast)
        validations.add("deletedAt", as: Date.self, is: .isInThePast)
        
        //
        validations.add("qualifiedUsername", as: String.self, is: !.empty && .count(Self.existingUsernameLengthLimits) && .characterSet(.usernameAllowedSet))
        validations.add("username", as: String.self, is: !.empty && .count(Self.existingUsernameLengthLimits) && .characterSet(.usernameAllowedSet))
        validations.add("userDomain", as: String.self, is: !.empty && .count(Self.userDomainLengthLimits) && .characterSet(.usernameAllowedSet))
        validations.add("usernameType", as: UsernameType.self, is: .init(validate: { data in
            AppValidationResult.by(
                test: {
                    data != .unknown
                },
                success: "UsernameType is valid",
                errorCode: .http_stt_badRequest,
                errorReason: "UsernameType is unknown")
        }))
    }
}

//// MARK: Identifiable / Vapor "Model" conformance
//@ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
//var id: UUID? // NOTE: this is the ID of the AccessToken, not the id of the user
//
//@Field(key: CodingKeys.expirationDate.fieldKey)
//var expirationDate : Date
//
//@Field(key: CodingKeys.lastUsedDate.fieldKey)
//private (set) var lastUsedDate : Date
//
//@Parent(key: "user_id")
//var user: User

extension User  {
    func propertiesValidation()->AppError? {
        //        var result : Abort? = nil
        //
        //        result = self.validateUsrname().appError?.asAbort(standInHttpStatus: .badRequest)
        //
        //        if let createdAt = self.createdAt, createdAt.isInTheFuture(safetyMargin: Date.SECONDS_IN_A_MINUTE) {
        //            result = Abort(.forbidden, reason: "funky dates")
        //            dlog?.warning("funky createdAt for user: [\(self.qualifiedUsername)] id: \(self.id?.uuidString ?? "<no uuid>") date: \(createdAt.description)")
        //        }
        //
        //        if let updatedAt = self.updatedAt, updatedAt.isInTheFuture(safetyMargin: Date.SECONDS_IN_A_MINUTE) {
        //            result = Abort(.forbidden, reason: "funky dates")
        //            dlog?.warning("funky updatedAt for user: [\(self.qualifiedUsername)] id: \(self.id?.uuidString ?? "<no uuid>") date: \(updatedAt.description)")
        //        }
        //
        //        return result
        return nil
    }
}
*/
