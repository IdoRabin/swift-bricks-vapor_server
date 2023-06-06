//
//  MNUIDTypes.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation
import MNUtils
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("TUID")

enum MNUIDTypes : String {
    case doc = "DOC"
    case docsettings = "DSET"
    case docstats = "DSTT"
    case docinfo = "DINF"
    case doclayers = "DLRS"
    
    case layer = "LYR"
    case user = "USR"
    case usersettings = "USET"
    case role = "ROL"
    
    case person = "PER"
    case company = "COM"
}
