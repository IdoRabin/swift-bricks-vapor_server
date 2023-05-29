//
//  Company.swift
//  Company model
//
//  Created by Ido on 28/07/2022.
//

import Foundation
import Fluent

final class Company {
    
    enum CodingKeys : String {
        case id = "id"
        case name = "name"
        case tags = "tags"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    // MARK: Identifiable / BUIDable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    var id : UUID?
    
    var mnUID : CompanyUID? {
        guard let uid = self.id else {
            return nil
        }
        return CompanyUID(uid: uid)
    }
    
    @Field(key: CodingKeys.name.fieldKey)
    var name : [String]
    
    // The Companie's list of possible tags
    @Field(key: CodingKeys.tags.fieldKey)
    var tags : [String]
    
    // Example of a children relation.
    @Children(for: \.$company)
    var personnel: [Person]
}

extension  Company : Codable & Hashable {
    // MARK: Equatable
    static func ==(lhs:Company, rhs:Company)->Bool {
        return lhs.mnUID == rhs.mnUID &&
               lhs.name == rhs.name &&
               lhs.tags == rhs.tags &&
               lhs.personnel == rhs.personnel
    }
    
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.name)
        hasher.combine(self.tags)
        hasher.combine(self.personnel)
    }
}
