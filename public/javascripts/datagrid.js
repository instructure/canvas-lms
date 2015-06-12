/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// xsslint jqueryObject.method _createCell _templateCellHTML

define([
  'INST' /* INST */,
  'jquery' /* $ */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.scrollToVisible' /* scrollToVisible */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/position' /* /\.position\(/ */
], function(INST, $) {

  var datagrid = {
    columns: [],
    rows: [],
    dataRows: [],
    dataFragment: document.createDocumentFragment(),
    cells: {},
    divs: {},
    init: function($table, options) {
      var callback = options.onReady;
      var tick = options.tick;
      var maxWidth = options.maxWidth || 150;
      datagrid.borderSize = options.borderSize || 1;
      datagrid.paddingBottom = options.paddingBottom || 0;
      if(options.scroll && $.isFunction(options.scroll)) {
        datagrid.scrollCallback = options.scroll;
      }
      datagrid.table = $table;
      datagrid.toggleCallback = options.toggle;
      var $columns = $table.find("tr:first td");
      var $rows = $table.find("tr");
      var columnTally = 0;
      // Measure table columns
      $columns.each(function(i) {
        var $col = datagrid.columns[i] = $(this);
        $col.metrics = {
          width: Math.min($col.width(), maxWidth),
          outerWidth: Math.min($col.outerWidth(), (maxWidth+1))
        };
        columnTally += $col.metrics.outerWidth;
      });
      // Measure table rows
      var rowTally = 0;
      $rows.each(function(i) {
        var $row = datagrid.rows[i] = $(this);
        $row.metrics = {
          outerHeight: $row.find("td:first").outerHeight(),
          height: $row.find("td:first").height()
        };
        rowTally += $row.metrics.height;
      });
      if(tick && $.isFunction(tick)) { tick(); }
      // Initialize container DOM elements
      datagrid.divs.all = $(".datagrid");
      datagrid.divs.topleft = $("#datagrid_topleft");
      datagrid.divs.left = $("#datagrid_left");
      datagrid.divs.top = $("#datagrid_top");
      datagrid.divs.data = $("#datagrid_data");
      datagrid.divs.filler = $("#datagrid_filler");
      datagrid.divs.topleft.width(datagrid.columns[0].metrics.width + datagrid.borderSize);
      datagrid.divs.left.width(datagrid.columns[0].metrics.width + datagrid.borderSize);
      datagrid.divs.filler.width(columnTally - datagrid.columns[0].metrics.width);
      datagrid.divs.top.height(datagrid.rows[0].metrics.height + datagrid.borderSize);
      datagrid.divs.topleft.height(datagrid.rows[0].metrics.height + datagrid.borderSize);
      datagrid.divs.filler.height(rowTally - datagrid.rows[0].metrics.height);
      datagrid._initializeListeners();
      datagrid._templateCellHTML = options.templateCellHTML;
      datagrid.sizeToWindow();
      $(window).resize(datagrid.sizeToWindow);
      
      // Initialize top-left corner cell
      var $row = datagrid._createRow(0, true);
      $row.append(datagrid._createCell(0,0, $table.find("tr:first td:first")));
      datagrid.divs.topleft.children(".content:first").append($row); //

      // Initialize top row (column headers)
      $row = datagrid._createRow(0);
      $row.width(columnTally - datagrid.columns[0].metrics.outerWidth);
      $table.find("tr:first").children("td:not(:first)").each(function(i) {
        $row.append(datagrid._createCell(0, i + 1, $(this)));
      });
      datagrid.divs.top.children(".content:first").append($row);
      
      if(tick && $.isFunction(tick)) { tick(); }
      var rowHeadersBuilt = false;
      // Function to handle each row individually, including the row header
      var handleRow = function(i) {
        if(!rowHeadersBuilt) {
          $row = datagrid._createRow(i + 1, true);
          $row.append(datagrid._createCell(i + 1, 0, $(this).find("td:first")));
          datagrid.divs.left.children(".content:first").append($row);
        }
        
        $row = datagrid._createRow(i + 1);
        $(this).children("td:not(:first)").each(function(j) {
          datagrid._createCell(i + 1, j + 1, $(this));
          datagrid._placeDataCell(i + 1, j + 1);
        });
        datagrid._placeDataRow(i + 1);
      }
      var rows = [];
      var populatedHeight = 0, populatedCells = 0;
      $table.find("tr:not(:first)").each(function(i) {
        var populatedWidth = 0;
        
        $row = datagrid._createRow(i + 1, true);
        $row.append(datagrid._createCell(i + 1, 0, $(this).find("td:first")));
        datagrid.divs.left.children(".content:first").append($row);
        
        $row = datagrid._createRow(i + 1);
        $row.width(columnTally - datagrid.columns[0].metrics.outerWidth);
        $(this).children("td:not(:first)").each(function(j) {
          populatedWidth = populatedWidth + datagrid.columns[j + 1].metrics.width;
        });
        datagrid._placeDataRow(i + 1);
        populatedHeight = populatedHeight + datagrid.rows[i + 1].metrics.height;
        
        rows.push($(this));
      })
      rowHeadersBuilt = true;
      datagrid._placeDataFragment();
      if(options && options.onViewable && $.isFunction(options.onViewable)) {
        options.onViewable.call(this);
      }
      var idx = 0;
      var nextRow = function(finisher) {
        if(tick && $.isFunction(tick) && finisher) { tick(); }
        if(idx < rows.length) {
          var i = idx;
          idx++;
          handleRow.call(rows[i], i);
          setTimeout(function() { 
            nextRow(true) 
          }, 1);
        } else if(finisher && !nextRow.finished) {
          nextRow.finished = true;
          datagrid.initialized = true;
          $table.hide();
          if(datagrid.ready && $.isFunction(datagrid.ready)) {
            datagrid.ready();
          }
          if(callback && $.isFunction(callback)) {
            callback();
          }

          // stupid hack to handle if you have zoomed in on the page in firefox.
          if (INST.browser.ff) {
            var $datagrid_top= $('#datagrid_top'),
                $topRow = $datagrid_top.find('.row'),
                $all_rows = $topRow.add('#datagrid_data .row');

            function fixForDifferentZoomLevelInFirefox(){
              var existingDatagridTopWidth = $datagrid_top.width();

              // make styles so the .row can be as wide as it needs to fit all the .cell's in it without wrapping
              $datagrid_top.width(99999999);
              $topRow.css({'position': 'relative', 'width' : ''});
              var topWidth = $topRow.width() +1;

              //reset styles back to what they were was
              $datagrid_top.width(existingDatagridTopWidth);
              $topRow.css('position', ''); 

              $all_rows.width(topWidth); 
            }
            fixForDifferentZoomLevelInFirefox();

            // changing the zoom level in firefox will trigger the resize event on the window.
            // so listen to it and re-run the fix when it is fired
            var firefoxZoomHackTimout;
            $(window).resize(function(){
              clearTimeout(firefoxZoomHackTimout);
              firefoxZoomHackTimout = setTimeout(fixForDifferentZoomLevelInFirefox, 100);
            });
          } //end of stupid firefox zoomlevel hack
        }
      };
      setTimeout(function() { nextRow(true); }, 5);
      setTimeout(function() { nextRow(false); }, 5);
      setTimeout(function() { nextRow(false); }, 5);
      setTimeout(function() { nextRow(false); }, 5);
      
      var $topChild = datagrid.divs.top.children(".content:first");
      var $leftChild = datagrid.divs.left.children(".content:first");
      var scrollPositionChanged = false;
      setInterval(function() {
        if(!scrollPositionChanged) { return; }
        if($topChild.length === 0) {
          $topChild = datagrid.divs.top.children(".content:first");
        }
        if($leftChild.length === 0) {
          $leftChild = datagrid.divs.left.children(".content:first");
        }
          
        $topChild.css('left', 0 - datagrid.divs.data.scrollLeft());
        $leftChild.css('top', 0 - datagrid.divs.data.scrollTop());
        if(datagrid.scrollCallback) {
          datagrid.scrollCallback();
        }
        scrollPositionChanged = false;
      }, 100);
      // Listen for scroll events on main content, scroll header divs
      datagrid.divs.data.bind('scroll', function() {
        scrollPositionChanged = true;
      });

      datagrid.mouseHasMoved = true;
      $(document).mousemove(function(event) {
        datagrid.mouseHasMoved = true;
      });
      
      // Keyboard navigation
      $(document).keycodes('up down left right tab shift+tab', function(event) {
        if($(event.target).closest(".ui-dialog").length > 0) { return; }
        event.preventDefault();
        event.stopPropagation();
        if(event.keyString == 'right' || event.keyString == 'tab') {
          datagrid.moveRight();
        } else if(event.keyString == 'down') {
          datagrid.moveDown();
        } else if(event.keyString == 'up') { 
          datagrid.moveUp();
        } else if(event.keyString == 'left' || event.keyString == 'shift+tab') {
          datagrid.moveLeft();
        }
      });
    },
    _initializeListeners: function() {
      datagrid.divs.all
        .delegate('.cell', 'mousemove', datagrid._cellMove)
        .delegate('.cell', 'mouseover', datagrid._cellOver)
        .delegate('.cell', 'mouseout', datagrid._cellOut)
        .delegate('.cell', 'click', datagrid._cellClick);
    },
    titles: function(order) {
      var titles = [];
      for(var idx in order) {
        var $obj = datagrid.cells[0 + ',' + order[idx]];
        titles.push($obj.find(".assignment_title").text() || "--");
      }
    },
    reorderColumns: function(order) {
      var newCells = {}, newColumns = [];
      var currentOrder = [];
      for(var i = 0; i < order.length; i++) { currentOrder[i] = i; }
      for(var to_index = 0; to_index < order.length; to_index++) {
        var from_index = order[to_index];
        for(var row = 0; row < datagrid.rows.length; row++) {
          var $cell = datagrid.cells[row + ',' + from_index];
          var $obj = datagrid.cells[row + ',' + currentOrder[to_index]];
          if(currentOrder[to_index] == from_index) {
          } else if(currentOrder[to_index] < from_index) {
            datagrid.cells[row + ',' + currentOrder[to_index]].before($cell);
          } else {
            datagrid.cells[row + ',' + currentOrder[to_index]].after($cell);
          }
          newCells[row + ',' + to_index] = datagrid.cells[row + ',' + from_index];
          newCells[row + ',' + to_index].column = to_index;
          newCells[row + ',' + to_index].data('datagrid_position', {row: row, column: to_index});
          newCells[row + ',' + to_index].data('column', to_index);
          newColumns[to_index] = datagrid.columns[from_index];
        }
        var currentIndex = -1;
        for(var i = 0; i < currentOrder.length; i++) {
          if(currentOrder[i] == from_index) {
            currentIndex = i;
          }
        }
        if(to_index == currentIndex) {
        } else if(to_index < currentIndex) {
          currentOrder.splice(to_index, 0, from_index);
          currentOrder.splice(currentIndex + 1, 1);
        } else {
          currentOrder.splice(to_index, 0, from_index);
          currentOrder.splice(currentIndex, 1);
        }
      }
      datagrid.cells = newCells;
      datagrid.columns = newColumns;
    },
    reorderRows: function(order) {
      var newCells = {}, newRows = [];
      var currentOrder = [];
      for(var i = 0; i < order.length; i++) { currentOrder[i] = i; }
      var top = 0;
      for(var to_index = 0; to_index < order.length; to_index++) {
        var from_index = order[to_index];
        var $row_head = datagrid.cells[from_index + ',0'].parents(".row");
        var $row = datagrid.cells[from_index + ',1'].parents(".row");
        $row.css('top', top);
        $row_head.css('top', top);
        if(to_index > 0) {
          top = top + datagrid.rows[from_index].metrics.height + 1;
        }
        if(currentOrder[to_index] == from_index) {
        } else if(currentOrder[to_index] < from_index) {
          datagrid.cells[currentOrder[to_index] + ',0'].parents(".row").before($row_head);
          datagrid.cells[currentOrder[to_index] + ',1'].parents(".row").before($row);
        } else {
          datagrid.cells[currentOrder[to_index] + ',0'].parents(".row").after($row_head);
          datagrid.cells[currentOrder[to_index] + ',1'].parents(".row").after($row);
        }
        newRows[to_index] = datagrid.rows[from_index];
        for(var col = 0; col < datagrid.columns.length; col++) {
          var $cell = datagrid.cells[from_index + ',' + col];
          newCells[to_index + ',' + col] = datagrid.cells[from_index + ',' + col];
          newCells[to_index + ',' + col].row = to_index;
          newCells[to_index + ',' + col].data('datagrid_position', {row: to_index, column: col});
          newCells[to_index + ',' + col].data('row', to_index);
          newRows[to_index] = datagrid.rows[from_index];
        }
        var currentIndex = -1;
        for(var i = 0; i < currentOrder.length; i++) {
          if(currentOrder[i] == from_index) {
            currentIndex = i;
          }
        }
        if(to_index == currentIndex) {
        } else if(to_index < currentIndex) {
          currentOrder.splice(to_index, 0, from_index);
          currentOrder.splice(currentIndex + 1, 1);
        } else {
          currentOrder.splice(to_index, 0, from_index);
          currentOrder.splice(currentIndex, 1);
        }
      }
      datagrid.cells = newCells;
      datagrid.rows = newRows;
    },
    moveColumn: function(from_index, to_index) {
      new_order = [];
      if(from_index == 0 || to_index == 0 || from_index == to_index) { return; }
      for(var col = 0; col < datagrid.columns.length; col++) {
        if(col == to_index) {
          new_order.push(from_index);
        } else if((col >= to_index && col <= from_index) || (col <= to_index && col >= from_index)) {
          if(to_index < from_index) {
            new_order.push(col - 1);
          } else {
            new_order.push(col + 1);
          }
        } else {
          new_order.push(col);
        }
      }
      datagrid.reorderColumns(new_order);
    },
    _placeDataCell: function(row, col) {
      if(row < 1 || col < 1) { return; }
      var $cell = datagrid.cells[row + ',' + col];
      if($cell && $cell.placed) { return; }
      var $row = datagrid.dataRows[row];
      if($row) {
        $row.append($cell);
        $cell.placed = true;
      }
    },
    
    // builds up a string that gets gets converted to an html node in one whack instead of using DOM methods, 
    // this was the slowest part of initializing the datagrid
    _initializeCell: function(row, col) {
      if(!datagrid.cells[row + ',' + col]) {
        var classes = ['cell'];
        if(row === 0) { classes.push('column_header');  }
        if(col === 0) { classes.push('row_header'); }
        if(col !== 0 && row !== 0) { classes.push('data_cell'); }
        var $cell = $(
          [ "<div class='", classes.join(" "), "' style='visibility: hidden; height:", datagrid.rows[row].metrics.height, 
            "px; width:", datagrid.columns[col].metrics.width, "px;' data-row='", row,
            "' data-column='", col,"'/>"
          ].join('')
        ).data({'row': row, 'column': col});
        $cell.row = row;
        $cell.column = col;
        datagrid.cells[row + ',' + col] = $cell;
      }
      return datagrid.cells[row + ',' + col];
    },
    _createCell: function(row, col, $td) {
      var $cell = datagrid._initializeCell(row, col);
      if($cell.transferred) { return $cell; }
      if(row != 0 && col != 0 && datagrid._templateCellHTML) {
        $cell.append(datagrid._templateCellHTML(row, col));
      } else {
        $cell.append($td.children());
      }
      $cell.attr('id', $td.attr('id'));
      $td.attr('id', "original_" + $cell.attr('id'));
      $cell.originalTD = $td;
      $cell.addClass($td.attr('class'));
      $cell.css('visibility', '');
      $cell.transferred = true;
      return $cell;
    },
    _trigger: function(event_type, event, object) {
      var e = $.Event(event_type);
      e.originalEvent = event;
      e.originalTarget = object;
      datagrid.table.trigger(e, {cell: object, trueEvent: (event && event.originalEvent)})
    },
    _cellClick: function(event) {
      var position = datagrid.position($(this));
      var $cell = datagrid.cells[position.row + ',' + position.column];
      if(datagrid.columns[$cell.column].hidden) {
        datagrid.toggleColumn($cell.column);
        return;
      }
      datagrid._trigger('entry_click', event, $cell);
    },
    _cellMove: function(event) {
      if(datagrid.disableHighlights) { return; }
      var position = datagrid.position($(this));
      var $cell = datagrid.cells[position.row + ',' + position.column];
      datagrid.table.trigger('entry_move', $cell);
      if($(this).index(datagrid.currentHover) != -1) {
        return;
      }
      $cell.trigger('mouseover');
    },
    _cellOver: function(event) {
      if(datagrid.disableHighlights) { return; }
      if(event.originalEvent && !datagrid.mouseHasMoved) { return; }
      datagrid.mouseHasMoved = false;
      var position = datagrid.position($(this));
      var $cell = datagrid.cells[position.row + ',' + position.column];
      $cell.addClass('selected');
      if(datagrid.currentHover && $cell.index(datagrid.currentHover) == -1) {
        $(datagrid.currentHover).trigger('mouseout');
      }
      datagrid.currentHover = $cell;
      if($cell.row == 0) {
        for(var i = 1; i < datagrid.rows.length; i++) {
          datagrid.cells[i + ',' + $cell.column].addClass('related');
        }
      } else if($cell.column == 0) {
        for(var i = 1; i < datagrid.columns.length; i++) {
          datagrid.cells[$cell.row + ',' + i].addClass('related');
        }
      } else {
        datagrid.cells[$cell.row + ',' + 0].addClass('related');
        datagrid.cells[0 + ',' + $cell.column].addClass('related');
      }
      datagrid._trigger('entry_over', event, $cell);
    },
    _cellOut: function(event) {
      if(datagrid.disableHighlights) { return; }
      if($(event.target).parents("div").index(this) != -1) { return; }
      var position = datagrid.position($(this));
      var $cell = datagrid.cells[position.row + ',' + position.column];
      $cell.removeClass('selected');
      if($cell.row == 0) {
        for(var i = 1; i < datagrid.rows.length; i++) {
          datagrid.cells[i + ',' + $cell.column].removeClass('related');
        }
      } else if($cell.column == 0) {
        for(var i = 1; i < datagrid.columns.length; i++) {
          datagrid.cells[$cell.row + ',' + i].removeClass('related');
        }
      } else {
        datagrid.cells[$cell.row + ',' + 0].removeClass('related');
        datagrid.cells[0 + ',' + $cell.column].removeClass('related');
      }
      datagrid._trigger('entry_out', event, $cell);
    },
    _placeDataFragment: function() {
      if(datagrid.dataFragment) {
        datagrid.divs.data.find(".content:first")[0].appendChild(datagrid.dataFragment);
        datagrid.dataFragment = null;
      }
    },
    _placeDataRow: function(row) {
      if(row < 1) { return; }
      var $row = datagrid.dataRows[row] || datagrid._createRow(row);
      if($row.placed) { return; }
      if(datagrid.dataFragment) {
        datagrid.dataFragment.appendChild($row[0]);
      } else {
        datagrid.divs.data.find(".content:first").append($row);
      }
      $row.placed = true;
    },
    _createRow: function(row, header) {
      if(datagrid.dataRows[row]) { return datagrid.dataRows[row]; }
      var fragment = document.createDocumentFragment();
      var $row = $(document.createElement('div')).addClass('row');
      fragment.appendChild($row[0]);
      $row.height(datagrid.rows[row].metrics.height);
      var top = 0;
      for(var i = 1; i < row; i++) {
        top += datagrid.rows[i].metrics.height + 1;
      }
      var left = 0;
      $row.css({top: top, left: left});
      if(row > 0 && !header) {
        datagrid.dataRows[row] = $row;
      }
      return $row;
    },
    toggleColumn: function(col, forceShow, options) {
      var showing = !datagrid.columns[col].hidden;
      var show = !!datagrid.columns[col].hidden;
      if(forceShow) { show = true; }
      else if(forceShow === false) { show = false; }
      if((!options || options.callback !== false) && $.isFunction(datagrid.toggleCallback)) {
        datagrid.toggleCallback(col, !!show);
      }
      if(showing == show) { return; }
      for(var i = 0; i < datagrid.rows.length; i++) {
        datagrid.cells[i + ',' + col]
          .width(show ? datagrid.columns[col].metrics.width : 10)
          .children().showIf(show).toggleClass('hidden_column', !show);
      }
      datagrid.columns[col].hidden = !show;
      if(!options || !options.skipSizeGrid) {
        datagrid.sizeGrid();
      }
      return show;
    },
    sizeGrid: function() {
      var width = 0;
      for(var i = 1; i < datagrid.columns.length; i++) {
        width += (datagrid.columns[i].hidden ? 10 : datagrid.columns[i].metrics.width);
      }
      datagrid.divs.filler.width(width - datagrid.columns[0].metrics.width);
      for(var i = 0; i < datagrid.rows.length; i++) {
        datagrid.cells[i + ',' + 1].parent(".row").width(width + datagrid.columns.length + 3);
      }
    },
    focus: function(row, col) {
      var $cell = datagrid.cells[row + ',' + col];
      if(datagrid.currentFocus && $cell.index(datagrid.currentFocus || []) != -1) { return; }
      if(datagrid.currentFocus) { datagrid.blur(); }
      $cell.addClass('focus');
      datagrid.currentFocus = $cell;
      datagrid._trigger('entry_focus', null, $cell);
    },
    blur: function() {
      if(datagrid.currentFocus) {
        datagrid.currentFocus.removeClass('focus');
        datagrid._trigger('entry_blur', null, datagrid.currentFocus);
        datagrid.currentFocus = null;
      }
    },
    scrollTo: function(row, col) {
      datagrid.disableHighlights = true;
      if(row == 0) { row = 1; }
      if(col == 0) { col = 1; }
      var $cell = datagrid.cells[row + ',' + col];
      datagrid.divs.data.scrollToVisible($cell).triggerHandler('scroll');
      datagrid.disableHighlights = false;
      if($cell && $cell.filter(":visible").length > 0) {
        $cell.attr("tabindex", 0);
        return true;
      }
    },
    sizeToWindow: function() {
      $("html,body").css('overflow', 'hidden');
      var $holder = $("#content,#wide_content");
      if (!$holder.length || $holder.width() < 100) {
        $holder = $(window);
      }
      var spacer = INST.browser.ff ? 1 : 0,
          windowHeight = $(window).height() - spacer - datagrid.divs.top.offset().top,
          windowWidth = $holder.width() - spacer,
          newWidth = Math.floor(windowWidth - datagrid.columns[0].metrics.outerWidth),
          newHeight = Math.floor(windowHeight - datagrid.rows[0].metrics.height - 
                                 datagrid.borderSize - datagrid.paddingBottom);

      datagrid.divs.top.width(newWidth);
      datagrid.divs.data.width(newWidth);
      datagrid.divs.left.height(newHeight);
      datagrid.divs.data.height(newHeight);
      datagrid.divs.data.metrics = {
        width: newWidth,
        height: newHeight
      }
    },
    _selectFirstCell: function() {
      var $cell = datagrid.cells['1,1'];
      $cell.trigger('mouseover');
      datagrid.currentHover = $cell;
      datagrid.scrollTo(1, 1);
    },
    position: function($div) {
      if(!$div.hasClass('cell')) {
        $div = $div.closest(".cell");
      }
      if($div.data('datagrid_position')) { return $div.data('datagrid_position'); }
      if($div.length == 0) { return {}; }
      var result = {
        row: parseInt($div.attr('data-row'), 10),
        column: parseInt($div.attr('data-column'), 10)
      };
      $div.data('datagrid_position', result);
      return result;
    },
    moveLeft: function() {
      var $current = datagrid.currentHover;
      if(!datagrid.currentHover) { datagrid._selectFirstCell(); return; }
      var newCol = $current.column - 1;
      var $new = datagrid.cells[$current.row + ',' + newCol];
      while($new && $new.hidden) {
        newCol--;
        $new = datagrid.cells[$current.row + ',' + newCol];
      }
      if(!$new || $new.length === 0) {
        $new = $current;
      }
      $new.trigger('mouseover').focus();
      datagrid.currentHover = $new;
      datagrid.scrollTo($new.row, $new.column);
    },
    moveRight: function() {
      var $current = datagrid.currentHover;
      if(!datagrid.currentHover) { datagrid._selectFirstCell(); return; }
      var newCol = $current.column + 1;
      var $new = datagrid.cells[$current.row + ',' + newCol];
      while($new && $new.hidden) {
        newCol++;
        $new = datagrid.cells[$current.row + ',' + newCol];
      }
      if(!$new || $new.length === 0) {
        $new = $current;
      }
      $new.trigger('mouseover').focus();
      datagrid.currentHover = $new;
      datagrid.scrollTo($new.row, $new.column);
    },
    moveUp: function() {
      var $current = datagrid.currentHover;
      if(!datagrid.currentHover) { datagrid._selectFirstCell(); return; }
      var newRow = $current.row - 1;
      var $new = datagrid.cells[newRow + ',' + $current.column];
      while($new && $new.hidden) {
        newRow--;
        $new = datagrid.cells[newRow + ',' + $current.column];
      }
      if(!$new || $new.length === 0) {
        $new = $current;
      }
      $new.trigger('mouseover').focus();
      datagrid.currentHover = $new;
      datagrid.scrollTo($new.row, $new.column);
    },
    moveDown: function() {
      var $current = datagrid.currentHover;
      if(!datagrid.currentHover) { datagrid._selectFirstCell(); return; }
      var newRow = $current.row + 1;
      var $new = datagrid.cells[newRow + ',' + $current.column];
      while($new && $new.hidden) {
        newRow++;
        $new = datagrid.cells[newRow + ',' + $current.column];
      }
      if(!$new || $new.length === 0) {
        $new = $current;
      }
      $new.trigger('mouseover').focus();
      datagrid.currentHover = $new;
      datagrid.scrollTo($new.row, $new.column);
    }
  }

  return datagrid;
});
