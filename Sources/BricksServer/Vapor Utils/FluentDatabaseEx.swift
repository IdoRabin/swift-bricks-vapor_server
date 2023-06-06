//
//  FluentDatabaseEx.swift
//  
//
//  Created by Ido on 05/12/2022.
//

import Foundation
import DSLogger

#if VAPOR || FLUENT
import Fluent

fileprivate let dlog : DSLogger? = DLog.forClass("FluentDatabaseEx")

// FluentKit
public extension Fluent.Database {
    
    /// .read() or .create() an enum type in the DB, according to the need (creates if does not already exists)
    /// - Parameters:
    ///   - enumName: name of the enum
    ///   - enumAllCases: all cases of the enum.
    /// - Returns: EventLoopFuture<DatabaseSchema.DataType> the data type schema for use in other migrations, during .prepare functions.
    func createOrGetEnumType(enumName:String, enumAllCases:[String] )->EventLoopFuture<DatabaseSchema.DataType> {
        // Read the enum type if it exists
        dlog?.info("createOrGetEnumType for enum: [\(enumName)] got cases: \(enumAllCases.descriptionsJoined)")
        let enumBuilder : EnumBuilder = self.enum(enumName)
        for caseName in enumAllCases.uniqueElements() {
            _ = enumBuilder.case(caseName)
        }
        return enumBuilder.create() // enumBuilder has no .ignoreExisting()
        
        // TODO: Check if and when we need to read() and only then create(): are instances where enums fail init are only because of wild debugging / creation / changing schemes and stoppong app run with crazzzy exit codes?
        
//        return self.enum(enumName).read().flatMapAlways({ result in
//            switch result {
//            case .success(let schema):
//                switch schema {
//                case .enum(let anEnum):
//                    // Make sure we have cases...
//                    if anEnum.cases.count != enumAllCases.count {
//                        for acase in enumAllCases {
//                            schema.case(acase)
//                        }
//                    }
//                    return self.eventLoop.makeSucceededFuture(schema)
//                default:
//                    throw AppError(code:.db_unknown, reason: "createOrGetEnumType schema type is not Enum")
//                }
//            case .failure(let error):
//                // Handle only errors: in this case, we need to create a new enum type and add its cases and return that
//                dlog?.info("createOrGetEnumType [\(enumName)] was not found: \(String(describing: error)). will creeate new")
//                let enumBuilder : EnumBuilder = self.enum(enumName)
//                for caseName in enumAllCases.uniqueElements() {
//                    _ = enumBuilder.case(caseName)
//                }
//                return enumBuilder.create() // enumBuilder has no .ignoreExisting()
//            }
//        })
    }
    
    func createOrGetEnumType<T:AppModelStrEnum>(anEnumType:T.Type)->EventLoopFuture<DatabaseSchema.DataType> {
        let name = anEnumType.dbTypeName
        let values = anEnumType.all.map { enumVal in
            return enumVal.dbRawValue
        }
        return createOrGetEnumType(enumName: name, enumAllCases: values)
    }
}

#endif
