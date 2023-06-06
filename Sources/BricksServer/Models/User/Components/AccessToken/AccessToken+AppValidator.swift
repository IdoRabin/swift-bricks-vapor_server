//
//  File.swift
//  
//
//  Created by Ido on 29/11/2022.
//

import Foundation
#if VAPOR
import Vapor
#endif

extension AccessToken : AppValidatable {
    
//case id = "id"
//case expirationDate = "expiration_date"
//case lastUsedDate = "last_used_date"
//case user = "user_id"
//case userUUIDStr = "user_id_str"
    
    static func validations(_ validations: inout AppValidations) {
        validations.add("id", as:String.self, is: !.empty)
        validations.add("expirationDate", as:Date.self, is: .isInTheFuture)
    }
}
