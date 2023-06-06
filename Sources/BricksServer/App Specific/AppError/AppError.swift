//
//  AppErrors.swift
//  grafo
//
//  Created by Ido on 10/07/2021.
//

import Foundation
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppError")

/// Main app class of error, is derived from Error, but can be initialized by AppError codes and also in concurrance with NSErrors and other Errors and underlying errors / filtered before determining eventual error code
/// The main aim in this class is to wrap each error raised in the app from any source into a more organized state

class AppError : Error, AppErrorable, JSONSerializable, CustomDebugStringConvertible {
    
    static let DEFAULT_DOMAIN = "com.\(AppConstants.APP_NAME).AppError"
    
    // MARK: MNErrorable
    var desc: String
    
    var domain: String = "AppError"
    
    var code: AppErrorInt
    
    private (set) var underlyingError: AppError?
    private (set) var reasons:[String]?
    
    // MARK: lifecycle / init (organic)
    /// Init in base level (try not to use this init)
    ///
    /// - Parameters:
    ///   - newDomain: domain of error.
    ///   - newCode: code of error
    ///   - newDescription: description of error (should b localized)
    ///   - newReasons: array of strings that detail the cause and exact situation where the error was raisedd (developer eyes only)
    ///   - newUnderlyingError: underlying error that was reaised befoer or was the cause to the main error
    init(domain newDomain:String, code newCode:AppErrorInt, description newDescription:String, reasons newReasons:[String]? = nil, underlyingError newUnderlyingError:Error?) {
        
        // Init members
        domain = newDomain
        code = newCode
        desc = newDescription
        if let underError = newUnderlyingError {
            underlyingError = AppError(error: underError)
        }
        reasons = newReasons
        
        self.validatSelf()
        
        // Tracks any error created
        self.trackError(error: self)
    }
    
    // Convenience
    convenience init(code appErrCode:AppErrorCode, description newDescription:String? = nil, reasons newReasons:[String]? = nil, underlyingError newUnderlyingError:Error? = nil) {
        self.init(domain: appErrCode.domain,
                  code: appErrCode.code,
                  description: newDescription ?? "\(appErrCode.domain).\(appErrCode.code)",
                  reasons: newReasons,
                  underlyingError: newUnderlyingError)
    }
    
    convenience init(code appErrCode:AppErrorCode, description newDescription:String? = nil, reason newReason:String? = nil, underlyingError newUnderlyingError:Error? = nil) {
        self.init(domain: appErrCode.domain,
                  code: appErrCode.code,
                  description: newDescription ?? "\(appErrCode.domain).\(appErrCode.code)",
                  reasons: (newReason != nil) ? [newReason!] : nil,
                  underlyingError: newUnderlyingError)
    }
    
    // AppError(code:.misc_failed_crypto, reason: "bad access token")
    // MARK: Funational methods
    private func validatSelf() {
        #if DEBUG
        if self.desc.contains("couldn't") {
            dlog?.warning("AppError.init(domain:newCode:description:reasons:underlyingError) Exception: Desc: \(desc)\n code: \(self.code) domain: \(self.domain) description: \(self.description) lines: \(self.reasons?.descriptionLines ?? "<no reason/s>")")
        }
        #endif
    }
    
    func setUnderlyingError(err:AppError) {
        if self != err && self.underlyingError != err {
            self.underlyingError = err
        }
    }
    
    // MARK: informative funcs
    var reason: String {
        get {
            return reasonsLines ?? self.desc
        }
        set {
            if newValue.count > 0 {
                if let reas = reasons {
                    if !reas.contains(newValue) {
                        reasons?.append(newValue)
                    }
                } else {
                    reasons = [newValue]
                }
            }
        }
    }
    
    func appErrorCode() -> AppErrorCode? {
        guard let result = AppErrorCode(rawValue:code) else {
            return nil
        }
        return result
    }
    
    func appErrorCode() throws -> AppErrorCode  {
        guard let result = AppErrorCode(rawValue:code) else {
            throw AppError(code:AppErrorCode.misc_failed_decoding, reason:"AppError failed converting code [\(code)] to AppErrorCode!")
        }
        return result
    }
    
    var localizedDescription: String {
        get {
            return desc
        }
    }
            
    public var debugDescription: String {
        return "<AppError \(self.domain) \(self.code)> [\(self.reason)]"
    }
    
    var hasUnderlyingError : Bool {
        return underlyingError != nil
    }
    
    var reasonsLines: String? {
        guard let reasons = reasons else {
            return nil
        }
        
        if reasons.count > 1 {
            return reasons.descriptionLines
        }
        return reasons.first
    }
}

