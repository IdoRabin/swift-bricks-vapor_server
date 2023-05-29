//
//  PostgresCellEx.swift
//  
//
//  Created by Ido on 27/06/2022.
//

import Foundation
import Fluent
import FluentKit
import PostgresNIO
import NIOFoundationCompat

extension PostgresCell {
    var stringValue : String? {
        switch self.dataType {
        case .text, .name:
            // Create String from ByteBuffer
            if let bytesCount = self.bytes?.readableBytes, let str = bytes?.getString(at: 0, length: bytesCount, encoding: .utf8) {
                return str
            }
        default: break
        }
        return nil
    }
    
    var dataValue : Data? {
        switch self.format {
        case .binary:
            // Create Data from ByteBuffer
            if let bytesCount = self.bytes?.readableBytes, let data = bytes?.getData(at: 0, length: bytesCount, byteTransferStrategy: .noCopy) {
                return data
            }
        default: break
        }
        return nil
    }
}
