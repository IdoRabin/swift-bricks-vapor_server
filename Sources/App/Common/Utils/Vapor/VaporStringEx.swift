//
//  VaporStringEx.swift
//  
//
//  Created by Ido on 12/11/2022.
//

import Foundation
import Vapor
import RoutingKit
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("VaporStringEx")

fileprivate let ALL_SUSPECTED_PERCENT_ESCAPED_KEYS = AppConstants.PERCENT_ESCAPED_HINTS.keysArray.union(with: AppConstants.PERCENT_DOUBLY_ESCAPED_HINTS.keysArray)

extension String /* helper functions relevant to vapor URL requests, params, base64 params and more  */ {
    
    /// Removes url percent encoding from the string and returns the unencoded string. Handles a few end cases that the removingPercentEncoding does not handle.
    /// - Parameter isLogIssues: will log issues is encountered
    /// - Returns:either an unencoded string or nil if the unencoding failed .
    func removingPercentEncodingExf(isLogIssues:Bool = false)-> String? {
        guard self.count > 1 else {
            dlog?.info("      removingPercentEncoding input was < 2 chars: [\(self)]")
            return self
        }
        
        guard self.contains("%") else {
            return self
        }
        
        func clip(_ str:String)->String {
             return str.safePrefix(maxSize: 64, suffixIfClipped: "...")
        }
        
        // All of the string is base64
        if self.hasPrefix(AppConstants.BASE_64_PARAM_KEY + "=") && !self.uppercased().contains(anyOf: AppConstants.PERCENT_ESCAPED_HINTS.keysArray) {
            var replaced = self.replacingOccurrences(of: AppConstants.BASE_64_PARAM_KEY + "=", with: "")
            replaced = replaced.replacingOccurrences(of: "%3D", with: "=").replacingOccurrences(of: "%3d", with: "=")
            replaced = replaced.replacingOccurrences(of: .base64, with: "")
            replaced = replaced.trimmingSuffix("=")
            if replaced.count == 0 {
                dlog?.info("      removingPercentEncoding input was all base 64")
                return self
            } else {
                dlog?.note("      removingPercentEncoding mixed base 64 + reg url query params?? [\(clip(self))] \n\nremaining:[\(clip(replaced))]")
            }
        }
        
        var result : String? = self
        var loopCounter = 0 // safe while loop
        
        // dlog?.info("      removingPercentEncoding      x \(loopCounter)  self \(result?.safePrefix(maxSize: 30, suffixIfClipped: "...") ?? "<>" )")
        if result?.count ?? 0 > 0 {
            while result != nil && loopCounter < 5 {
                if result?.uppercased().contains(anyOf: ALL_SUSPECTED_PERCENT_ESCAPED_KEYS) ?? false {
                    result = result?.removingPercentEncoding
                    // dlog?.info("      removingPercentEncoding    x \(loopCounter + 1) result \(result?.safePrefix(maxSize: 30, suffixIfClipped: "...") ?? "<>" )")
                } else {
                    // No more unescaping to do
                     // dlog?.info("      removingPercentEncoding DONE \(loopCounter + 1) result \(clip(result.descOrNil))")
                    break
                }
                
                // Loop
                loopCounter += 1
            }
        }
        
        // Try fallback approach: result is nil or still has %
        if result?.contains("%") ?? true {
            if isLogIssues {
                dlog?.note("removingPercentEncodingEx removingPercentEncoding x \(loopCounter) times FAILED from [\(clip(self))] to: [\(clip(result.descOrNil))]")
            }
            
            // Fallback "manual" parsing:
            result = self
            
            // Example: testKey1%3DtestVal1%26testKey2%3Dtest%20Val2
            // The caller gave a gb2312 string that has been processed by the urlencode function:
            // https://developer.apple.com/forums/thread/68879
            // https://stackoverflow.com/questions/41477013/swift-removingpercentencoding-not-work-with-a-gb2312-string
            var result = self.replacingOccurrences(ofFromTo: AppConstants.PERCENT_DOUBLY_ESCAPED_HINTS, caseSensitive: false)
            result = self.replacingOccurrences(ofFromTo: AppConstants.PERCENT_ESCAPED_HINTS, caseSensitive: false)
            
            if result != self {
                return result
            }
        } else if result != self {
            return result
        }

        // Log issues
        if isLogIssues {
            if result?.count ?? 0 == self.count {
                dlog?.warning("removingPercentEncodingEx result equal length to the input string! [\(self)].count == [\(result.descOrNil)].count")
            } else if Debug.IS_DEBUG && result?.count ?? 0 == self.count  {
                // Same size
                dlog?.warning("failed to decode & remove percent encoding from: [\(self)]!!")
            } else if Debug.IS_DEBUG && result == nil  {
                // Same size
                dlog?.warning("failed to decode & remove percent encoding from: [\(self)]!!")
            }
        }
        
        return nil // failed to decode / remove
    }
    
