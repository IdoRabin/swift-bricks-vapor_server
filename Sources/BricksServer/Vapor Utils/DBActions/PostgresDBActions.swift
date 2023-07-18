//
//  PostgresDBActionsEx.swift
//  PostgresDBActions
//
//  Created by Ido on 10/08/2022.
//

import Foundation

#if NIO || VAPOR || FLUENT || POSTGRES
import Fluent
import FluentKit
import FluentPostgresDriver
import PostgresNIO

import DSLogger
import MNUtils
fileprivate let dlog : DSLogger? = DLog.forClass("PostgresDBActions")

class PostgresDBActions {
    
}

extension PostgresDBActions : DBActionProvider {

    func shutdown(db: Database) {
        dlog?.info("> PostgresDBActions shutdown: \(db.configuration)")
    }
    
    func dropAllTables(db: Database, ignoreFluentTables : Bool, completion:@escaping (AppResult<String>)->Void) {
        // Query all table names:
        
        self.allTableNamesCompletion(db: db, ignoreFluentTables: ignoreFluentTables) { namesResult in
            switch namesResult {
            case .success(let names):
                
                // Handle all table names:
                if names.count > 0 {
                    
                    // Drop all tables
                    let queryString = """
                    DROP TABLE \(names.joined(separator: ", "));
                    """
                    let query = (db as? PostgresDatabase)?.query(queryString) // drop all tables
                    query?.whenComplete({ result in
                        switch result {
                        case .failure(let error):
                            db.logger.notice("Drop tables failed with error:\(error.localizedDescription)")
                            completion(AppResult<String>.failure(fromError: error))
                        case .success: // (let pgTablesResult):
                            
                            // Drop all migrations records:
                            let queryString2 = """
                            DELETE FROM _fluent_migrations;
                            """
                            let query2 = (db as? PostgresDatabase)?.query(queryString2) // drop all records from "_fluent_migrations"
                            query2?.whenComplete({ result in
                                switch result {
                                case .failure(let error):
                                    db.logger.notice("Drop migration tables failed with error:\(error.localizedDescription)")
                                    completion(AppResult<String>.failure(fromError: error))
                                case .success(let pgMigrationsResult):
                                    db.logger.info("Dropped tables: \(names.descriptionJoined) | migrations: \(pgMigrationsResult.rows.descriptionsJoined)")
                                    completion(.success("Dropped \(names.count) tables: \(names.descriptionJoined) "))
                                }
                            })
                        }
                    })
                } else {
                    completion(.success("No tables to delete (0 table names found)"))
                }
            case .failure(let error):
                if error.appErrorCode() == .some(AppErrorCode.db_empty_result) {
                    completion(AppResult<String>.success("No tables to delete (0 table names found)"))
                } else {
                    completion(AppResult<String>.failure(fromError: error))
                }
                
            }
        }
    }
}

extension PostgresDBActions : DBInfoProvider {
    
    // MARK: private helper funcs
    private func tablenamesQuery(db: Database)->EventLoopFuture<PostgresQueryResult>? {
        let queryString = """
        SELECT table_schema, table_name
          FROM information_schema.tables
         WHERE table_schema='public'
           AND table_type='BASE TABLE'
        """
        let query = (db as? PostgresDatabase)?.query(queryString) // list all table names
        return query
    }
    
    /// handle the result of a get all table names query to the db.
    ///  NOTE: this is a blocking function!
    /// - Parameters:
    ///   - db: database to use
    ///   - queryResult: result of the query
    ///   - ignoreFluentTables: should ignore "internal" fluent tables and only return "user" tables
    /// - Returns: Result with an array of all table names, or an error.
    private func handleTablenamesPostgresQueryResult(db: Database, queryResult:PostgresQueryResult?, ignoreFluentTables:Bool)->AppResult<[String]> {
        var result : [String] = []
        var aerror : AppError? = nil
        let NIL_ERR = "- NIL -"
        
//         do {
            if let postgresResult = queryResult {
                result = postgresResult.compactMap { pgRow in
                    // This allows accessing columns with O(1) instead of O(n) where n is number of rows.
                    let raRow : PostgresRandomAccessRow = pgRow.makeRandomAccess()
                    var tableName = "unknown"
                    
                    guard raRow.contains("table_name") else { //  {
                        return NIL_ERR
                    }
                    
                    let raCell = raRow["table_name"]
                    
                    #if NIO || VAPOR || FLUENT || POSTGRES
                    tableName = raCell.stringValue ?? tableName
                    #endif
                    
                    if ignoreFluentTables && tableName.contains("_fluent") {
                        return NIL_ERR
                    }
                    
                    return tableName
                }.filter({ val in
                    val != NIL_ERR
                })
                
                if result.count == 0 {
                    aerror = AppError(code:.db_empty_result, reason: "asyncExistingTableNames returned 0 table names!")
                }
            } else {
                aerror = AppError(code:.db_failed_migration, reason: "asyncExistingTableNames returned nil!")
            }
//         } catch let error {
//            db.logger.notice("asyncExistingTableNames failed with error:\(error.description)")
//            aerror = AppError(error:error)
//         }
        
        if let aerror = aerror {
            return .failure(aerror)
        }
        return .success(result)
    }
    
    // MARK: DBInfoProvider
    func allTableNames(db: Database, ignoreFluentTables : Bool) ->AppResult<[String]> {
        var result : AppResult<[String]>
        do {
            // NOTE: .wait blocks!
            let res = try tablenamesQuery(db:db)?.wait()
            result = self.handleTablenamesPostgresQueryResult(db: db, queryResult: res, ignoreFluentTables: true)
        } catch let error {
            result = .failure(fromError: error)
        }
        return result
    }
    
    func allTableNamesAsync(db: Database, ignoreFluentTables : Bool) async ->AppResult<[String]> {
        do {
            // NOTE: .wait blocks!
            let queryResult = try await tablenamesQuery(db:db)?.get()
            return self.handleTablenamesPostgresQueryResult(db: db, queryResult: queryResult, ignoreFluentTables: ignoreFluentTables)
        } catch let error {
            return .failure(AppError(code:.db_failed_query, reasons: ["tablenamesQuery returned nil!"], underlyingError: error))
        }
    }
    
    func allTableNamesCompletion(db: Database, ignoreFluentTables : Bool, completion:@escaping (AppResult<[String]>)->Void) {
        // NOTE: .whenComplete does not block!
        tablenamesQuery(db:db)?.whenComplete({[self] queryResult in
            // queryResult : Result<PostgresQueryResult, any Error>
            let result : AppResult<[String]> = self.handleTablenamesPostgresQueryResult(db: db, queryResult: queryResult.successValue /* < is optional */, ignoreFluentTables: true)
            completion(result)
        })
    }
    
}

#endif