// MARK: error trackign / loggign
extension AppError { /* error tracking / logging*/
    
    /// Track an error using the AppTracking mechanism (analytics)
    ///
    /// - Parameter error: an SAError to be sent to the analytics system
    private func trackError(error:AppError) {
        // let errorName = "error:" + error.domain + " code:" + String(error.code)
        
        // Create params for the analytics system:
        var params : [String:Any] = [:]
        params["description"] = error.desc
        if let foundReasons = error.reasons {
            params["reasons"] = foundReasons.joined(separator: "|")
        }
        
        // Add params for the underlying error
        if let underlyingError = error.underlyingError {
            let desc = "error:" + underlyingError.domain + " code:" + String(underlyingError.code)
            params["underlying_error"] = desc
            params["underlying_error_desc"] = underlyingError.desc
            if let underReasons = underlyingError.reasons {
                params["underlying_error_reasons"] = underReasons.joined(separator: "|")
            }
        }
        
        // Param values can be up to 100 characters long. The "firebase_", "google_" and "ga_" prefixes are reserved and should not be used
        // TODO: Uncomment
        #if os(OSX)
        // AppTracking.shared.trackEvent(category: TrackingCategory.Errors, name: errorName, parameters:(params.count > 0 ? params : nil))
        #elseif os(iOS)
        // Does nothing
        #endif
    }
}

// MARK: to / from other error types
extension AppError { /* converting to / from other error types */
    
    /// Init an SAError using any SAErrorCodable
    ///
    /// - Parameters:
    ///   - fromOther:any AppErrorCodable to deraive the properties of the new error (see AppErrors)
    ///   - reasons: (optional) reasons array describing the exact situations raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(fromOther other:AppErrorCodable, /*we needed to use this name for disambiguation details->*/reasonsArray:[String]?, underlyingError:Error? = nil) {
        var saunderlying : AppError? = nil
        if let underlyingError = underlyingError as? AppError {
            saunderlying = underlyingError
        } else if let underlyingError = underlyingError {
            saunderlying = AppError(error:underlyingError)
        }
        
        self.init(domain:other.domain, code:other.code, description:other.desc, reasons: reasonsArray, underlyingError: (saunderlying != nil ? saunderlying! : nil))
    }
    
    /// Init an AppError using any AppErrorCodable
    ///
    /// - Parameters:
    ///   - fromOther: any AppErrorCodable to deraive the properties of the new error (see AppErrors)
    ///   - reason: (optional) reason describing the exact situation raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(fromOther other:AppErrorCodable, reason:String? = nil, underlyingError:Error? = nil) {
        var newReasons : [String]? = nil
        if let reason = reason {
            newReasons = [reason]
        }
        self.init(fromOther:other, reasonsArray:newReasons, underlyingError:underlyingError)
    }
    
    // MARK: From NSError
    convenience init(nsError srcError:NSError?, defaultErrorCode:AppErrorCode, reason:String? = nil) {
        let reasons : [String]? = reason != nil ? [reason!] : nil
        self.init(nsError: srcError, defaultErrorCode: defaultErrorCode, reasons: reasons)
    }
    
    convenience init(nsError srcError:NSError?, defaultErrorCode:AppErrorCode, reasons:[String]?) {
        var reasons = reasons
        if reasons == nil || reasons?.count ?? 0 == 0 {
            reasons = [srcError?.reason ?? defaultErrorCode.domainCodeDesc]
        }
        
        if let sourceError = srcError {
            switch (sourceError.code, sourceError.domain) {
            case (-1009, NSURLErrorDomain), (-1003, NSURLErrorDomain), (-1004, NSURLErrorDomain), (-1001, NSURLErrorDomain):
                self.init(code:AppErrorCode.web_internet_connection_error, reasons:reasons, underlyingError:sourceError)
            case (3, "Alamofire.AFError"):
                self.init(code:AppErrorCode.web_unexpected_response, reasons:reasons, underlyingError:sourceError)
            default:
                self.init(code:defaultErrorCode, reasons: reasons, underlyingError: sourceError)
            }
        } else {
            self.init(code:defaultErrorCode, reasons: reasons, underlyingError: srcError)
        }
    }
    
    convenience init(mnError:MNErrorable) {
        var reasons = [mnError.reason]
        if let mnErr = mnError as? MNError {
            reasons = mnErr.reasons ?? reasons
        }
        self.init(code: AppErrorCode(rawValue: mnError.code) ?? .misc_unknown, description:mnError.desc, reasons:reasons)
    }
    // MARK: From Any other Error
    /// Init an AppError using any Error
    ///
    /// - Parameter error: error to be converted to an SAError
    convenience init(error:Error) {
        #if DEBUG
        if String(describing:type(of: error)) == "\(Self.self)" {
            dlog?.raiseAssertFailure("Error converted to error")
        }
        
        #endif
        if let mnErrorble = error as? MNErrorable {
            self.init(mnError: mnErrorble)
        } else {
            self.init(nsError: error as NSError, defaultErrorCode:.misc_unknown)
        }
    }
    
    /// Conveniene optional init an SAError using any Error?
    /// May return nil if provided error is nil
    ///
    /// - Parameter error: error to be converted to an SAError
    convenience init?(error:Error?) {
        #if DEBUG
            if String(describing:type(of: error)) == "\(Self.self)" {
                dlog?.raiseAssertFailure("Error converted to error")
            }
        #endif
        
        if let error = error {
            self.init(nsError:error as NSError, defaultErrorCode: .misc_unknown)
        }
        return nil
    }
}