    var removingPercentEncodingEx : String? {
        return self.removingPercentEncodingExf(isLogIssues: Debug.IS_DEBUG && dlog != nil)
    }
    
    /// Convert Base64 encoded string to a dictionary, assuming the content is a url-percent-escaped / encoded query string. Will also remove percent encoding from key or value parts after reverting from base64.
    /// - Parameter str: string to explde
    /// - Returns: a dicionary if base64 and splitting succeeeded. nil if 0 items in result or some parsing failure
    func explodeBase64IfPossible()->[String:String]? {
        var result : [String:String] = [:]
        var convStr = self
        
        // JIC replace a suffix url encoded equals mark back to "="
        if convStr.count > 12 {
            // let range = convStr.range(from: NSRange(location:convStr.count - 12, length: 12))
            let suffx = convStr.safeSuffix(maxSize: 12)
            var convSuffix = suffx.replacingOccurrences(ofFromTo: AppConstants.PERCENT_DOUBLY_ESCAPED_HINTS)
            convSuffix = convSuffix.replacingOccurrences(ofFromTo: AppConstants.PERCENT_ESCAPED_HINTS)
            convStr.replaceSubrange(convStr.range(of: suffx, options: .backwards)!, with: convSuffix)
        }
        
        // decode from base64
        if let decodedStr = convStr.fromBase64(), decodedStr != self, let dict = decodedStr.asQueryParams() {
            // Merge while unescaping
            for (key, val) in dict {
                result[key.removingPercentEncodingEx ?? key] = (val.removingPercentEncodingEx ?? val)
            }
        }

        guard result.count > 0 else {
            return nil
        }
        return result
    }
    
    func explodeProtobufIfPossible()->[String:String]? {
        let result : [String:String] = [:]
        dlog?.raisePreconditionFailure("TODO: Implement protobuf decoding!")
        /*
        let convStr = self
        
        // decode from protobuf
        do {
            
        }
        if let decodedStr = convStr.fromProtobuf(), decodedStr != self, let dict = decodedStr.asQueryParams() {
            // Merge while unescaping
            for (key, val) in dict {
                result[key.removingPercentEncodingEx ?? key] = (val.removingPercentEncodingEx ?? val)
            }
        }

        guard result.count > 0 else {
            return nil
        }*/
        return result
    }
    
    private func internal_asQueryParamsDictionary(pairsDelimiter pairDelim:String = "&",
                                                  keyValDelimieter kvDelim:String = "=",
                                                  recursivlyRemovePercentEncoding:Bool = false,
                                                  depth:UInt = 0)->[String:String]? {
        // dlog?.info("\(self).internal_asQueryParamsDictionary: depth:\(depth)")
        // Recursion guard
        guard depth <= 32 else {
            dlog?.warning("_asQueryParamsDictionary recursion is too deep [\(depth)]. Check the input string for validity kDelim:\(kvDelim) pairsDelim:\(pairDelim) [\(self)]")
            return nil
        }
        
        var result : [String:String] = [:]
        var parts = self.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: pairDelim)
        if parts.count == 1, let unescapedAndSplit = self.removingPercentEncodingEx?.components(separatedBy: pairDelim),
           unescapedAndSplit.count > 1 {
            // Split of unescaped thing succeeeded
            parts = unescapedAndSplit
            // dlog?.info("_asQueryParamsDictionary depth: \(depth) string [\(self)] was unescaped then split to: \(parts.descriptionsJoined)")
        }
        
