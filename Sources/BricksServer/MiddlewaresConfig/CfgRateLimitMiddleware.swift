//
//  CfgRateLimitMiddleware.swift
//  
//
//  Created by Ido on 03/07/2023.
//

import Foundation
import Vapor
import DSLogger
import MNUtils
fileprivate let dlog : DSLogger? = DLog.forClass("CfgRateLimitMiddleware")?.setting(verbose: false)


extension AppConfigurator {
    func configRateLimitMiddleware() {
        guard let app = AppServer.shared.vaporApplication else {
            dlog?.note("failed: vapor app not found!")
            return
        }
        
        // TODO: Add a RateLimitMiddleware to prevent ddos or DB drinking - for examples:
        // HTTPStatus - 429 Too Many Requests (rate limiting)
        // see: https://github.com/devmaximilian/RateLimitMiddleware
        // see: https://github.com/nodes-vapor/gatekeeper
        
        //  ===  CORS handling middleware:  ===
        // Make sure CORSMiddleware is inserted before all your error/abort middlewares, so that even the failed request responses contain proper CORS information. Given that thrown errors are immediately returned to the client, the CORSMiddleware must be listed before the ErrorMiddleware; otherwise the HTTP error response will be returned without CORS headers, and cannot be read by the browser.
        // Allow CORS ONLY for debug builds:
        if (BuildType.currentBuildType == .debug && Debug.IS_DEBUG) {
            /// CORSMiddleware.Configuration
            /// - parameters:
            ///   - allowedOrigin: Setting that controls which origin values are allowed.
            ///   - allowedMethods: Methods that are allowed for a CORS request response.
            ///   - allowedHeaders: Headers that are allowed in a response for CORS request.
            ///   - allowCredentials: If cookies and other credentials will be sent in the response.
            ///   - cacheExpiration: Optionally sets expiration of the cached pre-flight request in seconds.
            ///   - exposedHeaders: Headers exposed in the response of pre-flight request.
            let corsConfiguration = CORSMiddleware.Configuration(
                allowedOrigin: .any(AppConstants.ALLOWED_DEBUG_CORS_URIS),
                allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
                allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin],
                allowCredentials: true
            )
            
            app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
        }
    }
}
