//
//  Person.swift
//  Person model
//
//  Created by Ido on 28/07/2022.
//

import Foundation
import Fluent

#if VAPOR
import Vapor
#endif

final class Person {
    
    enum CodingKeys : String {
        case company = "company_id"
        case id = "id"
        case idinorg = "idinorg"
        case name = "name"
        case phoneNrs = "phone_nrs"
        case emails = "emails"
        case socials = "socials"
        case bDay = "birth_day"
        case eDay = "enlistment_day"
        case rank = "rank"
        case tags = "tags"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    // Owning company
    @Parent(key: CodingKeys.company.fieldKey)
    var company: Company
    
    // MARK: Identifiable / BUIDable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    var id : UUID? // primary key
    var mnUID : PersonUID? {
        guard let uid = self.id else {
            return nil
        }
        return PersonUID(uid: uid)
    }
    
    // The Person's id in thier containing organization
    @Field(key: CodingKeys.idinorg.fieldKey)
    var idInOrg : String?
    
    // The Person's name.
    @Field(key: CodingKeys.name.fieldKey)
    var name : [String]
    
    // The Person's phone number.
    @Field(key: CodingKeys.phoneNrs.fieldKey)
    var phoneNrs: [String]
    
    @Field(key: CodingKeys.emails.fieldKey)
    var emails: [String]
    
    @Field(key: CodingKeys.socials.fieldKey)
    var socials: [String:String]

    // The Person's BDay
    @Field(key: CodingKeys.bDay.fieldKey)
    var bDay: DateComponents
    
    // The Person's Enlistment Day
    @Field(key: CodingKeys.eDay.fieldKey)
    var eDay: DateComponents
    
    // The Person's current rank.
    @Enum(key: CodingKeys.rank.fieldKey)
    var rank : PersonRank
    
    // The Person's tags
    @Field(key: CodingKeys.tags.fieldKey)
    var tags : [String]
    
    // When this Person was created.
    @Timestamp(key: CodingKeys.createdAt.fieldKey, on: .create)
    var createdAt: Date?
    
    // When this Person was last updated.
    @Timestamp(key: CodingKeys.updatedAt.fieldKey, on: .update)
    var updatedAt: Date?
    
    // When this Person was last updated.
    @Timestamp(key: CodingKeys.deletedAt.fieldKey, on: .delete)
    var deletedAt: Date?
}

extension Person : Equatable, Hashable {
    // MARK: Hahsable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.company)
        hasher.combine(self.id)
        hasher.combine(self.idInOrg)
        hasher.combine(self.name)
        hasher.combine(self.phoneNrs)
        hasher.combine(self.emails)
        hasher.combine(self.socials)
        hasher.combine(self.bDay)
        hasher.combine(self.eDay)
        hasher.combine(self.rank)
        hasher.combine(self.tags)
        hasher.combine(self.createdAt)
        hasher.combine(self.updatedAt)
        hasher.combine(self.deletedAt)
    }
    
    // MARK: Equatable
    static func ==(lhs:Person, rhs:Person)->Bool {
        // NOTE: putting all members in ONE expression failes type-checking (compiler / ide limit)
        
        guard lhs.company == rhs.company &&
                lhs.id == rhs.id &&
                lhs.idInOrg == rhs.idInOrg &&
                lhs.name == rhs.name &&
                lhs.phoneNrs == rhs.phoneNrs &&
                lhs.emails == rhs.emails else {
            return false
        }
        return lhs.socials == rhs.socials &&
        lhs.bDay == rhs.bDay &&
        lhs.eDay == rhs.eDay &&
        lhs.rank == rhs.rank &&
        lhs.tags == rhs.tags &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt &&
        lhs.deletedAt == rhs.deletedAt
    }
}
