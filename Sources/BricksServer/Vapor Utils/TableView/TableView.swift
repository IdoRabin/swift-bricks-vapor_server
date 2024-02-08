//
//  TableView.swift
//
//
//  Created by Ido on 18/12/2023.
//

import Foundation
import MNUtils
import MNVaporUtils
import Vapor

class TableView {
    
    func prepParams(title:String, model:any MNModel.Type, allParams:inout [String:Codable], maxRows:Int = 40) async throws {
        allParams["table_title"] = ""
        allParams["table_subtitle"] = ""
        
        allParams["col_titles"] = ["One", "Two", "Three"]
    }
}
