//
//  AppError+HTTPResponseStatus.swift
//  
//
//  Created by Ido on 12/10/2022.
//

import Foundation
import Vapor; // HTTPResponseStatus comes from here

extension AppError /*vapor extensions */  {
    var httpStatus : HTTPResponseStatus? {
        return AppErrorCode.asHTTPResponseStatus(code: self.code)
    }
}

extension AppErrorCode {
    static func asHTTPResponseStatus(code:AppErrorInt) -> HTTPResponseStatus? {
        return AppErrorCode(rawValue: code)?.httpStatusCode;
    }
    
    var httpStatusCode : HTTPResponseStatus? {
        var result : HTTPResponseStatus? = nil
        
        switch self {
            // IANA HTTPResponseStatus (in swift-nio)
            
            // httpStatus               // HTTPResponseStatus
            
            // 1xx
            case .http_stt_continue:            result = .continue
            case .http_stt_switchingProtocols:  result = .switchingProtocols
            case .http_stt_processing:          result = .processing
            // TODO: add '103: Early Hints' when swift-nio upgrades
            
            // iana HTTPResponseStatus (in swift-nio)
            // 2xx
            case .http_stt_ok:                  result = .ok
            case .http_stt_created:             result = .created
            case .http_stt_accepted:            result = .accepted
            case .http_stt_nonAuthoritativeInformation:       result =     .nonAuthoritativeInformation
            case .http_stt_noContent_204:           result = .noContent
            case .http_stt_resetContent:        result = .resetContent
            case .http_stt_partialContent:      result = .partialContent
            case .http_stt_multiStatus:         result = .multiStatus
            case .http_stt_alreadyReported:     result = .alreadyReported
            case .http_stt_imUsed:              result = .imUsed
            
            // iana HTTPResponseStatus (in swift-nio)
            // 3xx
            case .http_stt_multipleChoices:     result = .multipleChoices
            case .http_stt_movedPermanently:    result = .movedPermanently
            case .http_stt_found:               result = .found
            case .http_stt_seeOther:            result = .seeOther
            case .http_stt_notModified:         result = .notModified
            case .http_stt_useProxy:            result = .useProxy
            case .http_stt_temporaryRedirect:   result = .temporaryRedirect
            case .http_stt_permanentRedirect:   result = .permanentRedirect
            
            // iana HTTPResponseStatus (in swift-nio)
            // 4xx
            case .http_stt_badRequest:          result = .badRequest // MDN: 400 the server cannot or will not process the request due to something that is perceived to be a client error (for example, malformed request syntax, invalid request message framing, or deceptive request routing).
            case .http_stt_unauthorized:        result = .unauthorized // MDN: 401 unauthorized status code indicates that the client request has not been completed because it lacks valid authentication credentials for the requested resource.
            case .http_stt_paymentRequired:     result = .paymentRequired
            case .http_stt_forbidden:           result = .forbidden // MDN 403 The HTTP 403 Forbidden response status code indicates that the server understands the request but refuses to authorize it. Use 410 is the resource is permenantly dead.
            case .http_stt_notFound:            result = .notFound // MDN 404: response status code indicates that the server cannot find the requested resource. use 410 - .gone when resource is permenantly dead / removed.
            case .http_stt_methodNotAllowed:    result = .methodNotAllowed
            case .http_stt_notAcceptable:       result = .notAcceptable // MDN 406: use only if server cannot supply values according to the requests' "Accept" or "Accept-Encoding"  headers
            case .http_stt_proxyAuthenticationRequired: result = .proxyAuthenticationRequired
            case .http_stt_requestTimeout:      result = .requestTimeout
            case .http_stt_conflict:            result = .conflict // 409 
            case .http_stt_gone:                result = .gone // 410
            case .http_stt_lengthRequired:      result = .lengthRequired
            case .http_stt_preconditionFailed:  result = .preconditionFailed
            case .http_stt_payloadTooLarge:     result = .payloadTooLarge
            case .http_stt_uriTooLong:          result = .uriTooLong
            case .http_stt_unsupportedMediaType:    result = .unsupportedMediaType
            case .http_stt_rangeNotSatisfiable:     result = .rangeNotSatisfiable
            case .http_stt_expectationFailed:   result = .expectationFailed
            case .http_stt_imATeapot:           result = .imATeapot
            case .http_stt_misdirectedRequest:  result = .misdirectedRequest
            case .http_stt_unprocessableEntity: result = .unprocessableEntity
            case .http_stt_locked:              result = .locked
            case .http_stt_failedDependency:    result = .failedDependency
            case .http_stt_upgradeRequired:     result = .upgradeRequired
            case .http_stt_preconditionRequired:    result = .preconditionRequired
            case .http_stt_tooManyRequests:     result = .tooManyRequests // 429 throttle limit - 
            case .http_stt_requestHeaderFieldsTooLarge:  result = .requestHeaderFieldsTooLarge
            case .http_stt_unavailableForLegalReasons:   result = .unavailableForLegalReasons
            
            // iana HTTPResponseStatus (in swift-nio)
            // 5xx
            case .http_stt_internalServerError:      result = .internalServerError
            case .http_stt_notImplemented:           result = .notImplemented
            case .http_stt_badGateway:               result = .badGateway
            case .http_stt_serviceUnavailable:       result = .serviceUnavailable
            case .http_stt_gatewayTimeout:           result = .gatewayTimeout
            case .http_stt_httpVersionNotSupported:  result = .httpVersionNotSupported
            case .http_stt_variantAlsoNegotiates:    result = .variantAlsoNegotiates
            case .http_stt_insufficientStorage:      result = .insufficientStorage
            case .http_stt_loopDetected:             result = .loopDetected
            case .http_stt_notExtended:              result = .notExtended
            case .http_stt_networkAuthenticationRequired:  result = .networkAuthenticationRequired // MDN: The HTTP 511 Network Authentication Required response status code indicates that the client needs to authenticate to gain network access. This status is not generated by origin servers, but by intercepting proxies that control access to the network.
            default:
                result = nil
        }
        
        return result;
    }
}