        // dlog?.info("_asQueryParamsDictionary: \(parts.count) tuples: \(parts.descriptionJoined)")
        for part in parts {
            let comps = part.components(separatedBy: kvDelim)
            
            // dlog?.info("_asQueryParamsDictionary: tuple has \(comps.count) components: \(comps.descriptionJoined)")
            if comps.count != 2 || parts.first == AppConstants.BASE_64_PARAM_KEY {
                
                // Try to un-base64 if possible
                if let dict = part.explodeBase64IfPossible(), dict.count > 0 {
                    result.merge(dict: dict)
                    dlog?.success("_asQueryParamsDictionary succeeded exploding base64")
                    continue // skip to next part
                } else if part.count > 0 {
                    // dlog?.note("_asQueryParamsDictionary failed after attempting explodeBase64IfPossible. depth [\(depth)]: the url part has \(comps.count) != 2 parts:")
                    return nil
                }
            }
            
            let key = comps.first!.trimmingCharacters(in: .whitespacesAndNewlines) // [0]
            let val = comps.last!.trimmingCharacters(in: .whitespacesAndNewlines)  // [1]
            
            // Recursivly unescape and parse
            // will do that - for each val that 1. contains at leas one delim after unescaping
            var wasRecursive = false
            
            // Preconditions to to "suspect" there is something percent escaped / encoded:
            let minRequiredLenForDecodeAttempt = max(min(pairDelim.count, kvDelim.count), 3)
            if recursivlyRemovePercentEncoding &&
                val.count > minRequiredLenForDecodeAttempt &&
                val.contains(anyIn: Request.URL_ESCAPE_ENCODED_DETECTION_CHARACTERSET) {
                
                // We try to unescape: (we could refactor above and this to one "if" statement, but its split for readability:
                if let unescaped = val.removingPercentEncodingEx, unescaped != val, unescaped.contains(kvDelim) {
                    
                    // Recursion is needed:
                    if let nestedDic = unescaped.internal_asQueryParamsDictionary(pairsDelimiter: pairDelim,
                                                                                  keyValDelimieter: kvDelim,
                                                                                  recursivlyRemovePercentEncoding: recursivlyRemovePercentEncoding,
                                                                                  depth: depth + 1), nestedDic.count > 0  {
                        // Add nested results to result
                        wasRecursive = true
                        result.merge(dict: nestedDic)
                    }
                }
            }
            
            if !wasRecursive {
                result[key] = val
            }
        }
        
