//
//  File.swift
//  
//
//  Created by Ido on 01/12/2022.
//

import Foundation
import MNUtils

#if VAPOR
import Vapor
#endif

struct UserLoginErrorLabel: OptionSet, CustomStringConvertible {
    let rawValue: Int
    
    static let username = UserLoginErrorLabel(rawValue: 1 << 0)
    static let password = UserLoginErrorLabel(rawValue: 1 << 1)
    static let general = UserLoginErrorLabel(rawValue: 1 << 2)
    
    static let all: UserLoginErrorLabel = [.username, .password, .general]
    var descriptions: [String] {
        let elems : [UserLoginErrorLabel] = Array(self.elements)
        var result : [String] = []
        if elems.count == 1 {
            if elems.first == .password { result = ["password"] }
            if elems.first == .username { result = ["username"] }
            if elems.first == .general  { result = ["general"] }
        } else {
            
            for element in elems {
                result.append(contentsOf: element.descriptions)
            }
        }
        
        return result
    }
    
    var description: String {
        return self.descriptions.descriptionsJoined
    }
}

protocol UserLoginable : AppValidatable, JSONSerializable {
    var username:String { get }
    var userDomain:String  { get }
    var userPassword:String  { get }
    var usernameType: UsernameType  { get }
}

extension UserLoginable {
    
    static func validations(_ validations: inout AppValidations) {
        validations.add("username", as: String.self, is: .count(User.existingUsernameLengthLimits) && .characterSet(.usernameAllowedSet))
        validations.add("userDomain", as: String.self, is: .count(User.userDomainLengthLimits) && .characterSet(.userDomainAllowedSet))
        validations.add("userPassword", as: String.self, is: .count(User.existingPwdLengthLimits))
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
    
    static func loginParamsLenCheck(username usrL:Int, pwd pwdL:Int) -> AppError? {
        let usrLWrong = !User.newUsernameLengthLimits.contains(usrL)
        let pwdLWrong = !User.newPwdLengthLimits.contains(pwdL)
        var labels : UserLoginErrorLabel = []
        func labelsStr()->String {
            return labels.descriptions.joined(separator: ", ")
        }
        var result : AppError? = nil
        // Check for zero-lengths:
        if (usrL == 0 && pwdL == 0) {
            labels = [.username, .password]
            result = AppError(code:.user_login_failed_name_and_password, reasons: ["Username and password are missing", labelsStr()])
        } else if (usrL == 0 && pwdL > 0 && pwdLWrong)  {
            labels = [.username]
            result = AppError(code:.user_login_failed_user_name, reasons: ["Username is missing", labelsStr()])
        } else if (pwdL == 0 && usrL > 0 && usrLWrong)  {
            labels = [.password]
            result = AppError(code:.user_login_failed_user_name, reasons: ["Password is missing", labelsStr()])
        } else if usrLWrong && pwdLWrong {
            labels = [.username, .password]
            result = AppError(code:.user_login_failed_name_and_password, reasons: ["Username and / or password may be wrong wrong", labelsStr()])
        } else if usrLWrong && !pwdLWrong {
            labels = [.username]
            result = AppError(code:.user_login_failed_user_name, reasons: ["Username may be wrong", labelsStr()])
        } else if !usrLWrong && pwdLWrong {
            labels = [.password]
            result = AppError(code:.user_login_failed_password, reasons: ["Password may be wrong", labelsStr()])
        }
        
        return result
    }
    
    func loginParamsLenCheck(username usrL:Int, pwd pwdL:Int) -> AppError? {
        return Self.loginParamsLenCheck(username: usrL, pwd: pwdL)
    }
}

