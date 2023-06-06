//
//  HTMLEncodable.swift
//  
//
//  Created by Ido on 17/07/2022.
//

import Vapor

protocol HTMLEncodable : ResponseEncodable {
    var htmlContents : String { get }
}

class HTMLPage : HTMLEncodable {
    
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        
        // Return the request UUID for comparisons w/ log / error logs / dashboards / analytics..
        headers.enrich(with: request) // see  VaporResponseEx
        
        return request.eventLoop.makeSucceededFuture(.init(
            status: .ok, headers: headers, body: Response.Body.init(string: htmlContents)
        ))
    }
    
    var htmlContents : String {
        return ""
    }
}
