//
//  File.swift
//  
//
//  Created by Ido on 28/11/2022.
//

import Foundation
#if VAPOR
import Vapor
#endif

extension Validator where T == Date {
    
    /// Validates whether a `date` is in the Future
    public static var isInTheFuture: Validator<T> {
        .init(validate: { data in
            return AppValidationResult.by(
                test: {
                    data.isFutureDate // also data.isInTheFuture
                },
                success: "Date is in the future",
                errorCode: .http_stt_badRequest,
                errorReason: "Date was expected to be a future date")
        })
    }
    
    public static var isInThePast: Validator<T> {
        .init(validate: { data in
            return AppValidationResult.by(
                test: {
                    data.isInThePast
                }, success: "Date is in the past",
                errorCode: .http_stt_badRequest,
                errorReason: "Date was expected to be a past date, but is in the future")
        })
    }
}

public extension ValidatorResults {
    
    /// `ValidatorResult` of a validator that validates whether a `String` is a valid zip code.
    struct isInTheFuture {
        public let isInTheFuture: Bool
    }
    struct isInThePast {
        public let isInThePast: Bool
    }
}

//extension ValidatorResults.isInFuture: ValidatorResult {
//
//    public var isFailure: Bool {
//        !self.isInFuture
//    }
//
//    public var successDescription: String? {
//        "Date is in the future"
//    }
//
//    public var failureDescription: String? {
//        "Date was expected to be a future date, but is not"
//    }
//}
