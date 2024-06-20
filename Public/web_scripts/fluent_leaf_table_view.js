// fluent_leaf_table_view.js

// MARK: table live data loaded from json:
var table = {};

function loadTableData() {
    table = JSON.parse(docElemById('table_data').textContent);
    docElemById('table_data').innerHTML = "- loaded ✔ -";
    calcRowHeight();
    // console.trace("fl_tableview: loadTableData", table);
}

// MARK: on load events
function calcRowHeight() {
    // window.innerHeight

    // Calc sizes:
    var sizes = {};
    sizes.body_height = docElemById("main-body-wrapper").getBoundingClientRect().height
    sizes.header_height = docElemById("table_header_section").getBoundingClientRect().height
    sizes.row_height = Math.max(20,0, docElemById("sample_row").getBoundingClientRect().height) + 1 /* padding? */;
    table.sizes = sizes;

    // Calc pages:
    table.rows_per_page = Math.max(Math.floor((sizes.body_height - sizes.header_height) / sizes.row_height), 10);
    table.number_of_pages = Math.ceil(table.total_rows_count / table.rows_per_page);
    table.page_index = 0;
}

function insertRowElement(index, prevRowId) {
    // This function should return the inserted element id (row_id)
    console.trace("fl_tableview:   insertRowElement", index, prevRowId);

}

function updatePagination(pageIndex) {
    table.page_index = pageIndex
    console.trace("fl_tableview:   updatePagination. pageindex:", pageIndex);
    docElemById("table_pagination_title").innerHTML = `page ${pageIndex + 1}&thinsp;/&thinsp;${table.number_of_pages}`;
}

function clearPrevTable() {
    console.trace("fl_tableview:   clearPrevTable");

    docElemById("sample_row").style = "visibility:hidden;";
    docElemById("loader_row").style = "visibility:visible;";

    // Delete all previous data rows:
    for (let row_idx = 0; row_idx < table.rows_per_page + 5; row_idx++) {
        var elem = docElemById("data_row_" + row_idx);
        if (elem) {
            elem.remove();
        }
    }
}

function updateToTablePage(pageIndex) {
    console.trace("fl_tableview: updateToTablePage", pageIndex, "/", table.number_of_pages);

    clearPrevTable();
    if (!(pageIndex >=0 && pageIndex < table.number_of_pages)) {
        return
    }

    self.updatePagination(pageIndex);
}

function addRowHandlers() {
    const ignoreCellIds = ["table_footer_cell", "table_loader_cell"];
    var table = docElemById("table-id");
    var rows = table.getElementsByTagName("tr");
    for (i = 0; i < rows.length; i++) {
        var currentRow = table.rows[i];
        var cells = currentRow.getElementsByTagName("td");
        var headerCells = currentRow.getElementsByTagName("th");
        
        for (j = 0; j < (cells.length + headerCells.length); j++) {
            var cellIdx = j;
            var currentCell = table.rows[i].cells[cellIdx];
            var cellId = currentCell.getAttribute("id");
            if (cellId != undefined && ignoreCellIds.includes(cellId)) {
                console.trace(`skipping cell id "${cellId}" for onClick.`);
            } else {
                // Set onclivk event
                currentCell.onclick = function(e) {
                    var tgt = e.target;
                    var row = tgt.getAttribute("row_index");
                    if (tgt.getAttribute("col_index") == undefined) {
                        var rowTgt = tgt.parentElement.parentElement;
                        var ccells = rowTgt.getElementsByTagName("td");
                        var cellObjects = [];
                        for (m = 0; m < (ccells.length); m++) {
                            var cell = ccells[m];
                            cellObjects.push({
                                "row":row,
                                "col":cell.getAttribute("col_index"),
                                "value":cell.getAttribute("value"),
                                "text":cell.innerHTML,
                                "element": cell
                            });
                        }
                        var targetObj = {
                            "row":row,
                            "cells": cellObjects,
                            "element": rowTgt
                        };
                        console.trace("fl_tableview: clicked row: ", targetObj);
                        // TODO: Broadcast event
                    } else {
                        var targetObj = {
                            "row":row,
                            "col":tgt.getAttribute("col_index"),
                            "value":tgt.getAttribute("value"),
                            "text":tgt.innerHTML,
                            "element": tgt
                        };
                        console.trace("fl_tableview: clicked cell: ", targetObj);
                        // TODO: Broadcast event
                    }
                }
            }
        }
    }
}


function onLoadActivities(e) {
    // console.trace("fl_tableview: onLoadActivities");
    loadTableData();
    updateToTablePage(0);
    addRowHandlers();
}

function onLoadCheck(e) {
    var master_script = document.getElementById("master_js");
    if (window.is_masterJSLoaded == true) {
        // console.trace("fl_tableview: master_js loaded");
        onLoadActivities();
    } else {
        console.warn("fl_tableview: master_js not loaded yet!");
        master_script.addEventListener("load", function(event) {
            console.log("fl_tableview: master_js loaded!)");
            // onjqloaded(); // in fact, yourstuffscript() function
        });
    }
}

window.addEventListener("load", onLoadCheck());