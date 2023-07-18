//
//  AppResultUpdates.swift
//  
//
//  Created by Ido on 26/11/2022.
//

import Foundation
import MNUtils

typealias AppResultUpdated<Success:Any> = Result3<Success, AppError>

extension AppResultUpdated {
    static func failure(fromError:Error)->AppResultUpdated<Success> {
        return AppResultUpdated.failure(AppError(error: fromError))
    }
    
    static func failure<Success:Any>(code appErrorCode:AppErrorCode, reason:String? = nil)->AppResultUpdated<Success> {
        return AppResultUpdated.failure(AppError(code:appErrorCode, reason: reason))
    }
    
    static func failure<Success:Any>(code appErrorCode:AppErrorCode, reasons:[String]? = nil)->AppResultUpdated<Success> {
        return AppResultUpdated.failure(AppError(code:appErrorCode, reasons: reasons))
    }
}

//public enum AppResultUpdates<Value:Any> : CustomStringConvertible, CaseIterable {
//    case noChanges(Value? = nil)
//    case newData(Value? = nil)
//
//    public var value: Value? {
//        switch self {
//        case .newData(let value): return value
//        case .noChanges(let value): return value
//        }
//        return nil
//    }
//
//    public var description: String {
//        switch self {
//        case .newData(let value): return "AppResultUpdates.newData(\(value.descOrNil))"
//        case .noChanges(let value): return "AppResultUpdates.noChanges(\(value.descOrNil))"
//        }
//    }
//
//    static func sucessFrom(noChangesBool:Bool, prevValue:Value?, newValue:Value?)-> AppResultUpdates<Value> {
//        if noChangesBool {
//            return .noChanges(prevValue)
//        } else {
//            return .newData(newValue)
//        }
//    }
//
//    static func sucessBy(equatingPrevValue prevValue:Value?, with newValue:Value?)-> AppResultUpdates<Value> where Value : Equatable {
//        return sucessFrom(noChangesBool: (prevValue == newValue), prevValue: prevValue, newValue: newValue)
//    }
//
//    static func sucessFrom(noChangeTest:(_ prevValue:Value?, _ newValue:Value?)->Bool, prevValue:Value?, newValue:Value?)-> AppResultUpdates<Value> {
//        if noChangeTest(prevValue, newValue) {
//            return .noChanges(newValue)
//        } else {
//            return .newData(newValue)
//        }
//    }
//}
//
//typealias AppResultUpdated<Value:Any> = Result<AppResultUpdates<Value>, AppError>
//typealias AppResultUpdatedBlock<Value:Any> = (AppResultUpdated<Value>)->Void
//
//extension AppResultUpdated {
//
//    static func sucessFrom<SuccValue : Any>(noChangesBool:Bool, prevValue:SuccValue?, newValue:SuccValue?)-> AppResultUpdated<SuccValue> {
//        return .success(AppResultUpdates.sucessFrom(noChangesBool:noChangesBool, prevValue: prevValue, newValue: newValue))
//    }
//
//    static func sucessBy<SuccValue : Any>(equatingPrevValue prevValue:SuccValue?, with newValue:SuccValue?)-> AppResultUpdated<SuccValue> where SuccValue : Equatable {
//        return .success(AppResultUpdates.sucessBy(equatingPrevValue: prevValue, with: newValue))
//    }
//
//    static func sucessFrom<SuccValue : Any>(noChangeTest:(_ prevValue:SuccValue?, _ newValue:SuccValue?)->Bool, prevValue:SuccValue?, newValue:SuccValue?)-> AppResultUpdated<SuccValue> {
//        return .success(AppResultUpdates.sucessFrom(noChangeTest: noChangeTest, prevValue: prevValue, newValue: newValue))
//    }
//}
