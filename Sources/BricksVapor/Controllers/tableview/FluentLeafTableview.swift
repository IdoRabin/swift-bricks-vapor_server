//
//  FluentLeafTableview.swift
//
//
//  Created by Ido on 17/02/2024.
//

import Foundation
import MNUtils
import Vapor
import Fluent
import Logging

fileprivate let dlog : Logger? = Logger(label:"FluentLeafTableview")

fileprivate protocol FluentLeafTableviewDebugTitled {
    var debugTitle : String { get }
}
fileprivate typealias FLTVDebugTtl = FluentLeafTableviewDebugTitled

public class FluentLeafTableview : JSONSerializable {
    
    static let ACTIONS_KEY_STR = "_actions_"
    
    public struct Cell : JSONSerializable, FLTVDebugTtl {
        typealias Operations = FluentLeafTableview.Operations
        
        var row_index : Int = -1
        var col_index : Int = -1
        let item_id : String
        let property_name : String // FieldKey?
        
        let value : String
        let text : String
        let url : URL?
        let icon : String?
        let operations : Operations
        
        func updatingIndexes(rowIndex:Int, colIndex:Int)->Cell {
            var result = self
            result.row_index = rowIndex
            result.col_index = colIndex
            return result
        }
        
        init(item_id: String, property_name: String, value: String, text: String, url:URL? = nil, icon:String? = nil, operations:Operations = []) {
            // self.row_index = row_index
            // self.col_index = col_index
            self.item_id = item_id
            self.property_name = property_name
            self.value = value
            self.text = text
            self.icon = icon
            self.url = url
            self.operations = operations
        }
        
        // MARK: FluentLeafTableviewDebugTitled
        var debugTitle : String {
            return self.text.asOptional ?? self.item_id
        }
    }
    
    public struct Row : JSONSerializable, FLTVDebugTtl {
        typealias Operations = FluentLeafTableview.Operations
        
        var row_index : Int = -1
        var item_id : String
        var cells : [Cell]
        var operations : Operations
        
        func updatingRowIndex(_ index:Int)->Row {
            var result = self
            result.row_index = index
            return result
        }
        
        func updatingColIndexes()->Row {
            var result = self
            var colIndex = 0
            
            let newCells = self.cells.map({ cell in
                let result = cell.updatingIndexes(rowIndex: self.row_index, colIndex: colIndex)
                colIndex += 1
                return result
            })
            
            result.cells = newCells
            
            return result
        }
        
        func appendingOperations(config:Config)->Row {
            var result = self
            
            let rowIndex = self.row_index
            var colIndex = max(result.cells.count, 0)
            var newCells = result.cells
            
            if !config.perRowOperations.isEmpty {
                
                // Union all operations
                result.operations = result.operations.union(config.perRowOperations)
                
                for elem in config.perRowOperations.elements {
                    // Add cell for each operation
                    let iconCell = Cell(item_id: "_" + elem.key + "_",
                                        property_name: FluentLeafTableview.ACTIONS_KEY_STR,
                                        value: "_" + elem.key + "_",
                                        text: "",
                                        icon: elem.bootstrapIconTag,
                                        operations: elem)
                        .updatingIndexes(rowIndex: rowIndex, 
                                         colIndex: colIndex)
                    newCells.append(iconCell)
                    colIndex += 1
                }
            }
            
            result.cells = newCells
            
            return result
        }
        
        init(item_id: String, cells: [Cell], operations:Operations = []) {
            // self.row_index = row_index
            self.item_id = item_id
            self.cells = cells
            self.operations = operations
        }
        
        // MARK: FluentLeafTableviewDebugTitled
        var debugTitle : String {
            return "row#\(self.row_index.asString(minDigits: 2))| " + self.item_id
        }
    }
    
    public struct ColTitle : JSONSerializable, FLTVDebugTtl {
        var col_index : Int = -1
        var item_id : String
        let text : String
        let property_name : String
        let icon : String?
        
