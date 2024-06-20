//
//  FluentLeafTableview+Mock.swift
//
//
//  Created by Ido on 17/02/2024.
//

import Foundation
import Vapor
import Fluent

extension FluentLeafTableview {
    static func debugMock()->FluentLeafTableview? {
        guard Debug.IS_DEBUG else {
            return nil
        }
        
        let config = FluentLeafTableview.Config.default(dbTableName: "[Mock DB table]")
        let result = FluentLeafTableview(title: "Mock table", subtitle: "Mock data table view subtitle here", config: config)
        result.col_titles = [
            .init(item_id: "col_id_1", text: "col_1_ttl", property_name: "col_1_prop"),
            .init(item_id: "col_id_2", text: "col_2_ttl", property_name: "col_2_prop"),
            .init(item_id: "col_id_3", text: "col_3_ttl", property_name: "col_3_prop"),
        ]
        
        var rows : [Row] = []
        var page_idx = 0
        let totalRowCnt = 72
        for row_idx in 0..<totalRowCnt {
            let rid = "r\((row_idx + 1).asString(minDigits: 2))"
            var cells : [Cell] = []
            for col_idx in 0...2 {
                let cid = "c\((col_idx + 1).asString(minDigits: 2))"
                var txt = "tx \(cid)_\(rid) tx"
                cells.append(.init(item_id: "item_id_\(rid)_\(cid)", property_name: "prop_\(rid)_\(cid)", value: "val_\(rid)_\(cid)", text: txt))
            }
            rows.append(.init(item_id: rid, cells: cells))
            cells.removeAll()
        }
        
        result.rows = rows
        result.total_rows_count = UInt(totalRowCnt)
        result.finalize()
        return result
    }
}
