//
//  UserSession.swift
//
//
//  Created by Ido on 26/01/2024.
//

import Vapor
import Fluent
import MNUtils
import JWT
import Logging

fileprivate let dlog : Logger? = Logger(label:"UserSession")

enum SessionSource: String, Content, Codable, CaseIterable {
    case signup
    case login
    case tokenRefresh
}

enum SessionTerminationSource: String, Content, Codable, CaseIterable {
    case timeout
    case logout
    case kickedOut
}

struct UserSession: AppEncodableVaporResponse {
    
    struct Public : AppEncodableVaporResponse, AsyncResponseEncodable {
        let accessToken : AccessToken.Public
        let user: User.Public
        let startTime: Date
        let startSource : SessionSource
        let terminationTime: Date?
        let terminationSource : SessionTerminationSource?
        let clientRedirect : String? // "client_redirect"
    }
    
    let accessToken: AccessToken
    let startTime: Date?
    let startSource : SessionSource
    var terminationTime: Date?
    var terminationSource : SessionTerminationSource?
    
    init(token:AccessToken, req:Request, source:SessionSource) {
        self.accessToken = token
        self.startTime = self.accessToken.createdAt
        self.startSource = source
        self.terminationTime = nil
        self.terminationSource = nil
    }
    
    func asPublic(redirect:URL? = nil) throws ->Public {
        return try Public(accessToken: self.accessToken.asPublic(),
                          user: self.accessToken.user.asPublic(),
                          startTime: self.startTime ?? self.accessToken.createdAt ?? Date.now,
                          startSource: self.startSource,
                          terminationTime: self.terminationTime,
                          terminationSource: self.terminationSource,
                          clientRedirect: redirect?.absoluteString)
    }
    
    mutating func terminate(terminationSource:SessionTerminationSource, terminatedAt : Date? = nil) {
        self.terminationTime = terminatedAt ?? Date.now
        self.terminationSource = terminationSource
    }
}
