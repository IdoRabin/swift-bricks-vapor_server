//
//  AppResultAcceptDecline.swift
//  
//
//  Created by Ido on 26/11/2022.
//

import Foundation

public enum AppResultAcceptDecline : CustomStringConvertible {
    case accept
    case decline
    
    public var description: String {
        switch self {
        case .accept: return "AppResultAcceptDecline.accept"
        case .decline: return "AppResultAcceptDecline.decline"
        }
    }
}

typealias AppResultAcceptedDeclined = Result<AppResultAcceptDecline, AppError>
typealias AppResultAcceptedDeclinedBlock = (AppResultAcceptedDeclined)->Void
