/**
 * Compiled inline version. (Library mode)
 */

/*jshint smarttabs:true, undef:true, latedef:true, curly:true, bitwise:true, camelcase:true */
/*globals $code */
define(['bower/tinymce/tinymce'], function(tinymce){
(function(exports, undefined) {
	"use strict";

	var modules = {};

	function require(ids, callback) {
		var module, defs = [];

		for (var i = 0; i < ids.length; ++i) {
			module = modules[ids[i]] || resolve(ids[i]);
			if (!module) {
				throw 'module definition dependecy not found: ' + ids[i];
			}

			defs.push(module);
		}

		callback.apply(null, defs);
	}

	function define(id, dependencies, definition) {
		if (typeof id !== 'string') {
			throw 'invalid module definition, module id must be defined and be a string';
		}

		if (dependencies === undefined) {
			throw 'invalid module definition, dependencies must be specified';
		}

		if (definition === undefined) {
			throw 'invalid module definition, definition function must be specified';
		}

		require(dependencies, function() {
			modules[id] = definition.apply(null, arguments);
		});
	}

	function defined(id) {
		return !!modules[id];
	}

	function resolve(id) {
		var target = exports;
		var fragments = id.split(/[.\/]/);

		for (var fi = 0; fi < fragments.length; ++fi) {
			if (!target[fragments[fi]]) {
				return;
			}

			target = target[fragments[fi]];
		}

		return target;
	}

	function expose(ids) {
		for (var i = 0; i < ids.length; i++) {
			var target = exports;
			var id = ids[i];
			var fragments = id.split(/[.\/]/);

			for (var fi = 0; fi < fragments.length - 1; ++fi) {
				if (target[fragments[fi]] === undefined) {
					target[fragments[fi]] = {};
				}

				target = target[fragments[fi]];
			}

			target[fragments[fragments.length - 1]] = modules[id];
		}
	}

// Included from: js/tinymce/plugins/table/classes/TableGrid.js

/**
 * TableGrid.js
 *
 * Copyright, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://www.tinymce.com/license
 * Contributing: http://www.tinymce.com/contributing
 */

/**
 * This class creates a grid out of a table element. This
 * makes it a whole lot easier to handle complex tables with
 * col/row spans.
 *
 * @class tinymce.tableplugin.TableGrid
 * @private
 */
define("tinymce/tableplugin/TableGrid", [
	"tinymce/util/Tools",
	"tinymce/Env"
], function(Tools, Env) {
	var each = Tools.each;

	function getSpanVal(td, name) {
		return parseInt(td.getAttribute(name) || 1, 10);
	}

	return function(editor, table) {
		var grid, gridWidth, startPos, endPos, selectedCell, selection = editor.selection, dom = selection.dom;

		function buildGrid() {
			var startY = 0;

			grid = [];
			gridWidth = 0;

			each(['thead', 'tbody', 'tfoot'], function(part) {
				var rows = dom.select('> ' + part + ' tr', table);

				each(rows, function(tr, y) {
					y += startY;

					each(dom.select('> td, > th', tr), function(td, x) {
						var x2, y2, rowspan, colspan;

						// Skip over existing cells produced by rowspan
						if (grid[y]) {
							while (grid[y][x]) {
								x++;
							}
						}

						// Get col/rowspan from cell
						rowspan = getSpanVal(td, 'rowspan');
						colspan = getSpanVal(td, 'colspan');

						// Fill out rowspan/colspan right and down
						for (y2 = y; y2 < y + rowspan; y2++) {
							if (!grid[y2]) {
								grid[y2] = [];
							}

							for (x2 = x; x2 < x + colspan; x2++) {
								grid[y2][x2] = {
									part: part,
									real: y2 == y && x2 == x,
									elm: td,
									rowspan: rowspan,
									colspan: colspan
								};
							}
						}

						gridWidth = Math.max(gridWidth, x + 1);
					});
				});

				startY += rows.length;
			});
		}

		function cloneNode(node, children) {
			node = node.cloneNode(children);
			node.removeAttribute('id');

			return node;
		}

		function getCell(x, y) {
			var row;

			row = grid[y];
			if (row) {
				return row[x];
			}
		}

		function setSpanVal(td, name, val) {
			if (td) {
				val = parseInt(val, 10);

				if (val === 1) {
					td.removeAttribute(name, 1);
				} else {
					td.setAttribute(name, val, 1);
				}
			}
		}

		function isCellSelected(cell) {
			return cell && (dom.hasClass(cell.elm, 'mce-item-selected') || cell == selectedCell);
		}

		function getSelectedRows() {
			var rows = [];

			each(table.rows, function(row) {
				each(row.cells, function(cell) {
					if (dom.hasClass(cell, 'mce-item-selected') || (selectedCell && cell == selectedCell.elm)) {
						rows.push(row);
						return false;
					}
				});
			});

			return rows;
		}

		function deleteTable() {
			var rng = dom.createRng();

			rng.setStartAfter(table);
			rng.setEndAfter(table);

			selection.setRng(rng);

			dom.remove(table);
		}

		function cloneCell(cell) {
			var formatNode, cloneFormats = {};

			if (editor.settings.table_clone_elements !== false) {
				cloneFormats = Tools.makeMap(
					(editor.settings.table_clone_elements || 'strong em b i span font h1 h2 h3 h4 h5 h6 p div').toUpperCase(),
					/[ ,]/
				);
			}

			// Clone formats
			Tools.walk(cell, function(node) {
				var curNode;

				if (node.nodeType == 3) {
					each(dom.getParents(node.parentNode, null, cell).reverse(), function(node) {
						if (!cloneFormats[node.nodeName]) {
							return;
						}

						node = cloneNode(node, false);

						if (!formatNode) {
							formatNode = curNode = node;
						} else if (curNode) {
							curNode.appendChild(node);
						}

						curNode = node;
					});

					// Add something to the inner node
					if (curNode) {
						curNode.innerHTML = Env.ie ? '&nbsp;' : '<br data-mce-bogus="1" />';
					}

					return false;
				}
			}, 'childNodes');

			cell = cloneNode(cell, false);
			setSpanVal(cell, 'rowSpan', 1);
			setSpanVal(cell, 'colSpan', 1);

			if (formatNode) {
				cell.appendChild(formatNode);
			} else {
				if (!Env.ie || Env.ie > 10) {
					cell.innerHTML = '<br data-mce-bogus="1" />';
				}
			}

			return cell;
		}

		function cleanup() {
			var rng = dom.createRng(), row;

			// Empty rows
			each(dom.select('tr', table), function(tr) {
				if (tr.cells.length === 0) {
					dom.remove(tr);
				}
			});

			// Empty table
			if (dom.select('tr', table).length === 0) {
				rng.setStartBefore(table);
				rng.setEndBefore(table);
				selection.setRng(rng);
				dom.remove(table);
				return;
			}

			// Empty header/body/footer
			each(dom.select('thead,tbody,tfoot', table), function(part) {
				if (part.rows.length === 0) {
					dom.remove(part);
				}
			});

			// Restore selection to start position if it still exists
			buildGrid();

			// If we have a valid startPos object
			if (startPos) {
				// Restore the selection to the closest table position
				row = grid[Math.min(grid.length - 1, startPos.y)];
				if (row) {
					selection.select(row[Math.min(row.length - 1, startPos.x)].elm, true);
					selection.collapse(true);
				}
			}
		}

		function fillLeftDown(x, y, rows, cols) {
			var tr, x2, r, c, cell;

			tr = grid[y][x].elm.parentNode;
			for (r = 1; r <= rows; r++) {
				tr = dom.getNext(tr, 'tr');

				if (tr) {
					// Loop left to find real cell
					for (x2 = x; x2 >= 0; x2--) {
						cell = grid[y + r][x2].elm;

						if (cell.parentNode == tr) {
							// Append clones after
							for (c = 1; c <= cols; c++) {
								dom.insertAfter(cloneCell(cell), cell);
							}

							break;
						}
					}

					if (x2 == -1) {
						// Insert nodes before first cell
						for (c = 1; c <= cols; c++) {
							tr.insertBefore(cloneCell(tr.cells[0]), tr.cells[0]);
						}
					}
				}
			}
		}

		function split() {
			each(grid, function(row, y) {
				each(row, function(cell, x) {
					var colSpan, rowSpan, i;

					if (isCellSelected(cell)) {
						cell = cell.elm;
						colSpan = getSpanVal(cell, 'colspan');
						rowSpan = getSpanVal(cell, 'rowspan');

						if (colSpan > 1 || rowSpan > 1) {
							setSpanVal(cell, 'rowSpan', 1);
							setSpanVal(cell, 'colSpan', 1);

							// Insert cells right
							for (i = 0; i < colSpan - 1; i++) {
								dom.insertAfter(cloneCell(cell), cell);
							}

							fillLeftDown(x, y, rowSpan - 1, colSpan);
						}
					}
				});
			});
		}

		function merge(cell, cols, rows) {
			var pos, startX, startY, endX, endY, x, y, startCell, endCell, children, count;

			// Use specified cell and cols/rows
			if (cell) {
				pos = getPos(cell);
				startX = pos.x;
				startY = pos.y;
				endX = startX + (cols - 1);
				endY = startY + (rows - 1);
			} else {
				startPos = endPos = null;

				// Calculate start/end pos by checking for selected cells in grid works better with context menu
				each(grid, function(row, y) {
					each(row, function(cell, x) {
						if (isCellSelected(cell)) {
							if (!startPos) {
								startPos = {x: x, y: y};
							}

							endPos = {x: x, y: y};
						}
					});
				});

				// Use selection, but make sure startPos is valid before accessing
				if (startPos) {
					startX = startPos.x;
					startY = startPos.y;
					endX = endPos.x;
					endY = endPos.y;
				}
			}

			// Find start/end cells
			startCell = getCell(startX, startY);
			endCell = getCell(endX, endY);

			// Check if the cells exists and if they are of the same part for example tbody = tbody
			if (startCell && endCell && startCell.part == endCell.part) {
				// Split and rebuild grid
				split();
				buildGrid();

				// Set row/col span to start cell
				startCell = getCell(startX, startY).elm;
				setSpanVal(startCell, 'colSpan', (endX - startX) + 1);
				setSpanVal(startCell, 'rowSpan', (endY - startY) + 1);

				// Remove other cells and add it's contents to the start cell
				for (y = startY; y <= endY; y++) {
					for (x = startX; x <= endX; x++) {
						if (!grid[y] || !grid[y][x]) {
							continue;
						}

						cell = grid[y][x].elm;

						/*jshint loopfunc:true */
						/*eslint no-loop-func:0 */
						if (cell != startCell) {
							// Move children to startCell
							children = Tools.grep(cell.childNodes);
							each(children, function(node) {
								startCell.appendChild(node);
							});

							// Remove bogus nodes if there is children in the target cell
							if (children.length) {
								children = Tools.grep(startCell.childNodes);
								count = 0;
								each(children, function(node) {
									if (node.nodeName == 'BR' && dom.getAttrib(node, 'data-mce-bogus') && count++ < children.length - 1) {
										startCell.removeChild(node);
									}
								});
							}

							dom.remove(cell);
						}
					}
				}

				// Remove empty rows etc and restore caret location
				cleanup();
			}
		}

		function insertRow(before) {
			var posY, cell, lastCell, x, rowElm, newRow, newCell, otherCell, rowSpan;

			// Find first/last row
			each(grid, function(row, y) {
				each(row, function(cell) {
					if (isCellSelected(cell)) {
						cell = cell.elm;
						rowElm = cell.parentNode;
						newRow = cloneNode(rowElm, false);
						posY = y;

						if (before) {
							return false;
						}
					}
				});

				if (before) {
					return !posY;
				}
			});

			// If posY is undefined there is nothing for us to do here...just return to avoid crashing below
			if (posY === undefined) {
				return;
			}

			for (x = 0; x < grid[0].length; x++) {
				// Cell not found could be because of an invalid table structure
				if (!grid[posY][x]) {
					continue;
				}

				cell = grid[posY][x].elm;

				if (cell != lastCell) {
					if (!before) {
						rowSpan = getSpanVal(cell, 'rowspan');
						if (rowSpan > 1) {
							setSpanVal(cell, 'rowSpan', rowSpan + 1);
							continue;
						}
					} else {
						// Check if cell above can be expanded
						if (posY > 0 && grid[posY - 1][x]) {
							otherCell = grid[posY - 1][x].elm;
							rowSpan = getSpanVal(otherCell, 'rowSpan');
							if (rowSpan > 1) {
								setSpanVal(otherCell, 'rowSpan', rowSpan + 1);
								continue;
							}
						}
					}

					// Insert new cell into new row
					newCell = cloneCell(cell);
					setSpanVal(newCell, 'colSpan', cell.colSpan);

					newRow.appendChild(newCell);

					lastCell = cell;
				}
			}

			if (newRow.hasChildNodes()) {
				if (!before) {
					dom.insertAfter(newRow, rowElm);
				} else {
					rowElm.parentNode.insertBefore(newRow, rowElm);
				}
			}
		}

		function insertCol(before) {
			var posX, lastCell;

			// Find first/last column
			each(grid, function(row) {
				each(row, function(cell, x) {
					if (isCellSelected(cell)) {
						posX = x;

						if (before) {
							return false;
						}
					}
				});

				if (before) {
					return !posX;
				}
			});

			each(grid, function(row, y) {
				var cell, rowSpan, colSpan;

				if (!row[posX]) {
					return;
				}

				cell = row[posX].elm;
				if (cell != lastCell) {
					colSpan = getSpanVal(cell, 'colspan');
					rowSpan = getSpanVal(cell, 'rowspan');

					if (colSpan == 1) {
						if (!before) {
							dom.insertAfter(cloneCell(cell), cell);
							fillLeftDown(posX, y, rowSpan - 1, colSpan);
						} else {
							cell.parentNode.insertBefore(cloneCell(cell), cell);
							fillLeftDown(posX, y, rowSpan - 1, colSpan);
						}
					} else {
						setSpanVal(cell, 'colSpan', cell.colSpan + 1);
					}

					lastCell = cell;
				}
			});
		}

		function deleteCols() {
			var cols = [];

			// Get selected column indexes
			each(grid, function(row) {
				each(row, function(cell, x) {
					if (isCellSelected(cell) && Tools.inArray(cols, x) === -1) {
						each(grid, function(row) {
							var cell = row[x].elm, colSpan;

							colSpan = getSpanVal(cell, 'colSpan');

							if (colSpan > 1) {
								setSpanVal(cell, 'colSpan', colSpan - 1);
							} else {
								dom.remove(cell);
							}
						});

						cols.push(x);
					}
				});
			});

			cleanup();
		}

		function deleteRows() {
			var rows;

			function deleteRow(tr) {
				var pos, lastCell;

				// Move down row spanned cells
				each(tr.cells, function(cell) {
					var rowSpan = getSpanVal(cell, 'rowSpan');

					if (rowSpan > 1) {
						setSpanVal(cell, 'rowSpan', rowSpan - 1);
						pos = getPos(cell);
						fillLeftDown(pos.x, pos.y, 1, 1);
					}
				});

				// Delete cells
				pos = getPos(tr.cells[0]);
				each(grid[pos.y], function(cell) {
					var rowSpan;

					cell = cell.elm;

					if (cell != lastCell) {
						rowSpan = getSpanVal(cell, 'rowSpan');

						if (rowSpan <= 1) {
							dom.remove(cell);
						} else {
							setSpanVal(cell, 'rowSpan', rowSpan - 1);
						}

						lastCell = cell;
					}
				});
			}

			// Get selected rows and move selection out of scope
			rows = getSelectedRows();

			// Delete all selected rows
			each(rows.reverse(), function(tr) {
				deleteRow(tr);
			});

			cleanup();
		}

		function cutRows() {
			var rows = getSelectedRows();

			dom.remove(rows);
			cleanup();

			return rows;
		}

		function copyRows() {
			var rows = getSelectedRows();

			each(rows, function(row, i) {
				rows[i] = cloneNode(row, true);
			});

			return rows;
		}

		function pasteRows(rows, before) {
			var selectedRows = getSelectedRows(),
				targetRow = selectedRows[before ? 0 : selectedRows.length - 1],
				targetCellCount = targetRow.cells.length;

			// Nothing to paste
			if (!rows) {
				return;
			}

			// Calc target cell count
			each(grid, function(row) {
				var match;

				targetCellCount = 0;
				each(row, function(cell) {
					if (cell.real) {
						targetCellCount += cell.colspan;
					}

					if (cell.elm.parentNode == targetRow) {
						match = 1;
					}
				});

				if (match) {
					return false;
				}
			});

			if (!before) {
				rows.reverse();
			}

			each(rows, function(row) {
				var i, cellCount = row.cells.length, cell;

				// Remove col/rowspans
				for (i = 0; i < cellCount; i++) {
					cell = row.cells[i];
					setSpanVal(cell, 'colSpan', 1);
					setSpanVal(cell, 'rowSpan', 1);
				}

				// Needs more cells
				for (i = cellCount; i < targetCellCount; i++) {
					row.appendChild(cloneCell(row.cells[cellCount - 1]));
				}

				// Needs less cells
				for (i = targetCellCount; i < cellCount; i++) {
					dom.remove(row.cells[i]);
				}

				// Add before/after
				if (before) {
					targetRow.parentNode.insertBefore(row, targetRow);
				} else {
					dom.insertAfter(row, targetRow);
				}
			});

			// Remove current selection
			dom.removeClass(dom.select('td.mce-item-selected,th.mce-item-selected'), 'mce-item-selected');
		}

		function getPos(target) {
			var pos;

			each(grid, function(row, y) {
				each(row, function(cell, x) {
					if (cell.elm == target) {
						pos = {x : x, y : y};
						return false;
					}
				});

				return !pos;
			});

			return pos;
		}

		function setStartCell(cell) {
			startPos = getPos(cell);
		}

		function findEndPos() {
			var maxX, maxY;

			maxX = maxY = 0;

			each(grid, function(row, y) {
				each(row, function(cell, x) {
					var colSpan, rowSpan;

					if (isCellSelected(cell)) {
						cell = grid[y][x];

						if (x > maxX) {
							maxX = x;
						}

						if (y > maxY) {
							maxY = y;
						}

						if (cell.real) {
							colSpan = cell.colspan - 1;
							rowSpan = cell.rowspan - 1;

							if (colSpan) {
								if (x + colSpan > maxX) {
									maxX = x + colSpan;
								}
							}

							if (rowSpan) {
								if (y + rowSpan > maxY) {
									maxY = y + rowSpan;
								}
							}
						}
					}
				});
			});

			return {x : maxX, y : maxY};
		}

		function setEndCell(cell) {
			var startX, startY, endX, endY, maxX, maxY, colSpan, rowSpan, x, y;

			endPos = getPos(cell);

			if (startPos && endPos) {
				// Get start/end positions
				startX = Math.min(startPos.x, endPos.x);
				startY = Math.min(startPos.y, endPos.y);
				endX = Math.max(startPos.x, endPos.x);
				endY = Math.max(startPos.y, endPos.y);

				// Expand end positon to include spans
				maxX = endX;
				maxY = endY;

				// Expand startX
				for (y = startY; y <= maxY; y++) {
					cell = grid[y][startX];

					if (!cell.real) {
						if (startX - (cell.colspan - 1) < startX) {
							startX -= cell.colspan - 1;
						}
					}
				}

				// Expand startY
				for (x = startX; x <= maxX; x++) {
					cell = grid[startY][x];

					if (!cell.real) {
						if (startY - (cell.rowspan - 1) < startY) {
							startY -= cell.rowspan - 1;
						}
					}
				}

				// Find max X, Y
				for (y = startY; y <= endY; y++) {
					for (x = startX; x <= endX; x++) {
						cell = grid[y][x];

						if (cell.real) {
							colSpan = cell.colspan - 1;
							rowSpan = cell.rowspan - 1;

							if (colSpan) {
								if (x + colSpan > maxX) {
									maxX = x + colSpan;
								}
							}

							if (rowSpan) {
								if (y + rowSpan > maxY) {
									maxY = y + rowSpan;
								}
							}
						}
					}
				}

				// Remove current selection
				dom.removeClass(dom.select('td.mce-item-selected,th.mce-item-selected'), 'mce-item-selected');

				// Add new selection
				for (y = startY; y <= maxY; y++) {
					for (x = startX; x <= maxX; x++) {
						if (grid[y][x]) {
							dom.addClass(grid[y][x].elm, 'mce-item-selected');
						}
					}
				}
			}
		}

		function moveRelIdx(cellElm, delta) {
			var pos, index, cell;

			pos = getPos(cellElm);
			index = pos.y * gridWidth + pos.x;

			do {
				index += delta;
				cell = getCell(index % gridWidth, Math.floor(index / gridWidth));

				if (!cell) {
					break;
				}

				if (cell.elm != cellElm) {
					selection.select(cell.elm, true);

					if (dom.isEmpty(cell.elm)) {
						selection.collapse(true);
					}

					return true;
				}
			} while (cell.elm == cellElm);

			return false;
		}

		table = table || dom.getParent(selection.getStart(), 'table');

		buildGrid();

		selectedCell = dom.getParent(selection.getStart(), 'th,td');
		if (selectedCell) {
			startPos = getPos(selectedCell);
			endPos = findEndPos();
			selectedCell = getCell(startPos.x, startPos.y);
		}

		Tools.extend(this, {
			deleteTable: deleteTable,
			split: split,
			merge: merge,
			insertRow: insertRow,
			insertCol: insertCol,
			deleteCols: deleteCols,
			deleteRows: deleteRows,
			cutRows: cutRows,
			copyRows: copyRows,
			pasteRows: pasteRows,
			getPos: getPos,
			setStartCell: setStartCell,
			setEndCell: setEndCell,
			moveRelIdx: moveRelIdx,
			refresh: buildGrid
		});
	};
});

// Included from: js/tinymce/plugins/table/classes/Quirks.js

/**
 * Quirks.js
 *
 * Copyright, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://www.tinymce.com/license
 * Contributing: http://www.tinymce.com/contributing
 */

/**
 * This class includes fixes for various browser quirks.
 *
 * @class tinymce.tableplugin.Quirks
 * @private
 */
define("tinymce/tableplugin/Quirks", [
	"tinymce/util/VK",
	"tinymce/Env",
	"tinymce/util/Tools"
], function(VK, Env, Tools) {
	var each = Tools.each;

	function getSpanVal(td, name) {
		return parseInt(td.getAttribute(name) || 1, 10);
	}

	return function(editor) {
		/**
		 * Fixed caret movement around tables on WebKit.
		 */
		function moveWebKitSelection() {
			function eventHandler(e) {
				var key = e.keyCode;

				function handle(upBool, sourceNode) {
					var siblingDirection = upBool ? 'previousSibling' : 'nextSibling';
					var currentRow = editor.dom.getParent(sourceNode, 'tr');
					var siblingRow = currentRow[siblingDirection];

					if (siblingRow) {
						moveCursorToRow(editor, sourceNode, siblingRow, upBool);
						e.preventDefault();
						return true;
					} else {
						var tableNode = editor.dom.getParent(currentRow, 'table');
						var middleNode = currentRow.parentNode;
						var parentNodeName = middleNode.nodeName.toLowerCase();
						if (parentNodeName === 'tbody' || parentNodeName === (upBool ? 'tfoot' : 'thead')) {
							var targetParent = getTargetParent(upBool, tableNode, middleNode, 'tbody');
							if (targetParent !== null) {
								return moveToRowInTarget(upBool, targetParent, sourceNode);
							}
						}
						return escapeTable(upBool, currentRow, siblingDirection, tableNode);
					}
				}

				function getTargetParent(upBool, topNode, secondNode, nodeName) {
					var tbodies = editor.dom.select('>' + nodeName, topNode);
					var position = tbodies.indexOf(secondNode);
					if (upBool && position === 0 || !upBool && position === tbodies.length - 1) {
						return getFirstHeadOrFoot(upBool, topNode);
					} else if (position === -1) {
						var topOrBottom = secondNode.tagName.toLowerCase() === 'thead' ? 0 : tbodies.length - 1;
						return tbodies[topOrBottom];
					} else {
						return tbodies[position + (upBool ? -1 : 1)];
					}
				}

				function getFirstHeadOrFoot(upBool, parent) {
					var tagName = upBool ? 'thead' : 'tfoot';
					var headOrFoot = editor.dom.select('>' + tagName, parent);
					return headOrFoot.length !== 0 ? headOrFoot[0] : null;
				}

				function moveToRowInTarget(upBool, targetParent, sourceNode) {
					var targetRow = getChildForDirection(targetParent, upBool);

					if (targetRow) {
						moveCursorToRow(editor, sourceNode, targetRow, upBool);
					}

					e.preventDefault();
					return true;
				}

				function escapeTable(upBool, currentRow, siblingDirection, table) {
					var tableSibling = table[siblingDirection];

					if (tableSibling) {
						moveCursorToStartOfElement(tableSibling);
						return true;
					} else {
						var parentCell = editor.dom.getParent(table, 'td,th');
						if (parentCell) {
							return handle(upBool, parentCell, e);
						} else {
							var backUpSibling = getChildForDirection(currentRow, !upBool);
							moveCursorToStartOfElement(backUpSibling);
							e.preventDefault();
							return false;
						}
					}
				}

				function getChildForDirection(parent, up) {
					var child =  parent && parent[up ? 'lastChild' : 'firstChild'];
					// BR is not a valid table child to return in this case we return the table cell
					return child && child.nodeName === 'BR' ? editor.dom.getParent(child, 'td,th') : child;
				}

				function moveCursorToStartOfElement(n) {
					editor.selection.setCursorLocation(n, 0);
				}

				function isVerticalMovement() {
					return key == VK.UP || key == VK.DOWN;
				}

				function isInTable(editor) {
					var node = editor.selection.getNode();
					var currentRow = editor.dom.getParent(node, 'tr');
					return currentRow !== null;
				}

				function columnIndex(column) {
					var colIndex = 0;
					var c = column;
					while (c.previousSibling) {
						c = c.previousSibling;
						colIndex = colIndex + getSpanVal(c, "colspan");
					}
					return colIndex;
				}

				function findColumn(rowElement, columnIndex) {
					var c = 0, r = 0;

					each(rowElement.children, function(cell, i) {
						c = c + getSpanVal(cell, "colspan");
						r = i;
						if (c > columnIndex) {
							return false;
						}
					});
					return r;
				}

				function moveCursorToRow(ed, node, row, upBool) {
					var srcColumnIndex = columnIndex(editor.dom.getParent(node, 'td,th'));
					var tgtColumnIndex = findColumn(row, srcColumnIndex);
					var tgtNode = row.childNodes[tgtColumnIndex];
					var rowCellTarget = getChildForDirection(tgtNode, upBool);
					moveCursorToStartOfElement(rowCellTarget || tgtNode);
				}

				function shouldFixCaret(preBrowserNode) {
					var newNode = editor.selection.getNode();
					var newParent = editor.dom.getParent(newNode, 'td,th');
					var oldParent = editor.dom.getParent(preBrowserNode, 'td,th');

					return newParent && newParent !== oldParent && checkSameParentTable(newParent, oldParent);
				}

				function checkSameParentTable(nodeOne, NodeTwo) {
					return editor.dom.getParent(nodeOne, 'TABLE') === editor.dom.getParent(NodeTwo, 'TABLE');
				}

				if (isVerticalMovement() && isInTable(editor)) {
					var preBrowserNode = editor.selection.getNode();
					setTimeout(function() {
						if (shouldFixCaret(preBrowserNode)) {
							handle(!e.shiftKey && key === VK.UP, preBrowserNode, e);
						}
					}, 0);
				}
			}

			editor.on('KeyDown', function(e) {
				eventHandler(e);
			});
		}

		function fixBeforeTableCaretBug() {
			// Checks if the selection/caret is at the start of the specified block element
			function isAtStart(rng, par) {
				var doc = par.ownerDocument, rng2 = doc.createRange(), elm;

				rng2.setStartBefore(par);
				rng2.setEnd(rng.endContainer, rng.endOffset);

				elm = doc.createElement('body');
				elm.appendChild(rng2.cloneContents());

				// Check for text characters of other elements that should be treated as content
				return elm.innerHTML.replace(/<(br|img|object|embed|input|textarea)[^>]*>/gi, '-').replace(/<[^>]+>/g, '').length === 0;
			}

			// Fixes an bug where it's impossible to place the caret before a table in Gecko
			// this fix solves it by detecting when the caret is at the beginning of such a table
			// and then manually moves the caret infront of the table
			editor.on('KeyDown', function(e) {
				var rng, table, dom = editor.dom;

				// On gecko it's not possible to place the caret before a table
				if (e.keyCode == 37 || e.keyCode == 38) {
					rng = editor.selection.getRng();
					table = dom.getParent(rng.startContainer, 'table');

					if (table && editor.getBody().firstChild == table) {
						if (isAtStart(rng, table)) {
							rng = dom.createRng();

							rng.setStartBefore(table);
							rng.setEndBefore(table);

							editor.selection.setRng(rng);

							e.preventDefault();
						}
					}
				}
			});
		}

		// Fixes an issue on Gecko where it's impossible to place the caret behind a table
		// This fix will force a paragraph element after the table but only when the forced_root_block setting is enabled
		function fixTableCaretPos() {
			editor.on('KeyDown SetContent VisualAid', function() {
				var last;

				// Skip empty text nodes from the end
				for (last = editor.getBody().lastChild; last; last = last.previousSibling) {
					if (last.nodeType == 3) {
						if (last.nodeValue.length > 0) {
							break;
						}
					} else if (last.nodeType == 1 && (last.tagName == 'BR' || !last.getAttribute('data-mce-bogus'))) {
						break;
					}
				}

				if (last && last.nodeName == 'TABLE') {
					if (editor.settings.forced_root_block) {
						editor.dom.add(
							editor.getBody(),
							editor.settings.forced_root_block,
							editor.settings.forced_root_block_attrs,
							Env.ie && Env.ie < 11 ? '&nbsp;' : '<br data-mce-bogus="1" />'
						);
					} else {
						editor.dom.add(editor.getBody(), 'br', {'data-mce-bogus': '1'});
					}
				}
			});

			editor.on('PreProcess', function(o) {
				var last = o.node.lastChild;

				if (last && (last.nodeName == "BR" || (last.childNodes.length == 1 &&
					(last.firstChild.nodeName == 'BR' || last.firstChild.nodeValue == '\u00a0'))) &&
					last.previousSibling && last.previousSibling.nodeName == "TABLE") {
					editor.dom.remove(last);
				}
			});
		}

		// this nasty hack is here to work around some WebKit selection bugs.
		function fixTableCellSelection() {
			function tableCellSelected(ed, rng, n, currentCell) {
				// The decision of when a table cell is selected is somewhat involved.  The fact that this code is
				// required is actually a pointer to the root cause of this bug. A cell is selected when the start
				// and end offsets are 0, the start container is a text, and the selection node is either a TR (most cases)
				// or the parent of the table (in the case of the selection containing the last cell of a table).
				var TEXT_NODE = 3, table = ed.dom.getParent(rng.startContainer, 'TABLE');
				var tableParent, allOfCellSelected, tableCellSelection;

				if (table) {
					tableParent = table.parentNode;
				}

				allOfCellSelected = rng.startContainer.nodeType == TEXT_NODE &&
					rng.startOffset === 0 &&
					rng.endOffset === 0 &&
					currentCell &&
					(n.nodeName == "TR" || n == tableParent);

				tableCellSelection = (n.nodeName == "TD" || n.nodeName == "TH") && !currentCell;

				return allOfCellSelected || tableCellSelection;
			}

			function fixSelection() {
				var rng = editor.selection.getRng();
				var n = editor.selection.getNode();
				var currentCell = editor.dom.getParent(rng.startContainer, 'TD,TH');

				if (!tableCellSelected(editor, rng, n, currentCell)) {
					return;
				}

				if (!currentCell) {
					currentCell = n;
				}

				// Get the very last node inside the table cell
				var end = currentCell.lastChild;
				while (end.lastChild) {
					end = end.lastChild;
				}

				// Select the entire table cell. Nothing outside of the table cell should be selected.
				if (end.nodeType == 3) {
					rng.setEnd(end, end.data.length);
					editor.selection.setRng(rng);
				}
			}

			editor.on('KeyDown', function() {
				fixSelection();
			});

			editor.on('MouseDown', function(e) {
				if (e.button != 2) {
					fixSelection();
				}
			});
		}

		/**
		 * Delete table if all cells are selected.
		 */
		function deleteTable() {
			editor.on('keydown', function(e) {
				if ((e.keyCode == VK.DELETE || e.keyCode == VK.BACKSPACE) && !e.isDefaultPrevented()) {
					var table = editor.dom.getParent(editor.selection.getStart(), 'table');

					if (table) {
						var cells = editor.dom.select('td,th', table), i = cells.length;
						while (i--) {
							if (!editor.dom.hasClass(cells[i], 'mce-item-selected')) {
								return;
							}
						}

						e.preventDefault();
						editor.execCommand('mceTableDelete');
					}
				}
			});
		}

		deleteTable();

		if (Env.webkit) {
			moveWebKitSelection();
			fixTableCellSelection();
		}

		if (Env.gecko) {
			fixBeforeTableCaretBug();
			fixTableCaretPos();
		}

		if (Env.ie > 10) {
			fixBeforeTableCaretBug();
			fixTableCaretPos();
		}
	};
});

// Included from: js/tinymce/plugins/table/classes/CellSelection.js

/**
 * CellSelection.js
 *
 * Copyright, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://www.tinymce.com/license
 * Contributing: http://www.tinymce.com/contributing
 */

/**
 * This class handles table cell selection by faking it using a css class that gets applied
 * to cells when dragging the mouse from one cell to another.
 *
 * @class tinymce.tableplugin.CellSelection
 * @private
 */
define("tinymce/tableplugin/CellSelection", [
	"tinymce/tableplugin/TableGrid",
	"tinymce/dom/TreeWalker",
	"tinymce/util/Tools"
], function(TableGrid, TreeWalker, Tools) {
	return function(editor) {
		var dom = editor.dom, tableGrid, startCell, startTable, hasCellSelection = true, resizing;

		function clear(force) {
			// Restore selection possibilities
			editor.getBody().style.webkitUserSelect = '';

			if (force || hasCellSelection) {
				editor.dom.removeClass(
					editor.dom.select('td.mce-item-selected,th.mce-item-selected'),
					'mce-item-selected'
				);

				hasCellSelection = false;
			}
		}

		function cellSelectionHandler(e) {
			var sel, table, target = e.target;

			if (resizing) {
				return;
			}

			if (startCell && (tableGrid || target != startCell) && (target.nodeName == 'TD' || target.nodeName == 'TH')) {
				table = dom.getParent(target, 'table');
				if (table == startTable) {
					if (!tableGrid) {
						tableGrid = new TableGrid(editor, table);
						tableGrid.setStartCell(startCell);

						editor.getBody().style.webkitUserSelect = 'none';
					}

					tableGrid.setEndCell(target);
					hasCellSelection = true;
				}

				// Remove current selection
				sel = editor.selection.getSel();

				try {
					if (sel.removeAllRanges) {
						sel.removeAllRanges();
					} else {
						sel.empty();
					}
				} catch (ex) {
					// IE9 might throw errors here
				}

				e.preventDefault();
			}
		}

		// Add cell selection logic
		editor.on('MouseDown', function(e) {
			if (e.button != 2 && !resizing) {
				clear();

				startCell = dom.getParent(e.target, 'td,th');
				startTable = dom.getParent(startCell, 'table');
			}
		});

		editor.on('mouseover', cellSelectionHandler);

		editor.on('remove', function() {
			dom.unbind(editor.getDoc(), 'mouseover', cellSelectionHandler);
		});

		editor.on('MouseUp', function() {
			var rng, sel = editor.selection, selectedCells, walker, node, lastNode;

			function setPoint(node, start) {
				var walker = new TreeWalker(node, node);

				do {
					// Text node
					if (node.nodeType == 3 && Tools.trim(node.nodeValue).length !== 0) {
						if (start) {
							rng.setStart(node, 0);
						} else {
							rng.setEnd(node, node.nodeValue.length);
						}

						return;
					}

					// BR element
					if (node.nodeName == 'BR') {
						if (start) {
							rng.setStartBefore(node);
						} else {
							rng.setEndBefore(node);
						}

						return;
					}
				} while ((node = (start ? walker.next() : walker.prev())));
			}

			// Move selection to startCell
			if (startCell) {
				if (tableGrid) {
					editor.getBody().style.webkitUserSelect = '';
				}

				// Try to expand text selection as much as we can only Gecko supports cell selection
				selectedCells = dom.select('td.mce-item-selected,th.mce-item-selected');
				if (selectedCells.length > 0) {
					rng = dom.createRng();
					node = selectedCells[0];
					rng.setStartBefore(node);
					rng.setEndAfter(node);

					setPoint(node, 1);
					walker = new TreeWalker(node, dom.getParent(selectedCells[0], 'table'));

					do {
						if (node.nodeName == 'TD' || node.nodeName == 'TH') {
							if (!dom.hasClass(node, 'mce-item-selected')) {
								break;
							}

							lastNode = node;
						}
					} while ((node = walker.next()));

					setPoint(lastNode);

					sel.setRng(rng);
				}

				editor.nodeChanged();
				startCell = tableGrid = startTable = null;
			}
		});

		editor.on('KeyUp Drop SetContent', function(e) {
			clear(e.type == 'setcontent');
			startCell = tableGrid = startTable = null;
			resizing = false;
		});

		editor.on('ObjectResizeStart ObjectResized', function(e) {
			resizing = e.type != 'objectresized';
		});

		return {
			clear: clear
		};
	};
});

// Included from: js/tinymce/plugins/table/classes/Dialogs.js

/**
 * Dialogs.js
 *
 * Copyright, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://www.tinymce.com/license
 * Contributing: http://www.tinymce.com/contributing
 */

/**
 * ...
 *
 * @class tinymce.tableplugin.Dialogs
 * @private
 */
define("tinymce/tableplugin/Dialogs", [
	"tinymce/util/Tools",
	"tinymce/Env"
], function(Tools, Env) {
	var each = Tools.each;

	return function(editor) {
		var self = this;

		function createColorPickAction() {
			var colorPickerCallback = editor.settings.color_picker_callback;

			if (colorPickerCallback) {
				return function() {
					var self = this;

					colorPickerCallback.call(
						editor,
						function(value) {
							self.value(value).fire('change');
						},
						self.value()
					);
				};
			}
		}

		function createStyleForm(dom) {
			return {
				title: 'Advanced',
				type: 'form',
				defaults: {
					onchange: function() {
						updateStyle(dom, this.parents().reverse()[0], this.name() == "style");
					}
				},
				items: [
					{
						label: 'Style',
						name: 'style',
						type: 'textbox'
					},

					{
						type: 'form',
						padding: 0,
						formItemDefaults: {
							layout: 'grid',
							alignH: ['start', 'right']
						},
						defaults: {
							size: 7
						},
						items: [
							{
								label: 'Border color',
								type: 'colorbox',
								name: 'borderColor',
								onaction: createColorPickAction()
							},

							{
								label: 'Background color',
								type: 'colorbox',
								name: 'backgroundColor',
								onaction: createColorPickAction()
							}
						]
					}
				]
			};
		}

		function removePxSuffix(size) {
			return size ? size.replace(/px$/, '') : "";
		}

		function addSizeSuffix(size) {
			if (/^[0-9]+$/.test(size)) {
				size += "px";
			}

			return size;
		}

		function unApplyAlign(elm) {
			each('left center right'.split(' '), function(name) {
				editor.formatter.remove('align' + name, {}, elm);
			});
		}

		function unApplyVAlign(elm) {
			each('top middle bottom'.split(' '), function(name) {
				editor.formatter.remove('valign' + name, {}, elm);
			});
		}

		function buildListItems(inputList, itemCallback, startItems) {
			function appendItems(values, output) {
				output = output || [];

				Tools.each(values, function(item) {
					var menuItem = {text: item.text || item.title};

					if (item.menu) {
						menuItem.menu = appendItems(item.menu);
					} else {
						menuItem.value = item.value;

						if (itemCallback) {
							itemCallback(menuItem);
						}
					}

					output.push(menuItem);
				});

				return output;
			}

			return appendItems(inputList, startItems || []);
		}

		function updateStyle(dom, win, isStyleCtrl) {
			var data = win.toJSON();
			var css = dom.parseStyle(data.style);

			if (isStyleCtrl) {
				win.find('#borderColor').value(css["border-color"] || '')[0].fire('change');
				win.find('#backgroundColor').value(css["background-color"] || '')[0].fire('change');
			} else {
				css["border-color"] = data.borderColor;
				css["background-color"] = data.backgroundColor;
			}

			win.find('#style').value(dom.serializeStyle(dom.parseStyle(dom.serializeStyle(css))));
		}

		function appendStylesToData(dom, data, elm) {
			var css = dom.parseStyle(dom.getAttrib(elm, 'style'));

			if (css["border-color"]) {
				data.borderColor = css["border-color"];
			}

			if (css["background-color"]) {
				data.backgroundColor = css["background-color"];
			}

			data.style = dom.serializeStyle(css);
		}

		self.tableProps = function() {
			self.table(true);
		};

		self.table = function(isProps) {
			var dom = editor.dom, tableElm, colsCtrl, rowsCtrl, classListCtrl, data = {}, generalTableForm;

			function onSubmitTableForm() {
				var captionElm;

				updateStyle(dom, this);
				data = Tools.extend(data, this.toJSON());

				Tools.each('backgroundColor borderColor'.split(' '), function(name) {
					delete data[name];
				});

				if (data["class"] === false) {
					delete data["class"];
				}

				editor.undoManager.transact(function() {
					if (!tableElm) {
						tableElm = editor.plugins.table.insertTable(data.cols || 1, data.rows || 1);
					}

					editor.dom.setAttribs(tableElm, {
						cellspacing: data.cellspacing,
						cellpadding: data.cellpadding,
						border: data.border,
						style: data.style,
						'class': data['class']
					});

					if (dom.getAttrib(tableElm, 'width')) {
						dom.setAttrib(tableElm, 'width', removePxSuffix(data.width));
					} else {
						dom.setStyle(tableElm, 'width', addSizeSuffix(data.width));
					}

					dom.setStyle(tableElm, 'height', addSizeSuffix(data.height));

					// Toggle caption on/off
					captionElm = dom.select('caption', tableElm)[0];

					if (captionElm && !data.caption) {
						dom.remove(captionElm);
					}

					if (!captionElm && data.caption) {
						captionElm = dom.create('caption');
						captionElm.innerHTML = !Env.ie ? '<br data-mce-bogus="1"/>' : '\u00a0';
						tableElm.insertBefore(captionElm, tableElm.firstChild);
					}

					unApplyAlign(tableElm);
					if (data.align) {
						editor.formatter.apply('align' + data.align, {}, tableElm);
					}

					editor.focus();
					editor.addVisual();
				});
			}

			if (isProps === true) {
				tableElm = dom.getParent(editor.selection.getStart(), 'table');

				if (tableElm) {
					data = {
						width: removePxSuffix(dom.getStyle(tableElm, 'width') || dom.getAttrib(tableElm, 'width')),
						height: removePxSuffix(dom.getStyle(tableElm, 'height') || dom.getAttrib(tableElm, 'height')),
						cellspacing: tableElm ? dom.getAttrib(tableElm, 'cellspacing') : '',
						cellpadding: tableElm ? dom.getAttrib(tableElm, 'cellpadding') : '',
						border: tableElm ? dom.getAttrib(tableElm, 'border') : '',
						caption: !!dom.select('caption', tableElm)[0],
						'class': dom.getAttrib(tableElm, 'class')
					};

					each('left center right'.split(' '), function(name) {
						if (editor.formatter.matchNode(tableElm, 'align' + name)) {
							data.align = name;
						}
					});
				}
			} else {
				colsCtrl = {label: 'Cols', name: 'cols'};
				rowsCtrl = {label: 'Rows', name: 'rows'};
			}

			if (editor.settings.table_class_list) {
				if (data["class"]) {
					data["class"] = data["class"].replace(/\s*mce\-item\-table\s*/g, '');
				}

				classListCtrl = {
					name: 'class',
					type: 'listbox',
					label: 'Class',
					values: buildListItems(
						editor.settings.table_class_list,
						function(item) {
							if (item.value) {
								item.textStyle = function() {
									return editor.formatter.getCssText({block: 'table', classes: [item.value]});
								};
							}
						}
					)
				};
			}

			generalTableForm = {
				type: 'form',
				layout: 'flex',
				direction: 'column',
				labelGapCalc: 'children',
				padding: 0,
				items: [
					{
						type: 'form',
						labelGapCalc: false,
						padding: 0,
						layout: 'grid',
						columns: 2,
						defaults: {
							type: 'textbox',
							maxWidth: 50
						},
						items: [
							colsCtrl,
							rowsCtrl,
							{label: 'Width', name: 'width'},
							{label: 'Height', name: 'height'},
							{label: 'Cell spacing', name: 'cellspacing'},
							{label: 'Cell padding', name: 'cellpadding'},
							{label: 'Border', name: 'border'},
							{label: 'Caption', name: 'caption', type: 'checkbox'}
						]
					},

					{
						label: 'Alignment',
						name: 'align',
						type: 'listbox',
						text: 'None',
						values: [
							{text: 'None', value: ''},
							{text: 'Left', value: 'left'},
							{text: 'Center', value: 'center'},
							{text: 'Right', value: 'right'}
						]
					},

					classListCtrl
				]
			};

			if (editor.settings.table_advtab !== false) {
				appendStylesToData(dom, data, tableElm);

				editor.windowManager.open({
					title: "Table properties",
					data: data,
					bodyType: 'tabpanel',
					body: [
						{
							title: 'General',
							type: 'form',
							items: generalTableForm
						},
						createStyleForm(dom)
					],

					onsubmit: onSubmitTableForm
				});
			} else {
				editor.windowManager.open({
					title: "Table properties",
					data: data,
					body: generalTableForm,
					onsubmit: onSubmitTableForm
				});
			}
		};

		self.merge = function(grid, cell) {
			editor.windowManager.open({
				title: "Merge cells",
				body: [
					{label: 'Cols', name: 'cols', type: 'textbox', value: '1', size: 10},
					{label: 'Rows', name: 'rows', type: 'textbox', value: '1', size: 10}
				],
				onsubmit: function() {
					var data = this.toJSON();

					editor.undoManager.transact(function() {
						grid.merge(cell, data.cols, data.rows);
					});
				}
			});
		};

		self.cell = function() {
			var dom = editor.dom, cellElm, data, classListCtrl, cells = [];

			function onSubmitCellForm() {
				updateStyle(dom, this);
				data = Tools.extend(data, this.toJSON());

				editor.undoManager.transact(function() {
					each(cells, function(cellElm) {
						editor.dom.setAttribs(cellElm, {
							scope: data.scope,
							style: data.style,
							'class': data['class']
						});

						editor.dom.setStyles(cellElm, {
							width: addSizeSuffix(data.width),
							height: addSizeSuffix(data.height)
						});

						// Switch cell type
						if (data.type && cellElm.nodeName.toLowerCase() != data.type) {
							cellElm = dom.rename(cellElm, data.type);
						}

						// Apply/remove alignment
						unApplyAlign(cellElm);
						if (data.align) {
							editor.formatter.apply('align' + data.align, {}, cellElm);
						}

						// Apply/remove vertical alignment
						unApplyVAlign(cellElm);
						if (data.valign) {
							editor.formatter.apply('valign' + data.valign, {}, cellElm);
						}
					});

					editor.focus();
				});
			}

			// Get selected cells or the current cell
			cells = editor.dom.select('td.mce-item-selected,th.mce-item-selected');
			cellElm = editor.dom.getParent(editor.selection.getStart(), 'td,th');
			if (!cells.length && cellElm) {
				cells.push(cellElm);
			}

			cellElm = cellElm || cells[0];

			if (!cellElm) {
				// If this element is null, return now to avoid crashing.
				return;
			}

			data = {
				width: removePxSuffix(dom.getStyle(cellElm, 'width') || dom.getAttrib(cellElm, 'width')),
				height: removePxSuffix(dom.getStyle(cellElm, 'height') || dom.getAttrib(cellElm, 'height')),
				scope: dom.getAttrib(cellElm, 'scope'),
				'class': dom.getAttrib(cellElm, 'class')
			};

			data.type = cellElm.nodeName.toLowerCase();

			each('left center right'.split(' '), function(name) {
				if (editor.formatter.matchNode(cellElm, 'align' + name)) {
					data.align = name;
				}
			});

			each('top middle bottom'.split(' '), function(name) {
				if (editor.formatter.matchNode(cellElm, 'valign' + name)) {
					data.valign = name;
				}
			});

			if (editor.settings.table_cell_class_list) {
				classListCtrl = {
					name: 'class',
					type: 'listbox',
					label: 'Class',
					values: buildListItems(
						editor.settings.table_cell_class_list,
						function(item) {
							if (item.value) {
								item.textStyle = function() {
									return editor.formatter.getCssText({block: 'td', classes: [item.value]});
								};
							}
						}
					)
				};
			}

			var generalCellForm = {
				type: 'form',
				layout: 'flex',
				direction: 'column',
				labelGapCalc: 'children',
				padding: 0,
				items: [
					{
						type: 'form',
						layout: 'grid',
						columns: 2,
						labelGapCalc: false,
						padding: 0,
						defaults: {
							type: 'textbox',
							maxWidth: 50
						},
						items: [
							{label: 'Width', name: 'width'},
							{label: 'Height', name: 'height'},
							{
								label: 'Cell type',
								name: 'type',
								type: 'listbox',
								text: 'None',
								minWidth: 90,
								maxWidth: null,
								values: [
									{text: 'Cell', value: 'td'},
									{text: 'Header cell', value: 'th'}
								]
							},
							{
								label: 'Scope',
								name: 'scope',
								type: 'listbox',
								text: 'None',
								minWidth: 90,
								maxWidth: null,
								values: [
									{text: 'None', value: ''},
									{text: 'Row', value: 'row'},
									{text: 'Column', value: 'col'},
									{text: 'Row group', value: 'rowgroup'},
									{text: 'Column group', value: 'colgroup'}
								]
							},
							{
								label: 'H Align',
								name: 'align',
								type: 'listbox',
								text: 'None',
								minWidth: 90,
								maxWidth: null,
								values: [
									{text: 'None', value: ''},
									{text: 'Left', value: 'left'},
									{text: 'Center', value: 'center'},
									{text: 'Right', value: 'right'}
								]
							},
							{
								label: 'V Align',
								name: 'valign',
								type: 'listbox',
								text: 'None',
								minWidth: 90,
								maxWidth: null,
								values: [
									{text: 'None', value: ''},
									{text: 'Top', value: 'top'},
									{text: 'Middle', value: 'middle'},
									{text: 'Bottom', value: 'bottom'}
								]
							}
						]
					},

					classListCtrl
				]
			};

			if (editor.settings.table_cell_advtab !== false) {
				appendStylesToData(dom, data, cellElm);

				editor.windowManager.open({
					title: "Cell properties",
					bodyType: 'tabpanel',
					data: data,
					body: [
						{
							title: 'General',
							type: 'form',
							items: generalCellForm
						},

						createStyleForm(dom)
					],

					onsubmit: onSubmitCellForm
				});
			} else {
				editor.windowManager.open({
					title: "Cell properties",
					data: data,
					body: generalCellForm,
					onsubmit: onSubmitCellForm
				});
			}
		};

		self.row = function() {
			var dom = editor.dom, tableElm, cellElm, rowElm, classListCtrl, data, rows = [], generalRowForm;

			function onSubmitRowForm() {
				var tableElm, oldParentElm, parentElm;

				updateStyle(dom, this);
				data = Tools.extend(data, this.toJSON());

				editor.undoManager.transact(function() {
					var toType = data.type;

					each(rows, function(rowElm) {
						editor.dom.setAttribs(rowElm, {
							scope: data.scope,
							style: data.style,
							'class': data['class']
						});

						editor.dom.setStyles(rowElm, {
							height: addSizeSuffix(data.height)
						});

						if (toType != rowElm.parentNode.nodeName.toLowerCase()) {
							tableElm = dom.getParent(rowElm, 'table');

							oldParentElm = rowElm.parentNode;
							parentElm = dom.select(toType, tableElm)[0];
							if (!parentElm) {
								parentElm = dom.create(toType);
								if (tableElm.firstChild) {
									tableElm.insertBefore(parentElm, tableElm.firstChild);
								} else {
									tableElm.appendChild(parentElm);
								}
							}

							parentElm.appendChild(rowElm);

							if (!oldParentElm.hasChildNodes()) {
								dom.remove(oldParentElm);
							}
						}

						// Apply/remove alignment
						unApplyAlign(rowElm);
						if (data.align) {
							editor.formatter.apply('align' + data.align, {}, rowElm);
						}
					});

					editor.focus();
				});
			}

			tableElm = editor.dom.getParent(editor.selection.getStart(), 'table');
			cellElm = editor.dom.getParent(editor.selection.getStart(), 'td,th');

			each(tableElm.rows, function(row) {
				each(row.cells, function(cell) {
					if (dom.hasClass(cell, 'mce-item-selected') || cell == cellElm) {
						rows.push(row);
						return false;
					}
				});
			});

			rowElm = rows[0];
			if (!rowElm) {
				// If this element is null, return now to avoid crashing.
				return;
			}

			data = {
				height: removePxSuffix(dom.getStyle(rowElm, 'height') || dom.getAttrib(rowElm, 'height')),
				scope: dom.getAttrib(rowElm, 'scope'),
				'class': dom.getAttrib(rowElm, 'class')
			};

			data.type = rowElm.parentNode.nodeName.toLowerCase();

			each('left center right'.split(' '), function(name) {
				if (editor.formatter.matchNode(rowElm, 'align' + name)) {
					data.align = name;
				}
			});

			if (editor.settings.table_row_class_list) {
				classListCtrl = {
					name: 'class',
					type: 'listbox',
					label: 'Class',
					values: buildListItems(
						editor.settings.table_row_class_list,
						function(item) {
							if (item.value) {
								item.textStyle = function() {
									return editor.formatter.getCssText({block: 'tr', classes: [item.value]});
								};
							}
						}
					)
				};
			}

			generalRowForm = {
				type: 'form',
				columns: 2,
				padding: 0,
				defaults: {
					type: 'textbox'
				},
				items: [
					{
						type: 'listbox',
						name: 'type',
						label: 'Row type',
						text: 'None',
						maxWidth: null,
						values: [
							{text: 'Header', value: 'thead'},
							{text: 'Body', value: 'tbody'},
							{text: 'Footer', value: 'tfoot'}
						]
					},
					{
						type: 'listbox',
						name: 'align',
						label: 'Alignment',
						text: 'None',
						maxWidth: null,
						values: [
							{text: 'None', value: ''},
							{text: 'Left', value: 'left'},
							{text: 'Center', value: 'center'},
							{text: 'Right', value: 'right'}
						]
					},
					{label: 'Height', name: 'height'},
					classListCtrl
				]
			};

			if (editor.settings.table_row_advtab !== false) {
				appendStylesToData(dom, data, rowElm);

				editor.windowManager.open({
					title: "Row properties",
					data: data,
					bodyType: 'tabpanel',
					body: [
						{
							title: 'General',
							type: 'form',
							items: generalRowForm
						},
						createStyleForm(dom)
					],

					onsubmit: onSubmitRowForm
				});
			} else {
				editor.windowManager.open({
					title: "Row properties",
					data: data,
					body: generalRowForm,
					onsubmit: onSubmitRowForm
				});
			}
		};
	};
});

// Included from: js/tinymce/plugins/table/classes/Plugin.js

/**
 * Plugin.js
 *
 * Copyright, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://www.tinymce.com/license
 * Contributing: http://www.tinymce.com/contributing
 */

/**
 * This class contains all core logic for the table plugin.
 *
 * @class tinymce.tableplugin.Plugin
 * @private
 */
define("tinymce/tableplugin/Plugin", [
	"tinymce/tableplugin/TableGrid",
	"tinymce/tableplugin/Quirks",
	"tinymce/tableplugin/CellSelection",
	"tinymce/tableplugin/Dialogs",
	"tinymce/util/Tools",
	"tinymce/dom/TreeWalker",
	"tinymce/Env",
	"tinymce/PluginManager"
], function(TableGrid, Quirks, CellSelection, Dialogs, Tools, TreeWalker, Env, PluginManager) {
	var each = Tools.each;

	function Plugin(editor) {
		var clipboardRows, self = this, dialogs = new Dialogs(editor);

		function cmd(command) {
			return function() {
				editor.execCommand(command);
			};
		}

		function insertTable(cols, rows) {
			var y, x, html, tableElm;

			html = '<table id="__mce"><tbody>';

			for (y = 0; y < rows; y++) {
				html += '<tr>';

				for (x = 0; x < cols; x++) {
					html += '<td>' + (Env.ie ? " " : '<br>') + '</td>';
				}

				html += '</tr>';
			}

			html += '</tbody></table>';

			editor.undoManager.transact(function() {
				editor.insertContent(html);

				tableElm = editor.dom.get('__mce');
				editor.dom.setAttrib(tableElm, 'id', null);

				editor.dom.setAttribs(tableElm, editor.settings.table_default_attributes || {});
				editor.dom.setStyles(tableElm, editor.settings.table_default_styles || {});
			});

			return tableElm;
		}

		function handleDisabledState(ctrl, selector) {
			function bindStateListener() {
				ctrl.disabled(!editor.dom.getParent(editor.selection.getStart(), selector));

				editor.selection.selectorChanged(selector, function(state) {
					ctrl.disabled(!state);
				});
			}

			if (editor.initialized) {
				bindStateListener();
			} else {
				editor.on('init', bindStateListener);
			}
		}

		function postRender() {
			/*jshint validthis:true*/
			handleDisabledState(this, 'table');
		}

		function postRenderCell() {
			/*jshint validthis:true*/
			handleDisabledState(this, 'td,th');
		}

		function generateTableGrid() {
			var html = '';

			html = '<table role="grid" class="mce-grid mce-grid-border" aria-readonly="true">';

			for (var y = 0; y < 10; y++) {
				html += '<tr>';

				for (var x = 0; x < 10; x++) {
					html += '<td role="gridcell" tabindex="-1"><a id="mcegrid' + (y * 10 + x) + '" href="#" ' +
						'data-mce-x="' + x + '" data-mce-y="' + y + '"></a></td>';
				}

				html += '</tr>';
			}

			html += '</table>';

			html += '<div class="mce-text-center" role="presentation">1 x 1</div>';

			return html;
		}

		function selectGrid(tx, ty, control) {
			var table = control.getEl().getElementsByTagName('table')[0];
			var x, y, focusCell, cell, active;
			var rtl = control.isRtl() || control.parent().rel == 'tl-tr';

			table.nextSibling.innerHTML = (tx + 1) + ' x ' + (ty + 1);

			if (rtl) {
				tx = 9 - tx;
			}

			for (y = 0; y < 10; y++) {
				for (x = 0; x < 10; x++) {
					cell = table.rows[y].childNodes[x].firstChild;
					active = (rtl ? x >= tx : x <= tx) && y <= ty;

					editor.dom.toggleClass(cell, 'mce-active', active);

					if (active) {
						focusCell = cell;
					}
				}
			}

			return focusCell.parentNode;
		}

		if (editor.settings.table_grid === false) {
			editor.addMenuItem('inserttable', {
				text: 'Insert table',
				icon: 'table',
				context: 'table',
				onclick: dialogs.table
			});
		} else {
			editor.addMenuItem('inserttable', {
				text: 'Insert table',
				icon: 'table',
				context: 'table',
				ariaHideMenu: true,
				onclick: function(e) {
					if (e.aria) {
						this.parent().hideAll();
						e.stopImmediatePropagation();
						dialogs.table();
					}
				},
				onshow: function() {
					selectGrid(0, 0, this.menu.items()[0]);
				},
				onhide: function() {
					var elements = this.menu.items()[0].getEl().getElementsByTagName('a');
					editor.dom.removeClass(elements, 'mce-active');
					editor.dom.addClass(elements[0], 'mce-active');
				},
				menu: [
					{
						type: 'container',
						html: generateTableGrid(),

						onPostRender: function() {
							this.lastX = this.lastY = 0;
						},

						onmousemove: function(e) {
							var target = e.target, x, y;

							if (target.tagName.toUpperCase() == 'A') {
								x = parseInt(target.getAttribute('data-mce-x'), 10);
								y = parseInt(target.getAttribute('data-mce-y'), 10);

								if (this.isRtl() || this.parent().rel == 'tl-tr') {
									x = 9 - x;
								}

								if (x !== this.lastX || y !== this.lastY) {
									selectGrid(x, y, e.control);

									this.lastX = x;
									this.lastY = y;
								}
							}
						},

						onclick: function(e) {
							var self = this;

							if (e.target.tagName.toUpperCase() == 'A') {
								e.preventDefault();
								e.stopPropagation();
								self.parent().cancel();

								editor.undoManager.transact(function() {
									insertTable(self.lastX + 1, self.lastY + 1);
								});

								editor.addVisual();
							}
						}
					}
				]
			});
		}

		editor.addMenuItem('tableprops', {
			text: 'Table properties',
			context: 'table',
			onPostRender: postRender,
			onclick: dialogs.tableProps
		});

		editor.addMenuItem('deletetable', {
			text: 'Delete table',
			context: 'table',
			onPostRender: postRender,
			cmd: 'mceTableDelete'
		});

		editor.addMenuItem('cell', {
			separator: 'before',
			text: 'Cell',
			context: 'table',
			menu: [
				{text: 'Cell properties', onclick: cmd('mceTableCellProps'), onPostRender: postRenderCell},
				{text: 'Merge cells', onclick: cmd('mceTableMergeCells'), onPostRender: postRenderCell},
				{text: 'Split cell', onclick: cmd('mceTableSplitCells'), onPostRender: postRenderCell}
			]
		});

		editor.addMenuItem('row', {
			text: 'Row',
			context: 'table',
			menu: [
				{text: 'Insert row before', onclick: cmd('mceTableInsertRowBefore'), onPostRender: postRenderCell},
				{text: 'Insert row after', onclick: cmd('mceTableInsertRowAfter'), onPostRender: postRenderCell},
				{text: 'Delete row', onclick: cmd('mceTableDeleteRow'), onPostRender: postRenderCell},
				{text: 'Row properties', onclick: cmd('mceTableRowProps'), onPostRender: postRenderCell},
				{text: '-'},
				{text: 'Cut row', onclick: cmd('mceTableCutRow'), onPostRender: postRenderCell},
				{text: 'Copy row', onclick: cmd('mceTableCopyRow'), onPostRender: postRenderCell},
				{text: 'Paste row before', onclick: cmd('mceTablePasteRowBefore'), onPostRender: postRenderCell},
				{text: 'Paste row after', onclick: cmd('mceTablePasteRowAfter'), onPostRender: postRenderCell}
			]
		});

		editor.addMenuItem('column', {
			text: 'Column',
			context: 'table',
			menu: [
				{text: 'Insert column before', onclick: cmd('mceTableInsertColBefore'), onPostRender: postRenderCell},
				{text: 'Insert column after', onclick: cmd('mceTableInsertColAfter'), onPostRender: postRenderCell},
				{text: 'Delete column', onclick: cmd('mceTableDeleteCol'), onPostRender: postRenderCell}
			]
		});

		var menuItems = [];
		each("inserttable tableprops deletetable | cell row column".split(' '), function(name) {
			if (name == '|') {
				menuItems.push({text: '-'});
			} else {
				menuItems.push(editor.menuItems[name]);
			}
		});

		editor.addButton("table", {
			type: "menubutton",
			title: "Table",
			menu: menuItems
		});

		// Select whole table is a table border is clicked
		if (!Env.isIE) {
			editor.on('click', function(e) {
				e = e.target;

				if (e.nodeName === 'TABLE') {
					editor.selection.select(e);
					editor.nodeChanged();
				}
			});
		}

		self.quirks = new Quirks(editor);

		editor.on('Init', function() {
			self.cellSelection = new CellSelection(editor);
		});

		// Register action commands
		each({
			mceTableSplitCells: function(grid) {
				grid.split();
			},

			mceTableMergeCells: function(grid) {
				var cell;

				cell = editor.dom.getParent(editor.selection.getStart(), 'th,td');

				if (!editor.dom.select('td.mce-item-selected,th.mce-item-selected').length) {
					dialogs.merge(grid, cell);
				} else {
					grid.merge();
				}
			},

			mceTableInsertRowBefore: function(grid) {
				grid.insertRow(true);
			},

			mceTableInsertRowAfter: function(grid) {
				grid.insertRow();
			},

			mceTableInsertColBefore: function(grid) {
				grid.insertCol(true);
			},

			mceTableInsertColAfter: function(grid) {
				grid.insertCol();
			},

			mceTableDeleteCol: function(grid) {
				grid.deleteCols();
			},

			mceTableDeleteRow: function(grid) {
				grid.deleteRows();
			},

			mceTableCutRow: function(grid) {
				clipboardRows = grid.cutRows();
			},

			mceTableCopyRow: function(grid) {
				clipboardRows = grid.copyRows();
			},

			mceTablePasteRowBefore: function(grid) {
				grid.pasteRows(clipboardRows, true);
			},

			mceTablePasteRowAfter: function(grid) {
				grid.pasteRows(clipboardRows);
			},

			mceTableDelete: function(grid) {
				grid.deleteTable();
			}
		}, function(func, name) {
			editor.addCommand(name, function() {
				var grid = new TableGrid(editor);

				if (grid) {
					func(grid);
					editor.execCommand('mceRepaint');
					self.cellSelection.clear();
				}
			});
		});

		// Register dialog commands
		each({
			mceInsertTable: dialogs.table,
			mceTableProps: function() {
				dialogs.table(true);
			},
			mceTableRowProps: dialogs.row,
			mceTableCellProps: dialogs.cell
		}, function(func, name) {
			editor.addCommand(name, function(ui, val) {
				func(val);
			});
		});

		// Enable tab key cell navigation
		if (editor.settings.table_tab_navigation !== false) {
			editor.on('keydown', function(e) {
				var cellElm, grid, delta;

				if (e.keyCode == 9) {
					cellElm = editor.dom.getParent(editor.selection.getStart(), 'th,td');

					if (cellElm) {
						e.preventDefault();

						grid = new TableGrid(editor);
						delta = e.shiftKey ? -1 : 1;

						editor.undoManager.transact(function() {
							if (!grid.moveRelIdx(cellElm, delta) && delta > 0) {
								grid.insertRow();
								grid.refresh();
								grid.moveRelIdx(cellElm, delta);
							}
						});
					}
				}
			});
		}

		self.insertTable = insertTable;
	}

	PluginManager.add('table', Plugin);
});
})(this);
});
