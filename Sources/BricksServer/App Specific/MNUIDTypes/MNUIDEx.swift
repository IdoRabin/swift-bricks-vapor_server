//
//  MNUIDTypesEx.swift
//  
//
//  Created by Ido on 24/05/2023.
//

import Foundation
import MNUtils

extension MNUID {
    convenience init(type:MNUIDTypes = .doc) {
        self.init(typeStr: type.rawValue)
    }

    convenience init(uidV5 auid: UUID, type:MNUIDTypes) {
        self.init(uid:auid, typeStr:type.rawValue)
    }
    
    convenience init?(uuidString: String, type buidType:MNUIDTypes) {
        guard let auid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.init(uid:auid, typeStr:buidType.rawValue)
    }
}
