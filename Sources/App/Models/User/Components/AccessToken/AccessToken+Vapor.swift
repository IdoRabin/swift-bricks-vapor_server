//
//  AccessToken+Vapor.swift
//  
//
//  Created by Ido on 13/07/2022.
//

import Foundation
import Fluent
import JWT
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("AccessToken+Vapor")


#if VAPOR
import Vapor

// Extensions requiring no implementations
extension AccessToken : Content {}
extension AccessToken : AsyncResponseEncodable {}

/// Keys for data stored in Request.storage or Request.session.storage:
struct AccessTokenStorageKey : ReqStorageKey {
    typealias Value = AccessToken
}

struct SelfAccessTokenStorageKey : ReqStorageKey {
    typealias Value = AccessToken
}

extension AccessToken : JWTPayload, Authenticatable {
    
    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim {
        return SubjectClaim(value: self.user.$id.value!.uuidString)
    }

    // The "expirationDate" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    var expiration: ExpirationClaim {
        return ExpirationClaim(value: self.expirationDate)
    }

    func forceLoadUser(vaporRequest:Request) async->User  {
        return await self.forceLoadUser(db: vaporRequest.db)
    }
    
    func verify(context:String) throws {
        if !self.isValid {
            throw Abort(.unauthorized, reason: "token is not valid!")
        }
        if self.isEmpty {
            throw Abort(.unauthorized, reason: "token has an empty UUID 00000000-0000-0000-0000-000000000000")
        }
        if self.isExpired {
            throw Abort(.unauthorized, reason: "token has expired")
        }
    }
    
    // MARK: JWTPayload
    func verify(using signer: JWTSigner) throws {
        return try self.verify(context: "AccessToken implementing JWTPayload.verify(using:JWTSigner)")
    }
}

#endif
