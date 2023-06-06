//
//  BrickVersionControlType.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import Foundation

enum BrickVersionControlType : String, AppModelStrEnum {
    
    // NOTE: AppModelStrEnum MUST have string values = "my_string_value" for each string case.
    case none       = "none"
    case git        = "git"
    case svn        = "svn"
    case mercurial  = "mercurial"
    
    static var all : [BrickVersionControlType] {
        return [.none, .git, .svn, .mercurial]
    }
}

//extension BrickVersionControlType /* VCS protocol factory */ {
//
//    func factoryCreateVCS(path:URL?)->VCS? {
//        if let path = path {
//            switch self {
//            case .git:
//                return VCSGit(path: path)
//            default:
//                assert(false, "VCS factory not implemented for BrickVersionControlType \(self)")
//            }
//        }
//        return nil
//    }
//}