/*
        
    /// Will duplicate existing error but will set the provided underlying error
    /// - Parameters:
    ///   - fromError: curArror the error to duplicate with an additional underlying error
    ///   - withUnderlyingError: underlying erro to set in the new error
    convenience init(fromError curError:AppError, withUnderlyingError newUnderlyingErr : AppError) {
        self.init(domain: curError.domain, code: curError.code, description: curError.desc,
                  reasons: curError.reasons,
                underlyingError: newUnderlyingErr)
    }
    /// Init using a given NSError
    ///
    /// - Parameter nserror: NSError to convert to AppError
    init (nserror:NSError, reason:String? = nil) {
        
        // Init memebrs from the NSError:
        domain = nserror.domain
        code = nserror.code
        desc = nserror.localizedDescription
        var newReasons : [String] = []
        
        // Add detail param to details array
        if let reason = reason {
            newReasons.append(reason)
        }
        
        // Add other userInfo keys as details
        if nserror.userInfo.count > 0 {
            for (key,value) in nserror.userInfo {
                let aKey = key.replacingOccurrences(of: "NSValidationErrorKey", with: "❗NSValidationErrorKey")
                newReasons.append("\(aKey) : \(value)")
            }
        }
        reasons = (newReasons.count > 0) ? newReasons : nil
        
        // Copy underlying error (but convert to AppError as well)
        if let underlyingError = nserror.userInfo[NSUnderlyingErrorKey] as? NSError {
            self.underlyingError = AppError(nserror: underlyingError)
        } else {
            self.underlyingError = nil
        }
        
        self.validatSelf()
        
        // Tracks any error created
        self.trackError(error: self)
    }

    
    
    convenience init(code:AppErrorCode, reasons newReasons:[String]?, underlyingError:Error? = nil) {
        var saunderlying : AppError? = nil
        if let underlyingError = underlyingError as? AppError {
            saunderlying = underlyingError
        } else if let underlyingError = underlyingError {
            saunderlying = AppError(error:underlyingError)
        }
        
        let adomain = code.domain
        self.init(domain:adomain,
                  errcode:code,
                  description:code.desc,
                  reasons: newReasons,
                  underlyingError: (saunderlying != nil ? saunderlying! : nil))
    }
    

    convenience init(code:AppErrorCode, reason : String?, underlyingError:Error? = nil){
        self.init(code: code, reasons: reason != nil ? [reason!] : nil, underlyingError:underlyingError)
    }
    
    /// Init an SAError using any SAErrorCodable
    ///
    /// - Parameters:
    ///   - code: code for the error (see AppErrors)
    ///   - reasons: (optional) array of details describing the exact situation raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(_ code:AppErrorCodable, reasons newReasons:[String]?, underlyingError:Error? = nil) {
        var saunderlying : AppError? = nil
        if let underlyingError = underlyingError, !(underlyingError is AppError) {
            saunderlying = AppError(error:underlyingError)
        }
        self.init(domain:code.domain, code:code.code, description:code.desc, reasons: newReasons, underlyingError: (saunderlying != nil ? saunderlying! : nil))
    }
    
    
    /// Init an SAError using any Error
    ///
    /// - Parameter error: error to be converted to an SAError
    convenience init(error:Error) {
        #if DEBUG
        if String(describing:type(of: error)) == "SAError" {
            dlog?.raiseAssertFailure("Error converted to error")
        }
        #endif
        
        self.init(nserror: error as NSError)
    }
    
    /// Conveniene optional init an SAError using any Error?
    /// May return nil if provided error is nil
    ///
    /// - Parameter error: error to be converted to an SAError
    convenience init?(error:Error?) {
        #if DEBUG
            if String(describing:type(of: error)) == "SAError" {
                dlog?.raiseAssertFailure("Error converted to error")
            }
        #endif
        
        if let error = error {
            self.init(nserror: error as NSError)
        }
        return nil
    }
    
    // Track error:
    
    /// Track an error using the AppTracking mechanism (analytics)
    ///
    /// - Parameter error: an SAError to be sent to the analytics system
    private func trackError(error:AppError) {
        // let errorName = "error:" + error.domain + " code:" + String(error.code)
        
        // Create params for the analytics system:
        var params : [String:Any] = [:]
        params["description"] = error.desc
        if let foundReasons = error.reasons {
            params["reasons"] = foundReasons.joined(separator: "|")
        }
        
        // Add params for the underlying error
        if let underlyingError = error.underlyingError {
            let desc = "error:" + underlyingError.domain + " code:" + String(underlyingError.code)
            params["underlying_error"] = desc
            params["underlying_error_desc"] = underlyingError.desc
            if let underReasons = underlyingError.reasons {
                params["underlying_error_reasons"] = underReasons.joined(separator: "|")
            }
        }
        
        // Param values can be up to 100 characters long. The "firebase_", "google_" and "ga_" prefixes are reserved and should not be used
        #if os(OSX)
        // AppTracking.shared.trackEvent(category: TrackingCategory.Errors, name: errorName, parameters:(params.count > 0 ? params : nil))
        #elseif os(iOS)
        // Does nothing
        #endif
    }
}

extension AppError : AppErrorable {
}

extension AppError /*appErrors*/ {
    