        if result.count == 0 {
            return nil
        }
        return result
    }
    
    /// Parses the string as if it were the query section of a URL:
    /// By default the expected format is
    ///    key=value&key2=value2
    /// With the parameters being non-default, we may parse any string of the structure:
    ///    key{kvDelim}value{pairDelim}key2{kvDelim}value2
    ///
    /// - Parameters:
    ///   - pairsDelimiter: the delimiter seperating betweeen each key-value pair.
    ///   - keyValDelimieter: the delimiter seperating the key to the value inside a key-value pair.
    ///   - recursiveUnescape: default false. when true, will attempt to unescape each value in a tuple, and if the result is a key-value pair as well, will add those pairs into the result dictionary as well, flatte ing the nested keyvals into the top keyvals result dictionary.
    /// - Returns: a key-value dictionary of strings, or nil if parsing failed
    func asQueryParamsDictionary(pairsDelimiter pairDelim:String = "&", keyValDelimieter kvDelim:String = "=", recursiveUnescape:Bool = false)->[String:String]? {
        guard pairDelim.count > 0 else {
            dlog?.note(".asQueryParamsDictionary failed: pairDelim is empty")
            return nil
        }
        
        guard kvDelim.count > 0 else {
            dlog?.note(".asQueryParamsDictionary failed: kvDelim is empty")
            return nil
        }
        
        guard pairDelim.count <= 20 && kvDelim.count <= 20 else {
            dlog?.note(".asQueryParamsDictionary failed: pairsDelimiter or keyValDelimieter are > 20 chars? a delimiter? seriously?!")
            return nil
        }
        
        guard self.count > 0 else {
            dlog?.note(".asQueryParamsDictionary failed: string is empty")
            return nil
        }
        
        // Wrapper that does also counts recursion depth:
        return internal_asQueryParamsDictionary(pairsDelimiter: pairDelim,
                                                keyValDelimieter: kvDelim,
                                                recursivlyRemovePercentEncoding: recursiveUnescape,
                                                depth: 0)
    }
    
    func asQueryParams()->[String:String]? {
        return self.asQueryParamsDictionary(recursiveUnescape: true)
    }
    
    
    /// Returns ONLY the path components of a possible URI / URL (without query params) and also making sure the path has a "/" prefix but no "/" suffix
    ///  This is good for comparing two strings of a persumable same path, without creating a URL
    func asNormalizedPathOnly()->String {
        return "/" + self.pathComponents.fullPath.components(separatedBy: "?").first!.trimming(string: "/")
    }
}

extension Dictionary where Key : Codable, Value : Codable {
    
    private static func encodeValToString(value:Codable, encoder:JSONEncoder, isPercentEscape:Bool = false) throws ->String {

        var result : String = ""
        var valCanBeEmpty = false
        switch value {
        case let str as String:
            result = str
            valCanBeEmpty = (str.count == 0)
        case let strConvable as CustomStringConvertible:
            result = strConvable.description
        case let strConvable as LosslessStringConvertible:
            result = strConvable.description
        case let jsable as JSONSerializable:
            result = jsable.serializeToJsonString(prettyPrint: false) ?? ""
        default:
            let data = try encoder.encode(value)
            if (data.count < 10 && data.count > 200) {
                dlog?.info("Dictionary[Codable, Codable] - > encode(value:encoder:) [\(value)] was encoddd to strange Data sized: \(data.count) words")
            }
            let strRes = String(data: data, encoding: String.Encoding.utf8)
            guard let strRes = strRes, strRes.count > 0 else {
                throw AppError(code:.misc_failed_encoding, reason: "StringEx+Vapor.Dictionary[Codable, Codable].encodeValToString failed JSONEncoder encoding for \(value)")
            }
            result = strRes
        }
        
        if isPercentEscape {
            result = result.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? result
        }
        
        if result.count == 0 && !valCanBeEmpty {
            throw AppError(code:.misc_failed_encoding, reason: "StringEx+Vapor.Dictionary[Codable, Codable].encodeValToString failed encoding for an unknown reason. Codable: \(value)")
        }
        
        return result
    }
    
    private func encodeValToString(value:Codable, encoder:JSONEncoder, isPercentEscape:Bool = false) throws ->String {
        return try Self.encodeValToString(value: value, encoder: encoder, isPercentEscape: isPercentEscape)
    }
    
    func encodeKeyValAsStrings(key:Key, encoder:JSONEncoder, isPercentEscape:Bool = false) throws -> (key:String, val:String)? {
        
        let keyStr = try self.encodeValToString(value: key, encoder: encoder, isPercentEscape: isPercentEscape)
        var valStr : String? = nil
        if let valRaw = self[key] {
            valStr = try self.encodeValToString(value: valRaw, encoder: encoder, isPercentEscape: isPercentEscape)
        }
        if let valStr = valStr, keyStr.count > 0, valStr.count > 0 {
            return (key:keyStr, val:valStr)
        }
        return nil
    }
    