        func updatingColIndex(_ index:Int)->ColTitle {
            var result = self
            result.col_index = index
            return result
        }
        
        init(item_id: String, text: String, property_name: String, icon : String? = nil) {
            // self.col_index = col_index
            self.item_id = item_id
            self.text = text
            self.property_name = property_name
            self.icon = icon
        }
        
        // MARK: FluentLeafTableviewDebugTitled
        var debugTitle : String {
            return self.text.asOptional ?? self.item_id
        }
    }
    
    
    // Properties for the while table:
    public var title : String = ""
    public var subtitle : String? = nil
    public var col_titles : [ColTitle] = []
    public var rows : [Row] = []
    public var starting_row_index : UInt = 0
    public var total_rows_count : UInt = 0
    public var brand_name : String = AppConstants.APP_DISPLAY_NAME
    public var globalOperations : Operations = []
    public var json : String = ""
    let config : Config
    
    public init(title:String, subtitle:String?, config : Config) {
        self.title = title
        self.subtitle = subtitle
        self.config = config
        self.rows = []
    }
    
    public func finalize() {
        
        // Add row operations as header title/s
        if !self.config.perRowOperations.isEmpty {
            for elem in self.config.perRowOperations.elements {
                self.col_titles.append(.init(item_id: "_" + elem.key + "_",
                                             text: "",
                                             property_name: Self.ACTIONS_KEY_STR,
                                             icon: Operations.actions.bootstrapIconTag))
            }
        }
        
        // Update col_titles indexes
        var colIndex = 0
        self.col_titles = self.col_titles.map({ colTitle in
            let result = colTitle.updatingColIndex(colIndex)
            colIndex += 1
            return result
        })
        
        // Update rows indexes
        var rowIndex = 0
        let newRows = rows.map({ row in
            let result = row.updatingRowIndex(rowIndex)
                .updatingColIndexes() // make sure coloums are indexed correctly
                .appendingOperations(config: self.config) // Add row operation / icons for each row
            rowIndex += 1
            return result
        })
        rows = newRows
        self.total_rows_count = UInt(rowIndex + 1)
        
        self.json = self.serializeToJsonString(prettyPrint: Debug.IS_DEBUG) ?? ""
        
        // TODO: Remove this when needed
        self.debugLog()
    }
    
    public func debugLog() {
        guard Debug.IS_DEBUG else {
            return
        }
        enum Step {
            case measure
            case log
        }
        
        dlog?.info("Finalized tableview: '\(self.title)' \(self.total_rows_count) rows.")
        dlog?.info("  :: dbTableName: '\(self.config.dbTableName)'")
        
        var colSze : [Int:Int] = [:]
        let padAdd = 2
        for step in [Step.measure, Step.log] {
            
            // 1. Title / headers
            var rowStrs : [String] = []
            for ttl in self.col_titles {
                let str = ttl.debugTitle
                switch step {
                case .measure:
                    colSze[ttl.col_index] = str.count + padAdd
                case .log:
                    rowStrs.append(str.paddingCentered(toLength: colSze[ttl.col_index] ?? 6, withPad: " "))
                }
            }
            if case .log = step {
                dlog?.info("  ::header titles:: \(rowStrs.joined(separator: " | "))")
            }
            
            // 2. Rows and columns
            for row in rows {
                rowStrs.removeAll()
                for cell in row.cells {
                    let str = cell.debugTitle
                    switch step {
                    case .measure:
                        colSze[cell.col_index] = max(colSze[cell.col_index] ?? 0, str.count + padAdd)
                    case .log:
                        rowStrs.append(str.paddingCentered(toLength: colSze[cell.col_index] ?? 6, withPad: " "))
                    }
                }
                if case .log = step {
                    dlog?.info("       :: row \(row.row_index.asString(minDigits: 2)) :: \(rowStrs.joined(separator: " | "))")
                }
            }
        }
    }
}