    convenience init(fromError input:Error?, defaultErrorCode:AppErrorCode, reason:String?) {
        self.init(fromError:input, defaultErrorCode:defaultErrorCode, reasons:reason != nil ? [reason!] : [])
    }
    
    convenience init(fromError input:Error?, defaultErrorCode:AppErrorCode, reasons:[String]?) {
        if let appError = input as? AppError {
            self.init(domain:appError.domain, code:appError.code, description:appError.desc, reasons: reasons, underlyingError: nil)
        } else if let nsError = input as? NSError {
            self.init(fromNSError: nsError, defaultErrorCode: defaultErrorCode, reasons: reasons)
        } else {
            self.init(code:defaultErrorCode, reasons:reasons)
        }
    }
    
    convenience init(fromNSError underError:NSError?, defaultErrorCode:AppErrorCode, reason:String? = nil) {
        let reasons : [String]? = reason != nil ? [reason!] : nil
        self.init(fromNSError: underError as NSError?, defaultErrorCode: defaultErrorCode, reasons: reasons)
    }
    
    convenience init(fromNSError underError:NSError?, defaultErrorCode:AppErrorCode, reasons:[String]?) {
        if let underError = underError {
            switch (underError.code, underError.domain) {
            case (-1009, NSURLErrorDomain), (-1003, NSURLErrorDomain), (-1004, NSURLErrorDomain), (-1001, NSURLErrorDomain):
                self.init(AppErrorCode.web_internet_connection_error, reasons:reasons, underlyingError:underError)
            case (3, "Alamofire.AFError"):
                self.init(AppErrorCode.web_unexpected_response, reasons:reasons, underlyingError:underError)
            default:
                self.init(defaultErrorCode, reasons: reasons, underlyingError: underError)
            }
        } else {
            self.init(defaultErrorCode, reasons: reasons, underlyingError: underError)
        }
    }
}

extension AppError : Equatable {
    public static func == (lhs: AppError, rhs: AppError) -> Bool {
        var result = lhs.domain == rhs.domain && lhs.code == rhs.code
        if result {
            if lhs.hasUnderlyingError != rhs.hasUnderlyingError {
                result = false
            } else if let lhsu = lhs.underlyingError, let rhsu = rhs.underlyingError {
                result = lhsu == rhsu
            }
        }
        return result
    }
}

extension AppError : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.code)
        hasher.combine(self.reasons)
        hasher.combine(self.reason)
    }
}

extension Result3 where Failure : AppError {
    
    var appError : AppError? {
        switch self {
        case .successNoChange: return nil
        case .successChanged: return nil
        case .failure(let err): return err
            // default: return nil
        }
    }
}

extension Result where Failure : AppError {
    
    var appError : AppError? {
        switch self {
        case .success: return nil
        case .failure(let err): return err
            // default: return nil
        }
    }
}
*/

