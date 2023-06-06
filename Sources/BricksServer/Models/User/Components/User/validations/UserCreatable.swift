//
//  NewUserComps.swift
//  
//
//  Created by Ido on 29/11/2022.
//

import Foundation
import MNUtils

#if VAPOR
import Vapor
#endif

// New user components:
protocol UserCreatable : AppValidatable, JSONSerializable {
    var username:String? { get }
    var userDomain:String?  { get }
    var password:String  { get }
    var usernameType: UsernameType  { get }
    var isShouldsanitize:Bool  { get }
}

// Validation:
extension UserCreatable {
    
    static func validations(_ validations: inout AppValidations) {
        
        validations.add("username", as: String.self, is: .count(User.newUsernameLengthLimits) && .characterSet(.usernameAllowedSet))
        validations.add("userDomain", as: String.self, is: .count(User.userDomainLengthLimits) && .characterSet(.userDomainAllowedSet))
        validations.add("newUserPwd", as: String.self, is: .count(User.newPwdLengthLimits))
        validations.add("newUsernameType", as: UsernameType.self, is: .init(validate: { data in
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