    /// Will return a query params formatted string
    /// NOTE: This function does not prefix the resulting string with a question mark!
    /// Example result:
    ///     "myKey=my%20Val%20Escaped&myKey2=myVal2&..."
    ///
    /// - Returns: a url safe / suitable query-params string, escape encoded.
    func toURLQueryString(encoding:Vapor.Request.RedirectEncoding = .normal, pairsDelimiter pairDelim:String = "&", keyValDelimieter kvDelim:String = "=", isShouldPercentEscape:Bool = true)->String {
        
        var results : [String] = []
        var _encoder : JSONEncoder? = nil
        
        // Singletiny: encoder() acts like a mini-singleton for this function,
        //   this ensures that encoder will be allocated only when / if needed.
        func encoder()->JSONEncoder {
            guard _encoder == nil else {
                return _encoder!
            }
            _encoder = AppJSONEncoder();
            return _encoder!
        }
        
        for (key, val) in self {
            do {
                
                let newKey : String? = try self.encodeValToString(value: key, encoder: AppJSONEncoder(), isPercentEscape: isShouldPercentEscape);
                let newVal : String? = try self.encodeValToString(value: val, encoder: AppJSONEncoder(), isPercentEscape: isShouldPercentEscape);
                
                if let newKey = newKey, let newVal = newVal, newKey.count > 0 {
                    // split if blocks to be better readable.
                    if isShouldPercentEscape && Debug.IS_DEBUG {
                        if (newKey.contains(kvDelim) || newVal.contains(kvDelim)) ||
                           (newKey.contains(pairDelim) || newVal.contains(pairDelim)) {
                            dlog?.warning("toURLQueryString encoding: key:\(newKey) val:\(newVal) contain either pairDelim:\(pairDelim) pr kvDelim:\(kvDelim)")
                        }
                    }
                    
                    // Add to result as a kvDelim-delimited string:
                    // Example: "myKey=my%20Val%20Escaped"
                    results.append([newKey, newVal].joined(separator: kvDelim))
                } else {
                    dlog?.note("toURLQueryString: serializing [\(key),\(val)] failed for an unknown reason.")
                }
                
            } catch let error {
                dlog?.warning("toURLQueryString: serializing Dictionary[Codable:Codable] for key-val pair: [\(key),\(val)] encountered a thrown error: \(error.description)")
            }
        }
        
        // return result as a pairDelim delimited array of key-value tuples transformed already into string
        // Example: "myKey=my%20Val%20Escaped&myKey2=myVal2&..."
        return results.joined(separator: pairDelim);
    }
}

extension Vapor.Request.RedirectEncoding {
    
    func encode(urlQuery:String?)->String? {
        guard let urlQuery = urlQuery else {
            return nil
        }
        
        var result = urlQuery
        switch self {
        case .normal: return urlQuery
        case .base64:
            result = "\(AppConstants.BASE_64_PARAM_KEY)=\(urlQuery.toBase64())"
        case .protobuf:
            dlog?.warning("IMPLEMENT PROTOBUF!")
            result = "\(AppConstants.PROTOBUF_PARAM_KEY)=\(urlQuery.toProtobuf())"
        }
        
        return result;
        
//        let isShouldConv2Base64 = hadBase64 || toBase64
//        if (Debug.IS_DEBUG) {
//            // dlog?.info("\(logPrefix) will be Base64: \(hadBase64 || toBase64) result: \(path)?\(urlQuery)")
//        }
//
//        // If we had a base64 hiding some params, we will encode all params in a base64 wrapper:
//        if isShouldConv2Base64 {
//            urlQuery = "\(AppConstants.BASE_64_PARAM_KEY)=\(urlQuery.toBase64())"
//            let len = min(urlQuery.count - 1, 12) // last 12 chars
//            urlQuery = urlQuery.replacingOccurrences(of: "=",
//                                                     with: "%3D",
//                                                     options: [.backwards, .anchored, .caseInsensitive],
//                                                     range: urlQuery.range(from: NSRange(location:urlQuery.count - len, length:len)))
//        }
    }
    
}
