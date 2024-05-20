/* eslint-disable linebreak-style */
/* eslint-disable no-loop-func */
/* eslint-disable eslint-comments/no-duplicate-disable */
/* eslint-disable no-eval */
/* eslint-disable linebreak-style */
/* eslint-disable no-empty */
/* eslint-disable @typescript-eslint/no-redeclare */
/* eslint-disable no-useless-concat */
/* eslint-disable no-bitwise */
/* eslint-disable radix */
/* eslint-disable linebreak-style */
/* eslint-disable no-func-assign */
/* eslint-disable no-undef */
/* eslint-disable block-scoped-var */
/* eslint-disable no-var */
/* eslint-disable prettier/prettier */
/* eslint-disable no-throw-literal */
/* eslint-disable linebreak-style */
/* eslint-disable vars-on-top */
/* eslint-disable  no-constant-condition */
/*
 * Copyright (c) 2010 Michael Leibman, http://github.com/mleibman/slickgrid
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import $ from 'jquery'
import './slick.core'
import './jquery.event.drag-2.2'
import {isRTL} from '@canvas/i18n/rtlHelper'
import {getNormalizedScrollLeft, setNormalizedScrollLeft} from 'normalize-scroll-left'
import 'jqueryui/sortable'

/*
 * These eslint configurations are just becase that's how this file was
 * originally written and we want the file to remain as much like the original
 * source as possible but still want it to tell us about the important stuff.
 */

/* eslint linebreak-style: ["error", "windows"] */

/**
 * @license
 * (c) 2009-2013 Michael Leibman
 * michael{dot}leibman{at}gmail{dot}com
 * http://github.com/mleibman/slickgrid
 *
 * Distributed under MIT license.
 * All rights reserved.
 *
 * SlickGrid v2.2
 *
 * NOTES:
 *     Cell/row DOM manipulations are done directly bypassing jQuery's DOM manipulation methods.
 *     This increases the speed dramatically, but can only be done safely because there are no event handlers
 *     or data associated with any cell/row DOM nodes.  Cell editors must make sure they implement .destroy()
 *     and do proper cleanup.
 */

// make sure required JavaScript modules are loaded
if (typeof $ === 'undefined') {
  throw 'SlickGrid requires jquery module to be loaded'
}
if (!$.fn.drag) {
  throw 'SlickGrid requires jquery.event.drag module to be loaded'
}
if (typeof Slick === 'undefined') {
  throw 'slick.core.js not loaded'
}

  // Slick.Grid
  $.extend(true, window, {
    Slick: {
      Grid: SlickGrid,
    },
  })

  // shared across all grids on the page
  var scrollbarDimensions
  var maxSupportedCssHeight // browser's breaking point

  // ////////////////////////////////////////////////////////////////////////////////////////////
  // SlickGrid class implementation (available as Slick.Grid)

  /**
   * Creates a new instance of the grid.
   * @class SlickGrid
   * @constructor
   * @param {Node}              container   Container node to create the grid in.
   * @param {Array,Object}      data        An array of objects for databinding.
   * @param {Array}             columns     An array of column definitions.
   * @param {Object}            options     Grid options.
   * */
  function SlickGrid(container, data, columns, options) {
    // settings
    var defaults = {
      explicitInitialization: false,
      rowHeight: 25,
      defaultColumnWidth: 80,
      enableAddRow: false,
      leaveSpaceForNewRows: false,
      editable: false,
      autoEdit: true,
      enableCellNavigation: true,
      enableColumnReorder: true,
      asyncEditorLoading: false,
      asyncEditorLoadDelay: 100,
      forceFitColumns: false,
      enableAsyncPostRender: false,
      asyncPostRenderDelay: 50,
      autoHeight: false,
      editorLock: Slick.GlobalEditorLock,
      showHeaderRow: false,
      headerRowHeight: 25,
      showTopPanel: false,
      topPanelHeight: 25,
      formatterFactory: null,
      editorFactory: null,
      cellFlashingCssClass: 'flashing',
      selectedCellCssClass: 'selected',
      multiSelect: true,
      enableTextSelectionOnCells: false,
      dataItemColumnValueExtractor: null,
      fullWidthRows: false,
      multiColumnSort: false,
      defaultFormatter,
      forceSyncScrolling: false,
      numberOfColumnsToFreeze: 0, // Number of left-most columns to freeze from scrolling
    }

    var columnDefaults = {
      name: '',
      resizable: true,
      sortable: false,
      minWidth: 30,
      rerenderOnResize: false,
      headerCssClass: null,
      defaultSortAsc: true,
      focusable: true,
      selectable: true,
    }

    // scroller
    var th // virtual height
    var h // real scrollable height
    var ph // page height
    var n // number of pages
    var cj // "jumpiness" coefficient

    var page = 0 // current page
    var offset = 0 // current page offset
    var vScrollDir = 1

    // private
    var initialized = false
    var uid = 'slickgrid_' + Math.round(1000000 * Math.random())
    var self = this
    var $focusSink, $focusSink2

    var $outerContainer
    var $container_0
    var $container_1
    var $headerScroller_0
    var $headerScroller_1
    var $headers_0
    var $headers_1
    var $headerRow_0
    var $headerRow_1
    var $headerRowScroller_0
    var $headerRowScroller_1
    var $headerRowSpacer_0
    var $headerRowSpacer_1
    var $topPanelScroller_0
    var $topPanelScroller_1
    var $topPanel_0
    var $topPanel_1
    var $viewport_0
    var $viewport_1
    var $canvas_0
    var $canvas_1
    var canvasWidth_0
    var canvasWidth_1

    var $style
    var $boundAncestors
    var stylesheet, columnCssRulesB, columnCssRulesF
    var viewportH_1
    var viewportW_1

    var viewportHasHScroll_1
    var viewportHasVScroll_1
    // viewport_0 will never have scroll bars so the above two vars are only necessary for viewport_1.
    var headerColumnWidthDiff = 0,
      headerColumnHeightDiff = 0, // border+padding
      cellWidthDiff = 0,
      cellHeightDiff = 0
    var absoluteColumnMinWidth
    var numberOfRows = 0

    var tabbingDirection = 1
    var activePosX
    var activeRow, activeCell
    var activeCellNode = null
    var currentEditor = null
    var serializedEditorValue
    var editController

    var rowsCache = {}
    var renderedRows = 0
    var numVisibleRows
    var prevScrollTop = 0
    var scrollTop = 0
    var lastRenderedScrollTop = 0
    var lastRenderedScrollLeft = 0
    var prevScrollLeft = 0
    var scrollLeft = 0

    var selectionModel
    var selectedRows = []

    var plugins = []
    var cellCssClasses = {}

    var columnsById = {}
    var sortColumns = []
    var columnPosRear = []
    var columnPosFront = []

    // async call handles
    var h_editorLoader = null
    var h_render = null
    var h_postrender = null
    var postProcessedRows = {}
    var postProcessToRow = null
    var postProcessFromRow = null

    // perf counters
    var counter_rows_rendered = 0
    var counter_rows_removed = 0

    var rtl = false
    var rear = 'left'
    var front = 'right'
    var gotoRight
    var gotoLeft
    var getOffsetRear

    // ////////////////////////////////////////////////////////////////////////////////////////////
    // Initialization

    function init() {
      $outerContainer = $(container)
      $container_1 = $outerContainer
      if ($outerContainer.length < 1) {
        throw new Error(
          'SlickGrid requires a valid container, ' + container + ' does not exist in the DOM.'
        )
      }

      // calculate these only once and share between grid instances
      maxSupportedCssHeight = maxSupportedCssHeight || getMaxSupportedCssHeight()
      scrollbarDimensions = scrollbarDimensions || measureScrollbar()

      options = $.extend({}, defaults, options)
      validateAndEnforceOptions()
      columnDefaults.width = options.defaultColumnWidth

      columnsById = {}
      for (var i = 0; i < columns.length; i++) {
        var m = (columns[i] = $.extend({}, columnDefaults, columns[i]))
        columnsById[m.id] = i
        if (m.minWidth && m.width < m.minWidth) {
          m.width = m.minWidth
        }
        if (m.maxWidth && m.width > m.maxWidth) {
          m.width = m.maxWidth
        }
      }

      // validate loaded JavaScript modules against requested options
      if (options.enableColumnReorder && !$.fn.sortable) {
        throw new Error(
          "SlickGrid's 'enableColumnReorder = true' option requires jquery-ui.sortable module to be loaded"
        )
      }

      editController = {
        commitCurrentEdit,
        cancelCurrentEdit,
      }

      $outerContainer
        .empty()
        .css('overflow', 'hidden')
        .css('outline', 0)
        .addClass(uid)
        .addClass('ui-widget')
      $container_1
        .empty()
        .css('overflow', 'hidden')
        .css('outline', 0)
        .addClass(uid)
        .addClass('ui-widget')

      if (isRTL($outerContainer[0])) {
        rtl = true
        rear = 'right'
        front = 'left'
        gotoRight = gotoRear
        gotoLeft = gotoFront
        getOffsetRear = getOffsetRight
        getScrollLeft = el => getNormalizedScrollLeft(el, 'rtl')
        setScrollLeft = (el, val) => setNormalizedScrollLeft(el, val, 'rtl')
        $container_1.css('overflow', 'visible')
      }

      // set up a positioning container if needed
      if (!/relative|absolute|fixed/.test($outerContainer.css('position'))) {
        $outerContainer.css('position', 'relative')
      }
      // set up a positioning container if needed
      if (!/relative|absolute|fixed/.test($container_1.css('position'))) {
        $container_1.css('position', 'relative')
      }

      $focusSink = $(
        "<div tabIndex='0' hideFocus style='position:fixed;width:0;height:0;top:0;left:0;outline:0;'></div>"
      ).appendTo($outerContainer)

      // FreezeColumns - Add outerContainer and frozen column structure - Begin
      if (options.numberOfColumnsToFreeze > 0) {
        var totalWidthOfFrozenColumns = 0
        var container_1Width = 0
        var containerCSS = {
          overflow: 'hidden',
          position: 'absolute',
          [rear]: 0,
          top: 0,
          bottom: 0,
          outline: 0,
        }
        var containerClass = uid + ' ui-widget'
        // Calculate frozen widths
        for (var i = 0, len = columns.length; i < len; i++) {
          if (i < options.numberOfColumnsToFreeze) {
            totalWidthOfFrozenColumns += columns[i].width
          } else {
            break
          }
        }
        $container_0 = $("<div class='container_0'></div>")
          .css($.extend({}, containerCSS, {width: totalWidthOfFrozenColumns}))
          .addClass(containerClass)
          .appendTo($outerContainer)
        $container_1 = $("<div class='container_1'></div>")
          .css($.extend({}, containerCSS, {[rear]: totalWidthOfFrozenColumns, [front]: 0}))
          .addClass(containerClass)
          .appendTo($outerContainer)

        $headerScroller_0 = $(
          "<div class='headerScroller_0 slick-header ui-state-default' style='overflow:hidden;position:relative;' />"
        ).appendTo($container_0)
        $headers_0 = $(
          "<div class='headers_0 slick-header-columns' style='" + rear + ":-1000px' />"
        ).appendTo($headerScroller_0)

        $headerRowScroller_0 = $(
          "<div class='headerRowScroller_0 slick-headerrow ui-state-default' style='overflow:hidden;position:relative;' />"
        ).appendTo($container_0)
        $headerRow_0 = $("<div class='headerRow_0 slick-headerrow-columns' />").appendTo(
          $headerRowScroller_0
        )
        $headerRowSpacer_0 = $(
          "<div class='headerRowSpacer_0' style='display:block;height:1px;position:absolute;top:0;left:0;'></div>"
        ).appendTo($headerRowScroller_0)

        $topPanelScroller_0 = $(
          "<div class='topPanelScroller_0 slick-top-panel-scroller ui-state-default' style='overflow:hidden;position:relative;' />"
        ).appendTo($container_0)
        $topPanel_0 = $(
          "<div class='topPanel_0 slick-top-panel' style='width:10000px' />"
        ).appendTo($topPanelScroller_0)

        if (!options.showTopPanel) {
          $topPanelScroller_0.hide()
        }

        if (!options.showHeaderRow) {
          $headerRowScroller_0.hide()
        }

        $viewport_0 = $(
          "<div class='viewport_0 slick-viewport' style='width:100%;overflow:hidden;outline:0;position:relative;'>"
        ).appendTo($container_0)
        $canvas_0 = $("<div class='canvas_0 grid-canvas' />").appendTo($viewport_0)
      }
      // FreezeColumns - Add outerContainer and frozen column structure - End
      $headerScroller_1 = $(
        "<div class='headerScroller_1 slick-header ui-state-default' style='overflow:hidden;position:relative;' />"
      ).appendTo($container_1)
      if (isRTL($outerContainer[0])) {
        $headers_1 = $("<div class='headers_1 slick-header-columns' />").appendTo($headerScroller_1)
      } else {
        $headers_1 = $(
          "<div class='headers_1 slick-header-columns' style='" + rear + ":-1000px' />"
        ).appendTo($headerScroller_1)
      }

      // FreezeColumns - Set width of headers - Begin
      var headersWidthObj = getHeadersWidth()
      if (options.numberOfColumnsToFreeze > 0) {
        $headers_0.width(headersWidthObj.frozen + 1000)
        $headers_1.width(headersWidthObj.nonFrozen)
      } else {
        $headers_1.width(headersWidthObj.nonFrozen)
      }
      // FreezeColumns - Set width of headers - End

      $headerRowScroller_1 = $(
        "<div class='headerRowScroller_1 slick-headerrow ui-state-default' style='overflow:hidden;position:relative;' />"
      ).appendTo($container_1)
      $headerRow_1 = $("<div class='headerRow_1 slick-headerrow-columns' />").appendTo(
        $headerRowScroller_1
      )
      $headerRowSpacer_1 = $(
        "<div class='headerRowSpacer_1' style='display:block;height:1px;position:absolute;top:0;left:0;'></div>"
      ).appendTo($headerRowScroller_1)

      // FreezeColumns - Set width of header row spacer - Begin
      var canvasWidthObj = getCanvasWidth()
      $headerRowSpacer_1.css('width', canvasWidthObj.nonFrozen + scrollbarDimensions.width + 'px')
      if (options.numberOfColumnsToFreeze > 0) {
        $headerRowSpacer_0.css('width', canvasWidthObj.frozen + 'px')
      }
      // FreezeColumns - Set width of header row spacer - End

      $topPanelScroller_1 = $(
        "<div class='topPanelScroller_1 slick-top-panel-scroller ui-state-default' style='overflow:hidden;position:relative;' />"
      ).appendTo($container_1)
      $topPanel_1 = $("<div class='topPanel_1 slick-top-panel' style='width:10000px' />").appendTo(
        $topPanelScroller_1
      )

      if (!options.showTopPanel) {
        $topPanelScroller_1.hide()
      }

      if (!options.showHeaderRow) {
        $headerRowScroller_1.hide()
      }

      $viewport_1 = $(
        "<div class='viewport_1 slick-viewport' style='width:100%;overflow:auto;outline:0;position:relative;'>"
      ).appendTo($container_1)
      $viewport_1.css('overflow-y', options.autoHeight ? 'hidden' : 'auto')

      $canvas_1 = $("<div class='canvas_1 grid-canvas' />").appendTo($viewport_1)

      $focusSink2 = $focusSink.clone().appendTo($outerContainer)

      if (!options.explicitInitialization) {
        finishInitialization()
      }
    }

    function finishInitialization() {
      if (!initialized) {
        initialized = true

        viewportW_1 = parseFloat($.css($outerContainer[0], 'width', true))

        // header columns and cells may have different padding/border skewing width calculations (box-sizing, hello?)
        // calculate the diff so we can set consistent sizes
        measureCellPaddingAndBorder()

        // for usability reasons, all text selection in SlickGrid is disabled
        // with the exception of input and textarea elements (selection must
        // be enabled there so that editors work as expected); note that
        // selection in grid cells (grid body) is already unavailable in
        // all browsers except IE
        disableSelection($headers_1) // disable all text selection in header (including input and textarea)

        if (!options.enableTextSelectionOnCells) {
          // disable text selection in grid cells except in input and textarea elements
          // (this is IE-specific, because selectstart event will only fire in IE)
          $viewport_1.bind('selectstart.ui', event => $(event.target).is('input,textarea'))
        }

        updateColumnCaches()
        createColumnHeaders()
        setupColumnSort()
        createCssRules()
        resizeCanvas()
        bindAncestorScrollEvents()

        $outerContainer.bind('resize.slickgrid', resizeCanvas)
        $container_1.bind('resize.slickgrid', resizeCanvas)
        $viewport_1.bind('scroll', handleScroll).bind('click', handleClick)
        $headerScroller_1
          .bind('contextmenu', handleHeaderContextMenu)
          .bind('click', handleHeaderClick)
          .on('mouseenter', '.slick-header-column', handleHeaderMouseEnter)
          .on('mouseleave', '.slick-header-column', handleHeaderMouseLeave)
        $headerRowScroller_1.bind('scroll', handleHeaderRowScroll)
        $focusSink.add($focusSink2).bind('keydown', handleKeyDown)
        $canvas_1
          .bind('keydown', handleKeyDown)
          .bind('click', handleClick)
          .bind('dblclick', handleDblClick)
          .bind('contextmenu', handleContextMenu)
          .bind('draginit', handleDragInit)
          .bind('dragstart', {distance: 3}, handleDragStart)
          .bind('drag', handleDrag)
          .bind('dragend', handleDragEnd)
          .on('mouseenter', '.slick-cell', handleMouseEnter)
          .on('mouseleave', '.slick-cell', handleMouseLeave)

        if (options.numberOfColumnsToFreeze > 0) {
          $container_0.bind('resize.slickgrid', resizeCanvas)
          $viewport_0.bind('mousewheel', e => {
            var wheelDelta = e.originalEvent.wheelDelta
            var newScrollTop = scrollTop - wheelDelta
            if (newScrollTop < 0) {
              newScrollTop = 0
            }
            handleScroll({wheelDelta, scrollTop: newScrollTop})
          })
          $headerScroller_0
            .bind('contextmenu', handleHeaderContextMenu)
            .bind('click', handleHeaderClick)
            .on('mouseenter', '.slick-header-column', handleHeaderMouseEnter)
            .on('mouseleave', '.slick-header-column', handleHeaderMouseLeave)
          $headerRowScroller_0.bind('scroll', handleHeaderRowScroll)
          $canvas_0
            .bind('keydown', handleKeyDown)
            .bind('click', handleClick)
            .bind('dblclick', handleDblClick)
            .bind('contextmenu', handleContextMenu)
            .bind('draginit', handleDragInit)
            .bind('dragstart', {distance: 3}, handleDragStart)
            .bind('drag', handleDrag)
            .bind('dragend', handleDragEnd)
            .on('mouseenter', '.slick-cell', handleMouseEnter)
            .on('mouseleave', '.slick-cell', handleMouseLeave)
        }
      }
    }

    function registerPlugin(plugin) {
      plugins.unshift(plugin)
      plugin.init(self)
    }

    function unregisterPlugin(plugin) {
      for (var i = plugins.length; i >= 0; i--) {
        if (plugins[i] === plugin) {
          if (plugins[i].destroy) {
            plugins[i].destroy()
          }
          plugins.splice(i, 1)
          break
        }
      }
    }

    function setSelectionModel(model) {
      if (selectionModel) {
        selectionModel.onSelectedRangesChanged.unsubscribe(handleSelectedRangesChanged)
        if (selectionModel.destroy) {
          selectionModel.destroy()
        }
      }

      selectionModel = model
      if (selectionModel) {
        selectionModel.init(self)
        selectionModel.onSelectedRangesChanged.subscribe(handleSelectedRangesChanged)
      }
    }

    function getSelectionModel() {
      return selectionModel
    }

    function getCanvasNode(nodeClassName) {
      // TODO: SFA: This is the entry point into fixing the row reordering style issue
      var canvasNode = $canvas_1[0] // Original code
      // New code not yet complete
      // if(nodeClassName != undefined){
      //  canvasNode = {"frozen": $canvas_0[0],
      //                "nonFrozen": $canvas_1[0]
      //               };
      // }
      return canvasNode
    }

    function measureScrollbar() {
      var $c = $(
        "<div style='position:absolute; top:-10000px; left:-10000px; width:100px; height:100px; overflow:scroll;'></div>"
      ).appendTo('body')
      var dim = {
        width: $c.width() - $c[0].clientWidth,
        height: $c.height() - $c[0].clientHeight,
      }
      $c.remove()
      return dim
    }

    function getHeadersWidth() {
      var headersWidth_0 = 0
      var headersWidth_1 = 0
      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
      for (var i = 0, ii = columns.length; i < ii; i++) {
        var width = columns[i].width
        if (i < numberOfColumnsToFreeze) {
          headersWidth_0 += width
        } else {
          headersWidth_1 += width
        }
      }
      headersWidth_0 += 1000
      headersWidth_1 += scrollbarDimensions.width
      headersWidth_1 = Math.max(headersWidth_1, viewportW_1) + 1000
      return {frozen: headersWidth_0, nonFrozen: headersWidth_1}
    }

    function getCanvasWidth() {
      var availableWidth = viewportHasVScroll_1
        ? viewportW_1 - scrollbarDimensions.width
        : viewportW_1
      var rowWidth_0 = 0
      var rowWidth_1 = 0
      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
      var i = columns.length
      while (i--) {
        var colWidth = columns[i].width
        if (i < numberOfColumnsToFreeze) {
          rowWidth_0 += colWidth
        } else {
          rowWidth_1 += colWidth
        }
      }
      rowWidth_1 = options.fullWidthRows ? Math.max(rowWidth_1, availableWidth) : rowWidth_1
      return {frozen: rowWidth_0, nonFrozen: rowWidth_1}
    }

    function updateCanvasWidth(forceColumnWidthsUpdate) {
      var oldCanvasWidth_0 = canvasWidth_0
      var oldCanvasWidth_1 = canvasWidth_1

      var newCanvasWidth = getCanvasWidth()
      canvasWidth_0 = newCanvasWidth.frozen
      canvasWidth_1 = newCanvasWidth.nonFrozen

      // FreezeColumns - Handle left and main canvas widths
      var headersWidthObj = getHeadersWidth()
      var canvasWidthDelta_0 = 0
      if (options.numberOfColumnsToFreeze > 0 && canvasWidth_0 != oldCanvasWidth_0) {
        $canvas_0.width(canvasWidth_0)
        $headerRow_0.width(canvasWidth_0)
        $headers_0.width(headersWidthObj.frozen)
        $headerRowSpacer_0.width(canvasWidth_0)
        if (oldCanvasWidth_0 != undefined) {
          canvasWidthDelta_0 = canvasWidth_0 - oldCanvasWidth_0
          canvasWidth_1 -= canvasWidthDelta_0
          viewportW_1 -= canvasWidthDelta_0
          $container_0[0].style.width =
            parseInt($container_0[0].style.width) + canvasWidthDelta_0 + 'px'
          $container_1[0].style[rear] = canvasWidth_0 + 'px'
          $container_1[0].style.width =
            parseInt($container_1[0].style.width) - canvasWidthDelta_0 + 'px'
        }
      }
      if (canvasWidth_1 != oldCanvasWidth_1 || canvasWidthDelta_0 != 0) {
        $canvas_1.width(canvasWidth_1)
        $headerRow_1.width(canvasWidth_1)
        $headers_1.width(headersWidthObj.nonFrozen)
        viewportHasHScroll_1 = canvasWidth_1 > viewportW_1 - scrollbarDimensions.width
      }
      $headerRowSpacer_1.width(
        canvasWidth_1 + (viewportHasVScroll_1 ? scrollbarDimensions.width : 0)
      )

      if (canvasWidth_1 != oldCanvasWidth_1 || forceColumnWidthsUpdate || canvasWidthDelta_0 != 0) {
        applyColumnWidths()
      }
    }

    function disableSelection($target) {
      if ($target && $target.jquery) {
        $target
          .attr('unselectable', 'on')
          .css('MozUserSelect', 'none')
          .bind('selectstart.ui', () => false) // from jquery:ui.core.js 1.7.2
      }
    }

    function getMaxSupportedCssHeight() {
      var supportedHeight = 1000000
      // FF reports the height back but still renders blank after ~6M px
      var testUpTo = navigator.userAgent.toLowerCase().match(/firefox/) ? 6000000 : 1000000000
      var div = $("<div style='display:none' />").appendTo(document.body)

      while (true) {
        var test = supportedHeight * 2
        div.css('height', test)
        if (test > testUpTo || div.height() !== test) {
          break
        } else {
          supportedHeight = test
        }
      }

      div.remove()
      return supportedHeight
    }

    // TODO:  this is static.  need to handle page mutation.
    function bindAncestorScrollEvents() {
      var elem = $canvas_1[0]
      while ((elem = elem.parentNode) != document.body && elem != null) {
        // bind to scroll containers only
        if (
          elem == $viewport_1[0] ||
          elem.scrollWidth != elem.clientWidth ||
          elem.scrollHeight != elem.clientHeight
        ) {
          var $elem = $(elem)
          if (!$boundAncestors) {
            $boundAncestors = $elem
          } else {
            $boundAncestors = $boundAncestors.add($elem)
          }
          $elem.bind('scroll.' + uid, handleActiveCellPositionChange)
        }
      }
    }

    function unbindAncestorScrollEvents() {
      if (!$boundAncestors) {
        return
      }
      $boundAncestors.unbind('scroll.' + uid)
      $boundAncestors = null
    }

    function updateColumnHeader(columnId, title, toolTip) {
      if (!initialized) {
        return
      }
      var idx = getColumnIndex(columnId)
      if (idx == null) {
        return
      }

      var columnDef = columns[idx]
      let $header

      if (options.numberOfColumnsToFreeze > 0) {
        if (options.numberOfColumnsToFreeze > idx) {
          $header = $headers_0.children().eq(idx)
        } else {
          $header = $headers_1.children().eq(idx - options.numberOfColumnsToFreeze)
        }
      }

      if ($header) {
        if (title !== undefined) {
          columns[idx].name = title
        }
        if (toolTip !== undefined) {
          columns[idx].toolTip = toolTip
        }

        trigger(self.onBeforeHeaderCellDestroy, {
          node: $header[0],
          column: columnDef,
        })

        $header
          .attr('title', toolTip || '')
          .children()
          .eq(0)
          .html(title)

        trigger(self.onHeaderCellRendered, {
          node: $header[0],
          column: columnDef,
        })
      }
    }

    function getHeaderRow() {
      return $headerRow_1[0]
    }

    function getColumnHeaderNode(columnId) {
      var idx = getColumnIndex(columnId)
      // FreezeColumn - Combine frozen and nonFrozen side header row objects
      var $headersObject
      if (!options.numberOfColumnsToFreeze) {
        $headersObject = $headers_1
      } else {
        // Combine frozen and nonFrozen
        $headersObject = $($.merge($.merge([], $headers_0), $headers_1))
      }
      var $header = $headersObject.children().eq(idx)
      return $header && $header[0]
    }

    function getHeaderRowColumn(columnId) {
      var idx = getColumnIndex(columnId)
      // FreezeColumn - Combine frozen and nonFrozen side header row objects
      var $headerRowObject
      if (!options.numberOfColumnsToFreeze) {
        $headerRowObject = $headerRow_1
      } else {
        // Combine frozen and nonFrozen
        $headerRowObject = $($.merge($.merge([], $headerRow_0), $headerRow_1))
      }
      var $header = $headerRowObject.children().eq(idx)
      return $header && $header[0]
    }

    function createColumnHeaders() {
      function onMouseEnter() {
        $(this).addClass('ui-state-hover')
      }

      function onMouseLeave() {
        $(this).removeClass('ui-state-hover')
      }

      $headers_1.find('.slick-header-column').each(function () {
        var columnDef = $(this).data('column')
        if (columnDef) {
          trigger(self.onBeforeHeaderCellDestroy, {
            node: this,
            column: columnDef,
          })
        }
      })
      $headers_1.empty()
      var headersWidthObj = getHeadersWidth()
      $headers_1.width(headersWidthObj.nonFrozen)

      // FreezeColumns - handle header empty
      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
      if (numberOfColumnsToFreeze > 0) {
        $headers_0.empty()
        $headers_0.width(headersWidthObj.frozen)
      }

      // FreezeColumns - handle header row empty
      var $headerRowObject
      $headerRowObject = $headerRow_1
      if (numberOfColumnsToFreeze > 0) {
        // Combine frozen and nonFrozen
        $headerRowObject = $($.merge($.merge([], $headerRow_0), $headerRow_1))
      }
      $headerRowObject.find('.slick-headerrow-column').each(function () {
        var columnDef = $(this).data('column')
        if (columnDef) {
          trigger(self.onBeforeHeaderRowCellDestroy, {
            node: this,
            column: columnDef,
          })
        }
      })
      $headerRowObject.empty()

      for (var i = 0; i < columns.length; i++) {
        var m = columns[i]

        var header = $("<div class='ui-state-default slick-header-column' />")
          .html("<span class='slick-column-name'>" + m.name + '</span>')
          .width(m.width - headerColumnWidthDiff)
          .attr('id', '' + uid + m.id)
          .attr('title', m.toolTip || '')
          .data('column', m)
          .addClass(m.headerCssClass || '')
          .appendTo(i < numberOfColumnsToFreeze ? $headers_0 : $headers_1)

        if (options.enableColumnReorder || m.sortable) {
          header.on('mouseenter', onMouseEnter).on('mouseleave', onMouseLeave)
        }

        if (m.sortable) {
          header.addClass('slick-header-sortable')
          header.append("<span class='slick-sort-indicator' />")
        }

        trigger(self.onHeaderCellRendered, {
          node: header[0],
          column: m,
        })

        if (options.showHeaderRow) {
          var headerRowCell = $(
            "<div class='ui-state-default slick-headerrow-column b" + i + ' f' + i + "'></div>"
          )
            .data('column', m)
            .appendTo(i < numberOfColumnsToFreeze ? $headerRow_0 : $headerRow_1)

          trigger(self.onHeaderRowCellRendered, {
            node: headerRowCell[0],
            column: m,
          })
        }
      }

      setSortColumns(sortColumns)
      setupColumnResize()
      if (options.enableColumnReorder) {
        setupColumnReorder()
      }
    }

    function setupColumnSort() {
      $headers_1.add(options.numberOfColumnsToFreeze ? $headers_0 : null).click(e => {
        // temporary workaround for a bug in jQuery 1.7.1 (http://bugs.jquery.com/ticket/11328)
        e.metaKey = e.metaKey || e.ctrlKey

        if ($(e.target).hasClass('slick-resizable-handle')) {
          return
        }

        var $col = $(e.target).closest('.slick-header-column')
        if (!$col.length) {
          return
        }

        var column = $col.data('column')
        if (column.sortable) {
          if (!getEditorLock().commitCurrentEdit()) {
            return
          }

          var sortOpts = null
          var i = 0
          for (; i < sortColumns.length; i++) {
            if (sortColumns[i].columnId == column.id) {
              sortOpts = sortColumns[i]
              sortOpts.sortAsc = !sortOpts.sortAsc
              break
            }
          }

          if (e.metaKey && options.multiColumnSort) {
            if (sortOpts) {
              sortColumns.splice(i, 1)
            }
          } else {
            if ((!e.shiftKey && !e.metaKey) || !options.multiColumnSort) {
              sortColumns = []
            }

            if (!sortOpts) {
              sortOpts = {columnId: column.id, sortAsc: column.defaultSortAsc}
              sortColumns.push(sortOpts)
            } else if (sortColumns.length == 0) {
              sortColumns.push(sortOpts)
            }
          }

          setSortColumns(sortColumns)

          if (!options.multiColumnSort) {
            trigger(
              self.onSort,
              {
                multiColumnSort: false,
                sortCol: column,
                sortAsc: sortOpts.sortAsc,
              },
              e
            )
          } else {
            trigger(
              self.onSort,
              {
                multiColumnSort: true,
                sortCols: $.map(sortColumns, col => ({
                  sortCol: columns[getColumnIndex(col.columnId)],
                  sortAsc: col.sortAsc,
                })),
              },
              e
            )
          }
        }
      })
    }

    function setupColumnReorder() {
      const sortableHeaderGroups = [$headers_1]
      if (options.numberOfColumnsToFreeze > 0) sortableHeaderGroups.push($headers_0)
      sortableHeaderGroups.forEach($headers => {
        $headers.filter(':ui-sortable').sortable('destroy')
        $headers.sortable({
          containment: 'parent',
          distance: 3,
          axis: 'x',
          cursor: 'default',
          tolerance: 'intersection',
          helper: 'clone',
          placeholder: 'slick-sortable-placeholder ui-state-default slick-header-column',
          forcePlaceholderSize: true,
          start (e, ui) {
            ui.placeholder.width(ui.helper.outerWidth() - headerColumnWidthDiff)
            $(ui.helper).addClass('slick-header-column-active')
          },
          beforeStop (e, ui) {
            $(ui.helper).removeClass('slick-header-column-active')
          },
          stop (e) {
            if (!getEditorLock().commitCurrentEdit()) {
              $(this).sortable('cancel')
              return
            }
            var reorderedIds = $headers.sortable('toArray')
            var reorderedColumns = []

            // handle the reordering
            for (var i = 0; i < reorderedIds.length; i++) {
              var reorderedIndex = reorderedIds[i].replace(uid, '')
              var columnIndex = getColumnIndex(reorderedIndex)
              var thingToPush = columns[columnIndex]
              reorderedColumns.push(thingToPush)
            }

            // Preserve the other (frozen/nonfrozen) set of columns
            reorderedColumns =
              $headers === $headers_1
                ? [...columns.slice(0, options.numberOfColumnsToFreeze), ...reorderedColumns]
                : [...reorderedColumns, ...columns.slice(options.numberOfColumnsToFreeze)]

            setColumns(reorderedColumns)

            trigger(self.onColumnsReordered, {})
            e.stopPropagation()
            setupColumnResize()
          },
        })
      })
    }

    function setupColumnResize() {
      var $col, j, c, pageX, columnElements, minPageX, maxPageX, firstResizable, lastResizable
      var isFrozenColumn
      var headerElements = []
      if (options.numberOfColumnsToFreeze > 0) {
        headerElements.push($headers_0.children())
      }
      headerElements.push($headers_1.children())

      for (var h = 0; h < headerElements.length; h++) {
        columnElements = headerElements[h]
        isFrozenColumn = isPartOfAFrozenColumn(columnElements)

        columnElements.find('.slick-resizable-handle').remove()
        columnElements.each((i, e) => {
          var columnIndex = getIndexOffset(isFrozenColumn, i)
          if (columns[columnIndex].resizable) {
            if (firstResizable === undefined) {
              firstResizable = i
            }
            lastResizable = i
          }
        })
        if (firstResizable === undefined) {
          return
        }
        columnElements.each((i, e) => {
          if (i < firstResizable || (options.forceFitColumns && i >= lastResizable)) {
            return
          }
          $col = $(e)
          $("<div class='slick-resizable-handle' />")
            .appendTo(e)
            .on('dragstart', function (e, dd) {
              setTimeout(() => {
              isFrozenColumn = isPartOfAFrozenColumn(this)
              columnElements = getColumnElements(this)
              if (!getEditorLock().commitCurrentEdit()) {
                return false
              }
              pageX = e.pageX
              $(this).parent().addClass('slick-header-column-active')
              var shrinkLeewayOnFront = null,
                stretchLeewayOnFront = null
              // lock each column's width option to current width
              columnElements.each((i, e) => {
                var columnIndex = getIndexOffset(isFrozenColumn, i)
                columns[columnIndex].previousWidth = $(e).outerWidth()
              })
              if (options.forceFitColumns) {
                shrinkLeewayOnFront = 0
                stretchLeewayOnFront = 0
                // colums on front affect maxPageX/minPageX
                var nextColumnIndex
                for (j = i + 1; j < columnElements.length; j++) {
                  nextColumnIndex = getIndexOffset(isFrozenColumn, j)
                  c = columns[nextColumnIndex]
                  if (c.resizable) {
                    if (stretchLeewayOnFront !== null) {
                      if (c.maxWidth) {
                        stretchLeewayOnFront += c.maxWidth - c.previousWidth
                      } else {
                        stretchLeewayOnFront = null
                      }
                    }
                    shrinkLeewayOnFront +=
                      c.previousWidth - Math.max(c.minWidth || 0, absoluteColumnMinWidth)
                  }
                }
              }
              var shrinkLeewayOnRear = 0,
                stretchLeewayOnRear = 0
              for (j = 0; j <= i; j++) {
                // columns on rear only affect minPageX
                var columnIndex = getIndexOffset(isFrozenColumn, j)
                c = columns[columnIndex]
                if (c.resizable) {
                  if (stretchLeewayOnRear !== null) {
                    if (c.maxWidth) {
                      stretchLeewayOnRear += c.maxWidth - c.previousWidth
                    } else {
                      stretchLeewayOnRear = null
                    }
                  }
                  shrinkLeewayOnRear +=
                    c.previousWidth - Math.max(c.minWidth || 0, absoluteColumnMinWidth)
                }
              }
              if (shrinkLeewayOnFront === null) {
                shrinkLeewayOnFront = 100000
              }
              if (shrinkLeewayOnRear === null) {
                shrinkLeewayOnRear = 100000
              }
              if (stretchLeewayOnFront === null) {
                stretchLeewayOnFront = 100000
              }
              if (stretchLeewayOnRear === null) {
                stretchLeewayOnRear = 100000
              }
              if (rtl) {
                maxPageX = pageX - Math.min(shrinkLeewayOnFront, stretchLeewayOnRear)
                minPageX = pageX + Math.min(shrinkLeewayOnRear, stretchLeewayOnFront)
              } else {
                maxPageX = pageX + Math.min(shrinkLeewayOnFront, stretchLeewayOnRear)
                minPageX = pageX - Math.min(shrinkLeewayOnRear, stretchLeewayOnFront)
              }
              }, 0)
            })
            .on('drag', function (e, dd) {
              setTimeout(() => {
                isFrozenColumn = isPartOfAFrozenColumn(this)
                columnElements = getColumnElements(this)
                var actualMinWidth, d, x
                d = rtl
                  ? Math.max(maxPageX, Math.min(minPageX, e.pageX)) - pageX
                  : Math.min(maxPageX, Math.max(minPageX, e.pageX)) - pageX
                var isShrink = (d < 0 && !rtl) || (d > 0 && rtl)
                if (isShrink) {
                  // shrink column
                  x = d * (rtl ? -1 : 1)
                  for (j = i; j >= 0; j--) {
                    c = columns[getIndexOffset(isFrozenColumn, j)]
                    if (c.resizable) {
                      actualMinWidth = Math.max(c.minWidth || 0, absoluteColumnMinWidth)
                      if (x && c.previousWidth + x < actualMinWidth) {
                        x += c.previousWidth - actualMinWidth
                        c.width = actualMinWidth
                      } else {
                        c.width = c.previousWidth + x
                        x = 0
                      }
                    }
                  }

                  if (options.forceFitColumns) {
                    x = -d * (rtl ? -1 : 1)
                    for (j = i + 1; j < columnElements.length; j++) {
                      c = columns[getIndexOffset(isFrozenColumn, j)]
                      if (c.resizable) {
                        if (x && c.maxWidth && c.maxWidth - c.previousWidth < x) {
                          x -= c.maxWidth - c.previousWidth
                          c.width = c.maxWidth
                        } else {
                          c.width = c.previousWidth + x
                          x = 0
                        }
                      }
                    }
                  }
                } else {
                  // stretch column
                  x = d * (rtl ? -1 : 1)
                  for (j = i; j >= 0; j--) {
                    c = columns[getIndexOffset(isFrozenColumn, j)]
                    if (c.resizable) {
                      if (x && c.maxWidth && c.maxWidth - c.previousWidth < x) {
                        x -= c.maxWidth - c.previousWidth
                        c.width = c.maxWidth
                      } else {
                        c.width = c.previousWidth + x
                        x = 0
                      }
                    }
                  }

                  if (options.forceFitColumns) {
                    x = -d * (rtl ? -1 : 1)
                    for (j = i + 1; j < columnElements.length; j++) {
                      c = columns[getIndexOffset(isFrozenColumn, j)]
                      if (c.resizable) {
                        actualMinWidth = Math.max(c.minWidth || 0, absoluteColumnMinWidth)
                        if (x && c.previousWidth + x < actualMinWidth) {
                          x += c.previousWidth - actualMinWidth
                          c.width = actualMinWidth
                        } else {
                          c.width = c.previousWidth + x
                          x = 0
                        }
                      }
                    }
                  }
                }
                applyColumnHeaderWidths()
                if (options.numberOfColumnsToFreeze > 0) {
                  updateCanvasWidth(true)
                }
                if (options.syncColumnCellResize) {
                  applyColumnWidths()
                }
              }, 0)
            })
            .on('dragend', function (e, dd) {
              setTimeout(() => {
                isFrozenColumn = isPartOfAFrozenColumn(this)
                columnElements = getColumnElements(this)
                var newWidth
                $(this).parent().removeClass('slick-header-column-active')
                for (var j = 0; j < columnElements.length; j++) {
                  c = columns[getIndexOffset(isFrozenColumn, j)]
                  newWidth = $(columnElements[j]).outerWidth()
                  if (c.previousWidth !== newWidth) {
                    if (c.rerenderOnResize) {
                      invalidateAllRows()
                    }
                  }
                }
                updateCanvasWidth(true)
                render()
                trigger(self.onColumnsResized, {})
              }, 0)
            })
        })
      }
    }

    function getIndexOffset(isFrozen, index) {
      var newIndex = isFrozen ? index : index + options.numberOfColumnsToFreeze
      return newIndex
    }

    function isPartOfAFrozenColumn(target) {
      var results = false
      var targetIsFrozen = $(target).hasClass('headers_0')
      if (targetIsFrozen) {
        results = true
      } else {
        results = $(target).parents('.headers_0').length > 0
      }
      return results
    }

    function getColumnElements(target) {
      var results = $(target).parents('.slick-header-columns').children()
      return results
    }

    function getVBoxDelta($el) {
      var p = ['borderTopWidth', 'borderBottomWidth', 'paddingTop', 'paddingBottom']
      var delta = 0
      $.each(p, (n, val) => {
        delta += parseFloat($el.css(val)) || 0
      })
      return delta
    }

    function measureCellPaddingAndBorder() {
      var el
      var h = ['borderLeftWidth', 'borderRightWidth', 'paddingLeft', 'paddingRight']
      var v = ['borderTopWidth', 'borderBottomWidth', 'paddingTop', 'paddingBottom']

      el = $(
        "<div class='ui-state-default slick-header-column' style='visibility:hidden'>-</div>"
      ).appendTo($headers_1)
      headerColumnWidthDiff = headerColumnHeightDiff = 0
      if (
        el.css('box-sizing') != 'border-box' &&
        el.css('-moz-box-sizing') != 'border-box' &&
        el.css('-webkit-box-sizing') != 'border-box'
      ) {
        $.each(h, (n, val) => {
          headerColumnWidthDiff += parseFloat(el.css(val)) || 0
        })
        $.each(v, (n, val) => {
          headerColumnHeightDiff += parseFloat(el.css(val)) || 0
        })
      }
      el.remove()

      var r = $("<div class='slick-row' />").appendTo($canvas_1)
      el = $("<div class='slick-cell' id='' style='visibility:hidden'>-</div>").appendTo(r)
      cellWidthDiff = cellHeightDiff = 0
      if (
        el.css('box-sizing') != 'border-box' &&
        el.css('-moz-box-sizing') != 'border-box' &&
        el.css('-webkit-box-sizing') != 'border-box'
      ) {
        $.each(h, (n, val) => {
          cellWidthDiff += parseFloat(el.css(val)) || 0
        })
        $.each(v, (n, val) => {
          cellHeightDiff += parseFloat(el.css(val)) || 0
        })
      }
      r.remove()

      absoluteColumnMinWidth = Math.max(headerColumnWidthDiff, cellWidthDiff)
    }

    function createCssRules() {
      $style = $("<style type='text/css' rel='stylesheet' />").appendTo($('head'))
      var rowHeight = options.rowHeight - cellHeightDiff
      var rules = [
        '.' + uid + ' .slick-header-column { ' + rear + ': 1000px; }',
        '.' + uid + ' .slick-top-panel { height:' + options.topPanelHeight + 'px; }',
        '.' + uid + ' .slick-headerrow-columns { height:' + options.headerRowHeight + 'px; }',
        '.' + uid + ' .slick-cell { height:' + rowHeight + 'px; }',
        '.' + uid + ' .slick-row { height:' + options.rowHeight + 'px; }',
      ]

      for (var i = 0; i < columns.length; i++) {
        rules.push('.' + uid + ' .b' + i + ' { }')
        rules.push('.' + uid + ' .f' + i + ' { }')
      }

      if ($style[0].styleSheet) {
        // IE
        $style[0].styleSheet.cssText = rules.join(' ')
      } else {
        $style[0].appendChild(document.createTextNode(rules.join(' ')))
      }
    }

    function getColumnCssRules(idx) {
      if (!stylesheet) {
        var sheets = document.styleSheets
        for (var i = 0; i < sheets.length; i++) {
          if ((sheets[i].ownerNode || sheets[i].owningElement) == $style[0]) {
            stylesheet = sheets[i]
            break
          }
        }

        if (!stylesheet) {
          throw new Error('Cannot find stylesheet.')
        }

        // find and cache column CSS rules
        columnCssRulesB = []
        columnCssRulesF = []
        var cssRules = stylesheet.cssRules || stylesheet.rules
        var matches, columnIdx
        for (var i = 0; i < cssRules.length; i++) {
          var selector = cssRules[i].selectorText
          if ((matches = /\.b(\d+)/.exec(selector))) {
            columnIdx = parseInt(matches[1], 10)
            columnCssRulesB[columnIdx] = cssRules[i]
          } else if ((matches = /\.f(\d+)/.exec(selector))) {
            columnIdx = parseInt(matches[1], 10)
            columnCssRulesF[columnIdx] = cssRules[i]
          }
        }
      }

      return {
        [rear]: columnCssRulesB[idx],
        [front]: columnCssRulesF[idx],
      }
    }

    function removeCssRules() {
      $style.remove()
      stylesheet = null
    }

    function destroy() {
      getEditorLock().cancelCurrentEdit()

      trigger(self.onBeforeDestroy, {})

      var i = plugins.length
      while (i--) {
        unregisterPlugin(plugins[i])
      }

      if (options.enableColumnReorder) {
        if (options.numberOfColumnsToFreeze > 0) {
          $headers_0.filter(':ui-sortable').sortable('destroy')
        }
        $headers_1.filter(':ui-sortable').sortable('destroy')
      }

      unbindAncestorScrollEvents()
      $outerContainer.unbind('.slickgrid')
      removeCssRules()

      $canvas_1.unbind('draginit dragstart dragend drag')
      $outerContainer.empty().removeClass(uid)
    }

    // ////////////////////////////////////////////////////////////////////////////////////////////
    // General

    function trigger(evt, args, e) {
      e = e || new Slick.EventData()
      args = args || {}
      args.grid = self
      return evt.notify(args, e, self)
    }

    function getUID() {
      return uid
    }

    function getEditorLock() {
      return options.editorLock
    }

    function getEditController() {
      return editController
    }

    function getColumnIndex(id) {
      return columnsById[id]
    }

    function autosizeColumns() {
      var i,
        c,
        widths = [],
        shrinkLeeway = 0,
        total = 0,
        prevTotal,
        availWidth = viewportHasVScroll_1 ? viewportW_1 - scrollbarDimensions.width : viewportW_1

      for (i = 0; i < columns.length; i++) {
        c = columns[i]
        widths.push(c.width)
        total += c.width
        if (c.resizable) {
          shrinkLeeway += c.width - Math.max(c.minWidth, absoluteColumnMinWidth)
        }
      }

      // shrink
      prevTotal = total
      while (total > availWidth && shrinkLeeway) {
        var shrinkProportion = (total - availWidth) / shrinkLeeway
        for (i = 0; i < columns.length && total > availWidth; i++) {
          c = columns[i]
          var width = widths[i]
          if (!c.resizable || width <= c.minWidth || width <= absoluteColumnMinWidth) {
            continue
          }
          var absMinWidth = Math.max(c.minWidth, absoluteColumnMinWidth)
          var shrinkSize = Math.floor(shrinkProportion * (width - absMinWidth)) || 1
          shrinkSize = Math.min(shrinkSize, width - absMinWidth)
          total -= shrinkSize
          shrinkLeeway -= shrinkSize
          widths[i] -= shrinkSize
        }
        if (prevTotal == total) {
          // avoid infinite loop
          break
        }
        prevTotal = total
      }

      // grow
      prevTotal = total
      while (total < availWidth) {
        var growProportion = availWidth / total
        for (i = 0; i < columns.length && total < availWidth; i++) {
          c = columns[i]
          if (!c.resizable || c.maxWidth <= c.width) {
            continue
          }
          var growSize =
            Math.min(
              Math.floor(growProportion * c.width) - c.width,
              c.maxWidth - c.width || 1000000
            ) || 1
          total += growSize
          widths[i] += growSize
        }
        if (prevTotal == total) {
          // avoid infinite loop
          break
        }
        prevTotal = total
      }

      var reRender = false
      for (i = 0; i < columns.length; i++) {
        if (columns[i].rerenderOnResize && columns[i].width != widths[i]) {
          reRender = true
        }
        columns[i].width = widths[i]
      }

      applyColumnHeaderWidths()
      updateCanvasWidth(true)
      if (reRender) {
        invalidateAllRows()
        render()
      }
    }

    function applyWidthToHeaders(header) {
      var isFrozenColumn = isPartOfAFrozenColumn(header)
      var headers = header.children()
      for (var i = 0, h, ii = headers.length; i < ii; i++) {
        h = $(headers[i])
        var columnIndex = getIndexOffset(isFrozenColumn, i)
        if (h.width() !== columns[columnIndex].width - headerColumnWidthDiff) {
          h.width(columns[columnIndex].width - headerColumnWidthDiff)
        }
      }
    }

    function applyColumnHeaderWidths() {
      if (!initialized) {
        return
      }
      if (options.numberOfColumnsToFreeze > 0) {
        applyWidthToHeaders($headers_0) // Frozen Columns
      }
      applyWidthToHeaders($headers_1) // NonFrozen Columns
      updateColumnCaches()
    }

    function applyColumnWidths() {
      var nonFrozenWidth = 0,
        w,
        rule
      var frozenWidth = 0
      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
      var ruleIndex = 0
      var columnCount = columns.length

      for (var i = 0; i < columnCount; i++) {
        w = columns[i].width
        rule = getColumnCssRules(i)
        if (i < numberOfColumnsToFreeze) {
          // FrozenColumns
          rule[rear].style[rear] = frozenWidth + 'px'
          rule[front].style[front] = canvasWidth_0 - frozenWidth - w + 'px'
          frozenWidth += columns[i].width
        } else {
          // NonFrozenColumns
          rule[rear].style[rear] = nonFrozenWidth + 'px'
          rule[front].style[front] = canvasWidth_1 - nonFrozenWidth - w + 'px'
          nonFrozenWidth += columns[i].width
        }
      }
    }

    /*
     * updates the numberOfColumnsToFreeze.
     *
     * doesn't change the number of frozen columns until you do something to
     * re-build the grid (like setColumns)
     */
    function setNumberOfColumnsToFreeze(n) {
      options.numberOfColumnsToFreeze = n
    }

    function setSortColumn(columnId, ascending) {
      setSortColumns([{columnId, sortAsc: ascending}])
    }

    function setSortColumns(cols) {
      sortColumns = cols
      // Combine frozen and nonFrozen
      var headerColumnEls = $headers_1
        .children()
        .add(options.numberOfColumnsToFreeze ? $headers_0.children() : null)
      headerColumnEls
        .removeClass('slick-header-column-sorted')
        .find('.slick-sort-indicator')
        .removeClass('slick-sort-indicator-asc slick-sort-indicator-desc')

      $.each(sortColumns, (i, col) => {
        if (col.sortAsc == null) {
          col.sortAsc = true
        }
        var columnIndex = getColumnIndex(col.columnId)
        if (columnIndex != null) {
          headerColumnEls
            .eq(columnIndex)
            .addClass('slick-header-column-sorted')
            .find('.slick-sort-indicator')
            .addClass(col.sortAsc ? 'slick-sort-indicator-asc' : 'slick-sort-indicator-desc')
        }
      })
    }

    function getSortColumns() {
      return sortColumns
    }

    function handleSelectedRangesChanged(e, ranges) {
      selectedRows = []
      var hash = {}
      for (var i = 0; i < ranges.length; i++) {
        for (var j = ranges[i].fromRow; j <= ranges[i].toRow; j++) {
          if (!hash[j]) {
            // prevent duplicates
            selectedRows.push(j)
            hash[j] = {}
          }
          for (var k = ranges[i].fromCell; k <= ranges[i].toCell; k++) {
            if (canCellBeSelected(j, k)) {
              hash[j][columns[k].id] = options.selectedCellCssClass
            }
          }
        }
      }

      setCellCssStyles(options.selectedCellCssClass, hash)

      trigger(self.onSelectedRowsChanged, {rows: getSelectedRows()}, e)
    }

    function getColumns() {
      return columns
    }

    function updateColumnCaches() {
      // Pre-calculate cell boundaries.
      columnPosRear = []
      columnPosFront = []
      var frozenWidth = 0
      var nonFrozenWidth = 0
      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
      for (var i = 0, ii = columns.length; i < ii; i++) {
        if (i < numberOfColumnsToFreeze) {
          // Frozen Columns
          columnPosRear[i] = frozenWidth
          columnPosFront[i] = frozenWidth + columns[i].width
          frozenWidth += columns[i].width
        } else {
          // NonFrozen Columns
          columnPosRear[i] = nonFrozenWidth
          columnPosFront[i] = nonFrozenWidth + columns[i].width
          nonFrozenWidth += columns[i].width
        }
      }
    }

    function setColumns(columnDefinitions) {
      columns = columnDefinitions

      columnsById = {}
      for (var i = 0; i < columns.length; i++) {
        var m = (columns[i] = $.extend({}, columnDefaults, columns[i]))
        columnsById[m.id] = i
        if (m.minWidth && m.width < m.minWidth) {
          m.width = m.minWidth
        }
        if (m.maxWidth && m.width > m.maxWidth) {
          m.width = m.maxWidth
        }
      }

      updateColumnCaches()

      if (initialized) {
        invalidateAllRows()
        createColumnHeaders()
        removeCssRules()
        createCssRules()
        resizeCanvas()
        applyColumnWidths()
        handleScroll()
      }
    }

    function getOptions() {
      return options
    }

    function setOptions(args) {
      if (!getEditorLock().commitCurrentEdit()) {
        return
      }

      makeActiveCellNormal()

      if (options.enableAddRow !== args.enableAddRow) {
        invalidateRow(getDataLength())
      }

      options = $.extend(options, args)
      validateAndEnforceOptions()

      $viewport_1.css('overflow-y', options.autoHeight ? 'hidden' : 'auto')
      render()
    }

    function validateAndEnforceOptions() {
      if (options.autoHeight) {
        options.leaveSpaceForNewRows = false
      }
    }

    function setData(newData, scrollToTop) {
      data = newData
      invalidateAllRows()
      updateRowCount()
      if (scrollToTop) {
        scrollTo(0)
      }
    }

    function getData() {
      return data
    }

    function getDataLength() {
      if (data.getLength) {
        return data.getLength()
      } else {
        return data.length
      }
    }

    function getDataLengthIncludingAddNew() {
      return getDataLength() + (options.enableAddRow ? 1 : 0)
    }

    function getDataItem(i) {
      if (data.getItem) {
        return data.getItem(i)
      } else {
        return data[i]
      }
    }

    function getTopPanel() {
      return $topPanel_1[0]
    }

    function setTopPanelVisibility(visible) {
      if (options.showTopPanel != visible) {
        options.showTopPanel = visible
        if (visible) {
          $topPanelScroller_1.slideDown('fast', resizeCanvas)
        } else {
          $topPanelScroller_1.slideUp('fast', resizeCanvas)
        }
      }
    }

    function setHeaderRowVisibility(visible) {
      if (options.showHeaderRow != visible) {
        options.showHeaderRow = visible
        if (visible) {
          $headerRowScroller_1.slideDown('fast', resizeCanvas)
        } else {
          $headerRowScroller_1.slideUp('fast', resizeCanvas)
        }
      }
    }

    function getContainerNode() {
      return $outerContainer.get(0)
    }

    // ////////////////////////////////////////////////////////////////////////////////////////////
    // Rendering / Scrolling

    function getRowTop(row) {
      return options.rowHeight * row - offset
    }

    function getRowFromPosition(y) {
      return Math.floor((y + offset) / options.rowHeight)
    }

    function scrollTo(y) {
      y = Math.max(y, 0)
      y = Math.min(y, th - viewportH_1 + (viewportHasHScroll_1 ? scrollbarDimensions.height : 0))

      var oldOffset = offset

      page = Math.min(n - 1, Math.floor(y / ph))
      offset = Math.round(page * cj)
      var newScrollTop = y - offset

      if (offset != oldOffset) {
        var range = getVisibleRange(newScrollTop)
        cleanupRows(range)
        updateRowPositions()
      }

      if (prevScrollTop != newScrollTop) {
        vScrollDir = prevScrollTop + oldOffset < newScrollTop + offset ? 1 : -1
        $viewport_1[0].scrollTop = lastRenderedScrollTop = scrollTop = prevScrollTop = newScrollTop

        if (options.numberOfColumnsToFreeze > 0) {
          $viewport_0[0].scrollTop = scrollTop
        }

        trigger(self.onViewportChanged, {})
      }
    }

    function defaultFormatter(row, cell, value, columnDef, dataContext) {
      if (value == null) {
        return ''
      } else {
        return (value + '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      }
    }

    function getFormatter(row, column) {
      var rowMetadata = data.getItemMetadata && data.getItemMetadata(row)

      // look up by id, then index
      var columnOverrides =
        rowMetadata &&
        rowMetadata.columns &&
        (rowMetadata.columns[column.id] || rowMetadata.columns[getColumnIndex(column.id)])

      return (
        (columnOverrides && columnOverrides.formatter) ||
        (rowMetadata && rowMetadata.formatter) ||
        column.formatter ||
        (options.formatterFactory && options.formatterFactory.getFormatter(column)) ||
        options.defaultFormatter
      )
    }

    function getEditor(row, cell) {
      var column = columns[cell]
      var rowMetadata = data.getItemMetadata && data.getItemMetadata(row)
      var columnMetadata = rowMetadata && rowMetadata.columns

      if (
        columnMetadata &&
        columnMetadata[column.id] &&
        columnMetadata[column.id].editor !== undefined
      ) {
        return columnMetadata[column.id].editor
      }
      if (columnMetadata && columnMetadata[cell] && columnMetadata[cell].editor !== undefined) {
        return columnMetadata[cell].editor
      }

      return column.editor || (options.editorFactory && options.editorFactory.getEditor(column))
    }

    function getDataItemValueForColumn(item, columnDef) {
      if (options.dataItemColumnValueExtractor) {
        return options.dataItemColumnValueExtractor(item, columnDef)
      }
      return item[columnDef.field]
    }

    function appendRowHtml(stringArray, row, range, dataLength) {
      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze // CLICK CUSTOM CODE
      var d = getDataItem(row)
      var dataLoading = row < dataLength && !d
      var rowCss =
        'slick-row' +
        (dataLoading ? ' loading' : '') +
        (row === activeRow ? ' active' : '') +
        (row % 2 == 1 ? ' odd' : ' even')

      var metadata = data.getItemMetadata && data.getItemMetadata(row)

      if (metadata && metadata.cssClasses) {
        rowCss += ' ' + metadata.cssClasses
      }

      var rowString =
        "<div class='ui-widget-content " + rowCss + "' style='top:" + getRowTop(row) + "px;' >"
      // only use role in normal rows
      stringArray.nonFrozen.push(rowString)
      if (numberOfColumnsToFreeze > 0) {
        stringArray.frozen.push(rowString)
      }

      var colspan, m
      for (var i = 0, ii = columns.length; i < ii; i++) {
        m = columns[i]
        colspan = 1
        if (metadata && metadata.columns) {
          var columnData = metadata.columns[m.id] || metadata.columns[i]
          colspan = (columnData && columnData.colspan) || 1
          if (colspan === '*') {
            colspan = ii - i
          }
        }

        // Always render frozen columns
        if (numberOfColumnsToFreeze && i < numberOfColumnsToFreeze) {
          appendCellHtml(stringArray, row, i, colspan, d)
        } else if (
          columnPosFront[Math.min(ii - 1, i + colspan - 1)] >
          (rtl ? canvasWidth_1 - range.rightPx : range.leftPx)
        ) {
          // Do not render cells before those in range.
          if (columnPosRear[i] > (rtl ? canvasWidth_1 - range.leftPx : range.rightPx)) {
            // All columns after are outside the range.
            break
          }
          appendCellHtml(stringArray, row, i, colspan, d)
        }
        if (colspan > 1) {
          i += colspan - 1
        }
      }

      stringArray.nonFrozen.push('</div>')
      if (numberOfColumnsToFreeze > 0) {
        stringArray.frozen.push('</div>')
      }
    }

    function appendCellHtml(stringArray, row, cell, colspan, item) {
      var m = columns[cell]
      // var d = getDataItem(row);
      var cellCss =
        'slick-cell b' +
        cell +
        ' f' +
        Math.min(columns.length - 1, cell + colspan - 1) +
        (m.cssClass ? ' ' + m.cssClass : '')
      if (row === activeRow && cell === activeCell) {
        cellCss += ' active'
      }

      // TODO:  merge them together in the setter
      for (var key in cellCssClasses) {
        if (cellCssClasses[key][row] && cellCssClasses[key][row][m.id]) {
          cellCss += ' ' + cellCssClasses[key][row][m.id]
        }
      }

      var cellString = "<div class='" + cellCss + "'>"

      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
      // FrozenColumns - Add the cells html depending on the cell index - frozen or not
      if (cell < numberOfColumnsToFreeze) {
        stringArray.frozen.push(cellString)
      } else {
        stringArray.nonFrozen.push(cellString)
      }

      // if there is a corresponding row (if not, this is the Add New row or this data hasn't been loaded yet)
      if (item) {
        var value = getDataItemValueForColumn(item, m)
        var contents = getFormatter(row, m)(row, cell, value, m, item)
        if (cell < numberOfColumnsToFreeze) {
          stringArray.frozen.push(contents)
        } else {
          stringArray.nonFrozen.push(getFormatter(row, m)(row, cell, value, m, item))
        }
      }

      if (cell < numberOfColumnsToFreeze) {
        stringArray.frozen.push('</div>')
      } else {
        stringArray.nonFrozen.push('</div>')
      }

      rowsCache[row].cellRenderQueue.push(cell)
      rowsCache[row].cellColSpans[cell] = colspan
    }

    function cleanupRows(rangeToKeep) {
      for (var i in rowsCache) {
        if (
          (i = parseInt(i, 10)) !== activeRow &&
          (i < rangeToKeep.top || i > rangeToKeep.bottom)
        ) {
          removeRowFromCache(i)
        }
      }
    }

    function invalidate() {
      updateRowCount()
      invalidateAllRows()
      render()
    }

    function invalidateAllRows() {
      if (currentEditor) {
        makeActiveCellNormal()
      }
      for (var row in rowsCache) {
        removeRowFromCache(row)
      }
    }

    function removeRowFromCache(row) {
      var cacheEntry = rowsCache[row]
      if (!cacheEntry) {
        return
      }
      var childToRemove = cacheEntry.rowNode
      // Frozen Columns - remove row from frozen and nonFrozen canvas_x
      if (options.numberOfColumnsToFreeze > 0) {
        if (childToRemove.nonFrozen) {
          $canvas_1[0].removeChild(childToRemove.nonFrozen)
        }
        if (childToRemove.frozen) {
          $canvas_0[0].removeChild(childToRemove.frozen)
        }
      } else {
        $canvas_1[0].removeChild(childToRemove.nonFrozen)
      }
      delete rowsCache[row]
      delete postProcessedRows[row]
      renderedRows--
      counter_rows_removed++
    }

    function invalidateRows(rows) {
      var i, rl
      if (!rows || !rows.length) {
        return
      }
      vScrollDir = 0
      for (i = 0, rl = rows.length; i < rl; i++) {
        if (currentEditor && activeRow === rows[i]) {
          makeActiveCellNormal()
        }
        if (rowsCache[rows[i]]) {
          removeRowFromCache(rows[i])
        }
      }
    }

    function invalidateRow(row) {
      invalidateRows([row])
    }

    function updateCell(row, cell) {
      var cellNode = getCellNode(row, cell)
      if (!cellNode) {
        return
      }

      var m = columns[cell],
        d = getDataItem(row)
      if (currentEditor && activeRow === row && activeCell === cell) {
        currentEditor.loadValue(d)
      } else {
        cellNode.innerHTML = d
          ? getFormatter(row, m)(row, cell, getDataItemValueForColumn(d, m), m, d)
          : ''
        invalidatePostProcessingResults(row)
      }
    }

    function updateRow(row) {
      var cacheEntry = rowsCache[row]
      if (!cacheEntry) {
        return
      }

      ensureCellNodesInRowsCache(row)

      var d = getDataItem(row)

      for (var columnIdx in cacheEntry.cellNodesByColumnIdx) {
        if (!cacheEntry.cellNodesByColumnIdx.hasOwnProperty(columnIdx)) {
          continue
        }

        columnIdx |= 0
        var m = columns[columnIdx],
          node = cacheEntry.cellNodesByColumnIdx[columnIdx]

        if (row === activeRow && columnIdx === activeCell && currentEditor) {
          currentEditor.loadValue(d)
        } else if (d) {
          node.innerHTML = getFormatter(row, m)(
            row,
            columnIdx,
            getDataItemValueForColumn(d, m),
            m,
            d
          )
        } else {
          node.innerHTML = ''
        }
      }

      invalidatePostProcessingResults(row)
    }

    function getViewportHeight() {
      return (
        parseFloat($.css($outerContainer[0], 'height', true)) -
        parseFloat($.css($outerContainer[0], 'paddingTop', true)) -
        parseFloat($.css($outerContainer[0], 'paddingBottom', true)) -
        parseFloat($.css($headerScroller_1[0], 'height')) -
        getVBoxDelta($headerScroller_1) -
        (options.showTopPanel ? options.topPanelHeight + getVBoxDelta($topPanelScroller_1) : 0) -
        (options.showHeaderRow ? options.headerRowHeight + getVBoxDelta($headerRowScroller_1) : 0)
      )
    }

    function resizeCanvas() {
      if (!initialized) {
        return
      }
      if (options.autoHeight) {
        viewportH_1 = options.rowHeight * getDataLengthIncludingAddNew()
      } else {
        viewportH_1 = getViewportHeight()
      }

      numVisibleRows = Math.ceil(viewportH_1 / options.rowHeight)
      viewportW_1 = parseFloat($.css($container_1[0], 'width', true))
      if (!options.autoHeight) {
        $viewport_1.height(viewportH_1)
        // Frozen Columns - also set left viewport height
        if (options.numberOfColumnsToFreeze) {
          $viewport_0.height(viewportH_1)
        }
      }

      if (options.forceFitColumns) {
        autosizeColumns()
      }

      updateRowCount()
      handleScroll()
      // Since the width has changed, force the render() to reevaluate virtually rendered cells.
      lastRenderedScrollLeft = -1
      render()
    }

    function updateRowCount() {
      var dataLength = getDataLength()
      if (!initialized) {
        return
      }
      numberOfRows =
        getDataLengthIncludingAddNew() + (options.leaveSpaceForNewRows ? numVisibleRows - 1 : 0)

      var oldViewportHasVScroll = viewportHasVScroll_1
      // with autoHeight, we do not need to accommodate the vertical scroll bar
      viewportHasVScroll_1 = !options.autoHeight && numberOfRows * options.rowHeight > viewportH_1

      // remove the rows that are now outside of the data range
      // this helps avoid redundant calls to .removeRow() when the size of the data decreased by thousands of rows
      var l = getDataLengthIncludingAddNew() - 1
      for (var i in rowsCache) {
        if (i >= l) {
          removeRowFromCache(i)
        }
      }

      if (activeCellNode && activeRow > l) {
        resetActiveCell()
      }

      var oldH = h
      th = Math.max(options.rowHeight * numberOfRows, viewportH_1 - scrollbarDimensions.height)
      if (th < maxSupportedCssHeight) {
        // just one page
        h = ph = th
        n = 1
        cj = 0
      } else {
        // break into pages
        h = maxSupportedCssHeight
        ph = h / 100
        n = Math.floor(th / ph)
        cj = (th - h) / (n - 1)
      }

      if (h !== oldH) {
        $canvas_1.css('height', h)
        scrollTop = $viewport_1[0].scrollTop
        // Frozen Columns - Set left viewport height to h + scrollbar height
        if (options.numberOfColumnsToFreeze > 0) {
          $canvas_0.css('height', h + scrollbarDimensions.height)
        }
      }

      var oldScrollTopInRange = scrollTop + offset <= th - viewportH_1

      if (th == 0 || scrollTop == 0) {
        page = offset = 0
      } else if (oldScrollTopInRange) {
        // maintain virtual position
        scrollTo(scrollTop + offset)
      } else {
        // scroll to bottom
        scrollTo(th - viewportH_1)
      }

      if (h != oldH && options.autoHeight) {
        resizeCanvas()
      }

      if (options.forceFitColumns && oldViewportHasVScroll != viewportHasVScroll_1) {
        autosizeColumns()
      }
      updateCanvasWidth(false)
    }

    // ///////////////////////////////////////////////////////////////////////////////////////////////////////
    // Returns an object with the following values.
    //	top		- row number of the top visible row. applicable to viewport_0 and viewport_1.
    //	bottom	- row number of the bottom visible row. applicable to viewport_0 and viewport_1.
    //	leftPx	- pixel number of the leftmost visible pixel. applicable to viewPort_1 only.
    //			As viewport_0 is frozen it is assumed to always be visible
    //	rightPx	- pixel number. applicable to viewPort_1 only.
    //			As viewport_0 is frozen it is assumed to always be visible
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////
    function getVisibleRange(viewportTop, viewportLeft) {
      if (viewportTop == null) {
        viewportTop = scrollTop
      }
      if (viewportLeft == null) {
        viewportLeft = scrollLeft
      }

      return {
        top: getRowFromPosition(viewportTop),
        bottom: getRowFromPosition(viewportTop + viewportH_1),
        leftPx: viewportLeft,
        rightPx: viewportLeft + viewportW_1,
      }
    }

    // ///////////////////////////////////////////////////////////////////////////////////////////////////////
    // Returns an object with the following values.
    //	top		- row number. applicable to viewport_0 and viewport_1.
    //	bottom	- row number. applicable to viewport_0 and viewport_1.
    //	leftPx	- pixel number. applicable to viewPort_1 only. As viewport_0 is frozen it
    //			is assumed to always be rendered
    //	rightPx	- pixel number. applicable to viewPort_1 only. As viewport_0 is frozen it
    //			is assumed to always be rendered
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////
    function getRenderedRange(viewportTop, viewportLeft) {
      var range = getVisibleRange(viewportTop, viewportLeft)
      var buffer = Math.round(viewportH_1 / options.rowHeight)
      var minBuffer = 3

      if (vScrollDir == -1) {
        range.top -= buffer
        range.bottom += minBuffer
      } else if (vScrollDir == 1) {
        range.top -= minBuffer
        range.bottom += buffer
      } else {
        range.top -= minBuffer
        range.bottom += minBuffer
      }

      range.top = Math.max(0, range.top)
      range.bottom = Math.min(getDataLengthIncludingAddNew() - 1, range.bottom)
      range.leftPx -= viewportW_1
      range.rightPx += viewportW_1
      range.leftPx = Math.max(0, range.leftPx)
      range.rightPx = Math.min(canvasWidth_1, range.rightPx)
      return range
    }

    function ensureCellNodesInRowsCache(row) {
      var cacheEntry = rowsCache[row]
      if (cacheEntry) {
        if (cacheEntry.cellRenderQueue.length) {
          var lastChild_1 = cacheEntry.rowNode.nonFrozen.lastChild
          if (options.numberOfColumnsToFreeze > 0) {
            var lastChild_0 = cacheEntry.rowNode.frozen.lastChild
          }
          var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
          while (cacheEntry.cellRenderQueue.length) {
            var columnIdx = cacheEntry.cellRenderQueue.pop()

            if (numberOfColumnsToFreeze > columnIdx) {
              cacheEntry.cellNodesByColumnIdx[columnIdx] = lastChild_0
              if (lastChild_0.previousSibling) {
                lastChild_0 = lastChild_0.previousSibling
              }
            } else {
              cacheEntry.cellNodesByColumnIdx[columnIdx] = lastChild_1
              if (lastChild_1.previousSibling) {
                lastChild_1 = lastChild_1.previousSibling
              }
            }
          }
        }
      }
    }
    function cleanUpCells(range, row) {
      var totalCellsRemoved = 0
      var cacheEntry = rowsCache[row]

      // Remove cells outside the range.
      var cellsToRemove = []
      for (var i in cacheEntry.cellNodesByColumnIdx) {
        // I really hate it when people mess with Array.prototype.
        if (!cacheEntry.cellNodesByColumnIdx.hasOwnProperty(i)) {
          continue
        }

        // This is a string, so it needs to be cast back to a number.
        i |= 0

        var colspan = cacheEntry.cellColSpans[i]
        const outOfRange = rtl
          ? columnPosRear[i] > canvasWidth_1 - range.leftPx ||
            columnPosFront[Math.min(columns.length - 1, i + colspan - 1)] <
              canvasWidth_1 - range.rightPx
          : columnPosRear[i] > range.rightPx ||
            columnPosFront[Math.min(columns.length - 1, i + colspan - 1)] < range.leftPx
        if (outOfRange) {
          if (!(row == activeRow && i == activeCell)) {
            cellsToRemove.push(i)
          }
        }
      }

      var cellToRemove = cellsToRemove.pop()
      var childToRemove, children
      while (cellToRemove != null && cellToRemove != 0) {
        childToRemove = cacheEntry.cellNodesByColumnIdx[cellToRemove]
        // cacheEntry.rowNode.frozen.removeChild(childToRemove);
        children = cacheEntry.rowNode.nonFrozen.childNodes
        for (var i = 0; i < children.length; i++) {
          if (children[i] == childToRemove) {
            cacheEntry.rowNode.nonFrozen.removeChild(childToRemove)
            delete cacheEntry.cellColSpans[cellToRemove]
            delete cacheEntry.cellNodesByColumnIdx[cellToRemove]
            if (postProcessedRows[row]) {
              delete postProcessedRows[row][cellToRemove]
            }
            totalCellsRemoved++
            break
          }
        }
        if (cellsToRemove.length > 0) {
          cellToRemove = cellsToRemove.pop()
        } else {
          cellToRemove = null
        }
      }
    }

    function cleanUpAndRenderCells(range) {
      var cacheEntry
      var stringArray = {frozen: [], nonFrozen: []}
      var processedRows = []
      var cellsAdded
      var totalCellsAdded = 0
      var colspan

      for (var row = range.top, btm = range.bottom; row <= btm; row++) {
        cacheEntry = rowsCache[row]
        if (!cacheEntry) {
          continue
        }

        // cellRenderQueue populated in renderRows() needs to be cleared first
        ensureCellNodesInRowsCache(row)

        cleanUpCells(range, row)

        // Render missing cells.
        cellsAdded = 0

        var metadata = data.getItemMetadata && data.getItemMetadata(row)
        metadata = metadata && metadata.columns

        var d = getDataItem(row)

        // TODO:  shorten this loop (index? heuristics? binary search?)
        for (var i = 0, ii = columns.length; i < ii; i++) {
          // Cells to the right are outside the range.
          if (columnPosRear[i] > (rtl ? range.rightPx + canvasWidth_1 : range.rightPx)) {
            break
          }

          // Already rendered.
          if ((colspan = cacheEntry.cellColSpans[i]) != null) {
            i += colspan > 1 ? colspan - 1 : 0
            continue
          }

          colspan = 1
          if (metadata) {
            var columnData = metadata[columns[i].id] || metadata[i]
            colspan = (columnData && columnData.colspan) || 1
            if (colspan === '*') {
              colspan = ii - i
            }
          }

          if (
            columnPosFront[Math.min(ii - 1, i + colspan - 1)] >
            (rtl ? canvasWidth_1 - range.rightPx : range.leftPx)
          ) {
            appendCellHtml(stringArray, row, i, colspan, d)
            cellsAdded++
          }

          i += colspan > 1 ? colspan - 1 : 0
        }

        if (cellsAdded) {
          totalCellsAdded += cellsAdded
          processedRows.push(row)
        }
      }

      if (!stringArray.nonFrozen.length) {
        return
      }

      var nonFrozenDiv = document.createElement('div')
      nonFrozenDiv.innerHTML = stringArray.nonFrozen.join('')
      var frozenDiv = document.createElement('div')
      frozenDiv.innerHTML = stringArray.frozen.join('')

      var processedRow
      var nonFrozenNode
      var frozenNode
      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
      while ((processedRow = processedRows.pop()) != null) {
        cacheEntry = rowsCache[processedRow]
        var columnIdx
        while ((columnIdx = cacheEntry.cellRenderQueue.pop()) != null) {
          frozenNode = frozenDiv.lastChild
          nonFrozenNode = nonFrozenDiv.lastChild
          if (numberOfColumnsToFreeze > columnIdx) {
            cacheEntry.rowNode.frozen.appendChild(frozenNode)
            cacheEntry.cellNodesByColumnIdx[columnIdx] = frozenNode
          } else {
            cacheEntry.rowNode.nonFrozen.appendChild(nonFrozenNode)
            cacheEntry.cellNodesByColumnIdx[columnIdx] = nonFrozenNode
          }
        }
      }
    }

    function renderRows(range) {
      var parentNode_1 = $canvas_1[0],
        stringArray = {frozen: [], nonFrozen: []},
        rows = [],
        needToReselectCell = false,
        dataLength = getDataLength()

      var numberOfColumnsToFreeze = options.numberOfColumnsToFreeze
      if (numberOfColumnsToFreeze) {
        var parentNode_0 = $canvas_0[0]
      }

      for (var i = range.top, ii = range.bottom; i <= ii; i++) {
        if (rowsCache[i]) {
          continue
        }
        renderedRows++
        rows.push(i)

        // Create an entry right away so that appendRowHtml() can
        // start populatating it.
        rowsCache[i] = {
          rowNode: null,

          // ColSpans of rendered cells (by column idx).
          // Can also be used for checking whether a cell has been rendered.
          cellColSpans: [],

          // Cell nodes (by column idx).  Lazy-populated by ensureCellNodesInRowsCache().
          cellNodesByColumnIdx: [],

          // Column indices of cell nodes that have been rendered, but not yet indexed in
          // cellNodesByColumnIdx.  These are in the same order as cell nodes added at the
          // end of the row.
          cellRenderQueue: [],
        }

        appendRowHtml(stringArray, i, range, dataLength)
        if (activeCellNode && activeRow === i) {
          needToReselectCell = true
        }
        counter_rows_rendered++
      }

      if (!rows.length) {
        return
      }

      var nonFrozenDiv = document.createElement('div')
      nonFrozenDiv.innerHTML = stringArray.nonFrozen.join('')
      if (numberOfColumnsToFreeze > 0) {
        // FreezeColumns - Add divs for both frozen columns and update contents
        var frozenDiv = document.createElement('div')
        frozenDiv.innerHTML = stringArray.frozen.join('')
      }

      var currentRowCache
      for (var i = 0, ii = rows.length; i < ii; i++) {
        currentRowCache = rowsCache[rows[i]]
        currentRowCache.rowNode = {
          frozen: numberOfColumnsToFreeze > 0 ? parentNode_0.appendChild(frozenDiv.firstChild) : '',
          nonFrozen: parentNode_1.appendChild(nonFrozenDiv.firstChild),
        }
      }

      if (needToReselectCell) {
        activeCellNode = getCellNode(activeRow, activeCell)
      }
    }

    function startPostProcessing() {
      if (!options.enableAsyncPostRender) {
        return
      }
      clearTimeout(h_postrender)
      h_postrender = setTimeout(asyncPostProcessRows, options.asyncPostRenderDelay)
    }

    function invalidatePostProcessingResults(row) {
      delete postProcessedRows[row]
      postProcessFromRow = Math.min(postProcessFromRow, row)
      postProcessToRow = Math.max(postProcessToRow, row)
      startPostProcessing()
    }

    function updateRowPositions() {
      for (var row in rowsCache) {
        var rowTop = getRowTop(row) + 'px'
        rowsCache[row].rowNode.frozen.style.top = rowTop
        rowsCache[row].rowNode.nonFrozen.style.top = rowTop
      }
    }

    function render() {
      if (!initialized) {
        return
      }
      var visible = getVisibleRange()
      var rendered = getRenderedRange()

      // remove rows no longer in the viewport
      cleanupRows(rendered)

      // add new rows & missing cells in existing rows
      if (lastRenderedScrollLeft != scrollLeft) {
        cleanUpAndRenderCells(rendered)
      }

      // render missing rows
      renderRows(rendered)

      postProcessFromRow = visible.top
      postProcessToRow = Math.min(getDataLengthIncludingAddNew() - 1, visible.bottom)
      startPostProcessing()

      lastRenderedScrollTop = scrollTop
      lastRenderedScrollLeft = scrollLeft
      h_render = null
    }

    function handleHeaderRowScroll() {
      var scrollLeft = getScrollLeft($headerRowScroller_1[0])
      if (scrollLeft != getScrollLeft($viewport_1[0])) {
        $viewport_1[0].scrollLeft = scrollLeft
      }
    }

    function handleScroll(scrollInfo) {
      if (scrollInfo != undefined && scrollInfo.scrollTop != undefined) {
        $viewport_1[0].scrollTop = scrollInfo.scrollTop
      }
      scrollTop = $viewport_1[0].scrollTop
      scrollLeft = getScrollLeft($viewport_1[0])
      var vScrollDist = Math.abs(scrollTop - prevScrollTop)
      var hScrollDist = Math.abs(scrollLeft - prevScrollLeft)

      if (hScrollDist) {
        prevScrollLeft = scrollLeft
        setScrollLeft($headerScroller_1[0], scrollLeft)
        setScrollLeft($topPanelScroller_1[0], scrollLeft)
        setScrollLeft($headerRowScroller_1[0], scrollLeft)
      }

      if (vScrollDist) {
        vScrollDir = prevScrollTop < scrollTop ? 1 : -1
        prevScrollTop = scrollTop

        if (options.numberOfColumnsToFreeze > 0) {
          $viewport_0[0].scrollTop = scrollTop
        }

        // switch virtual pages if needed
        if (vScrollDist < viewportH_1) {
          scrollTo(scrollTop + offset)
        } else {
          var oldOffset = offset
          if (h == viewportH_1) {
            page = 0
          } else {
            page = Math.min(
              n - 1,
              Math.floor(scrollTop * ((th - viewportH_1) / (h - viewportH_1)) * (1 / ph))
            )
          }
          offset = Math.round(page * cj)
          if (oldOffset != offset) {
            invalidateAllRows()
          }
        }
      }

      if (hScrollDist || vScrollDist) {
        if (h_render) {
          clearTimeout(h_render)
        }

        if (
          Math.abs(lastRenderedScrollTop - scrollTop) > 20 ||
          Math.abs(lastRenderedScrollLeft - scrollLeft) > 20
        ) {
          if (
            options.forceSyncScrolling ||
            (Math.abs(lastRenderedScrollTop - scrollTop) < viewportH_1 &&
              Math.abs(lastRenderedScrollLeft - scrollLeft) < viewportW_1)
          ) {
            render()
          } else {
            h_render = setTimeout(render, 50)
          }

          trigger(self.onViewportChanged, {})
        }
      }

      trigger(self.onScroll, {scrollLeft, scrollTop})
    }

    function asyncPostProcessRows() {
      while (postProcessFromRow <= postProcessToRow) {
        var row = vScrollDir >= 0 ? postProcessFromRow++ : postProcessToRow--
        var cacheEntry = rowsCache[row]
        if (!cacheEntry || row >= getDataLength()) {
          continue
        }

        if (!postProcessedRows[row]) {
          postProcessedRows[row] = {}
        }

        ensureCellNodesInRowsCache(row)
        for (var columnIdx in cacheEntry.cellNodesByColumnIdx) {
          if (!cacheEntry.cellNodesByColumnIdx.hasOwnProperty(columnIdx)) {
            continue
          }

          columnIdx |= 0

          var m = columns[columnIdx]
          if (m.asyncPostRender && !postProcessedRows[row][columnIdx]) {
            var node = cacheEntry.cellNodesByColumnIdx[columnIdx]
            if (node) {
              m.asyncPostRender(node, row, getDataItem(row), m)
            }
            postProcessedRows[row][columnIdx] = true
          }
        }

        h_postrender = setTimeout(asyncPostProcessRows, options.asyncPostRenderDelay)
        return
      }
    }

    function updateCellCssStylesOnRenderedRows(addedHash, removedHash) {
      var node, columnId, addedRowHash, removedRowHash
      for (var row in rowsCache) {
        removedRowHash = removedHash && removedHash[row]
        addedRowHash = addedHash && addedHash[row]

        if (removedRowHash) {
          for (columnId in removedRowHash) {
            if (!addedRowHash || removedRowHash[columnId] != addedRowHash[columnId]) {
              node = getCellNode(row, getColumnIndex(columnId))
              if (node) {
                $(node).removeClass(removedRowHash[columnId])
              }
            }
          }
        }

        if (addedRowHash) {
          for (columnId in addedRowHash) {
            if (!removedRowHash || removedRowHash[columnId] != addedRowHash[columnId]) {
              node = getCellNode(row, getColumnIndex(columnId))
              if (node) {
                $(node).addClass(addedRowHash[columnId])
              }
            }
          }
        }
      }
    }

    function addCellCssStyles(key, hash) {
      if (cellCssClasses[key]) {
        throw "addCellCssStyles: cell CSS hash with key '" + key + "' already exists."
      }

      cellCssClasses[key] = hash
      updateCellCssStylesOnRenderedRows(hash, null)

      trigger(self.onCellCssStylesChanged, {key, hash})
    }

    function removeCellCssStyles(key) {
      if (!cellCssClasses[key]) {
        return
      }

      updateCellCssStylesOnRenderedRows(null, cellCssClasses[key])
      delete cellCssClasses[key]

      trigger(self.onCellCssStylesChanged, {key, hash: null})
    }

    function setCellCssStyles(key, hash) {
      var prevHash = cellCssClasses[key]

      cellCssClasses[key] = hash
      updateCellCssStylesOnRenderedRows(hash, prevHash)

      trigger(self.onCellCssStylesChanged, {key, hash})
    }

    function getCellCssStyles(key) {
      return cellCssClasses[key]
    }

    function flashCell(row, cell, speed) {
      speed = speed || 100
      if (rowsCache[row]) {
        var $cell = $(getCellNode(row, cell))

        var toggleCellClass = function (times) {
          if (!times) {
            return
          }
          setTimeout(() => {
            $cell.queue(() => {
              $cell.toggleClass(options.cellFlashingCssClass).dequeue()
              toggleCellClass(times - 1)
            })
          }, speed)
        }

        toggleCellClass(4)
      }
    }

    // ////////////////////////////////////////////////////////////////////////////////////////////
    // Interactivity

    function handleDragInit(e, dd) {
      var cell = getCellFromEvent(e)
      if (!cell || !cellExists(cell.row, cell.cell)) {
        return false
      }

      var retval = trigger(self.onDragInit, dd, e)
      if (e.isImmediatePropagationStopped()) {
        return retval
      }

      // if nobody claims to be handling drag'n'drop by stopping immediate propagation,
      // cancel out of it
      return false
    }

    function handleDragStart(e, dd) {
      var cell = getCellFromEvent(e)
      if (!cell || !cellExists(cell.row, cell.cell)) {
        return false
      }

      var retval = trigger(self.onDragStart, dd, e)
      if (e.isImmediatePropagationStopped()) {
        return retval
      }

      return false
    }

    function handleDrag(e, dd) {
      return trigger(self.onDrag, dd, e)
    }

    function handleDragEnd(e, dd) {
      trigger(self.onDragEnd, dd, e)
    }

    function handleKeyDown(e) {
      trigger(self.onKeyDown, {row: activeRow, cell: activeCell}, e)

      // Canvas Hack: SlickGrid has unreasonable default behavior that is unavoidable without an early return here.
      if (e.originalEvent.skipSlickGridDefaults) {
        return
      }

      var handled = e.isImmediatePropagationStopped()

      if (!handled) {
        if (!e.shiftKey && !e.altKey && !e.ctrlKey) {
          if (e.which == 27) {
            if (!getEditorLock().isActive()) {
              return // no editing mode to cancel, allow bubbling and default processing (exit without cancelling the event)
            }
            cancelEditAndSetFocus()
          } else if (e.which == 34) {
            navigatePageDown()
            handled = true
          } else if (e.which == 33) {
            navigatePageUp()
            handled = true
          } else if (e.which == 37) {
            handled = navigateLeft()
          } else if (e.which == 39) {
            handled = navigateRight()
          } else if (e.which == 38) {
            handled = navigateUp()
          } else if (e.which == 40) {
            handled = navigateDown()
          } else if (e.which == 9) {
            handled = navigateNext()
          } else if (e.which == 13) {
            if (options.editable) {
              if (currentEditor) {
                // adding new row
                if (activeRow === getDataLength()) {
                  navigateDown()
                } else {
                  commitEditAndSetFocus()
                }
              } else if (getEditorLock().commitCurrentEdit()) {
                makeActiveCellEditable()
              }
            }
            handled = true
          }
        } else if (e.which == 9 && e.shiftKey && !e.ctrlKey && !e.altKey) {
          handled = navigatePrev()
        }
      }

      if (handled) {
        // the event has been handled so don't let parent element (bubbling/propagation) or browser (default) handle it
        e.stopPropagation()
        e.preventDefault()
        try {
          e.originalEvent.keyCode = 0 // prevent default behaviour for special keys in IE browsers (F3, F5, etc.)
        } catch (error) {
          // ignore exceptions - setting the original event's keycode throws access denied exception for "Ctrl"
          // (hitting control key only, nothing else), "Shift" (maybe others)
        }
      }
    }

    function handleClick(e) {
      if (!currentEditor) {
        // if this click resulted in some cell child node getting focus,
        // don't steal it back - keyboard events will still bubble up
        // IE9+ seems to default DIVs to tabIndex=0 instead of -1, so check for cell clicks directly.
        if (e.target != document.activeElement || $(e.target).hasClass('slick-cell')) {
          setFocus()
        }
      }

      var cell = getCellFromEvent(e)
      if (!cell || (currentEditor !== null && activeRow == cell.row && activeCell == cell.cell)) {
        return
      }

      trigger(self.onClick, {row: cell.row, cell: cell.cell}, e)
      if (e.isImmediatePropagationStopped()) {
        return
      }

      if (
        (activeCell != cell.cell || activeRow != cell.row) &&
        canCellBeActive(cell.row, cell.cell)
      ) {
        if (!getEditorLock().isActive() || getEditorLock().commitCurrentEdit()) {
          scrollRowIntoView(cell.row, false)
          // Always switch to edit mode if possible in response to a click
          setActiveCellInternal(getCellNode(cell.row, cell.cell), true)
        }
      }
    }

    function handleContextMenu(e) {
      var $cell = $(e.target).closest('.slick-cell', $canvas_1)
      if ($cell.length === 0) {
        return
      }

      // are we editing this cell?
      if (activeCellNode === $cell[0] && currentEditor !== null) {
        return
      }

      trigger(self.onContextMenu, {}, e)
    }

    function handleDblClick(e) {
      var cell = getCellFromEvent(e)
      if (!cell || (currentEditor !== null && activeRow == cell.row && activeCell == cell.cell)) {
        return
      }

      trigger(self.onDblClick, {row: cell.row, cell: cell.cell}, e)
      if (e.isImmediatePropagationStopped()) {
        return
      }

      if (options.editable) {
        gotoCell(cell.row, cell.cell, true)
      }
    }

    function handleHeaderMouseEnter(e) {
      trigger(
        self.onHeaderMouseEnter,
        {
          column: $(this).data('column'),
        },
        e
      )
    }

    function handleHeaderMouseLeave(e) {
      trigger(
        self.onHeaderMouseLeave,
        {
          column: $(this).data('column'),
        },
        e
      )
    }

    function handleHeaderContextMenu(e) {
      var $header = $(e.target).closest('.slick-header-column', '.slick-header-columns')
      var column = $header && $header.data('column')
      trigger(self.onHeaderContextMenu, {column}, e)
    }

    function handleHeaderClick(e) {
      var $header = $(e.target).closest('.slick-header-column', '.slick-header-columns')
      var column = $header && $header.data('column')
      if (column) {
        trigger(self.onHeaderClick, {column}, e)
      }
    }

    function handleMouseEnter(e) {
      trigger(self.onMouseEnter, {}, e)
    }

    function handleMouseLeave(e) {
      trigger(self.onMouseLeave, {}, e)
    }

    function cellExists(row, cell) {
      return !(row < 0 || row >= getDataLength() || cell < 0 || cell >= columns.length)
    }

    function getCellFromPoint(x, y) {
      var row = getRowFromPosition(y)
      var cell = 0

      var w = 0
      for (var i = 0; i < columns.length && w < x; i++) {
        w += columns[i].width
        cell++
      }

      if (cell < 0) {
        cell = 0
      }

      return {row, cell: cell - 1}
    }

    function getCellFromNode(cellNode) {
      // read column number from .b<columnNumber> CSS class
      var cls = /b\d+/.exec(cellNode.className)
      if (!cls) {
        throw 'getCellFromNode: cannot get cell - ' + cellNode.className
      }
      return parseInt(cls[0].substr(1, cls[0].length - 1), 10)
    }

    function getRowFromNode(rowNode) {
      for (var row in rowsCache) {
        var rowItem = rowsCache[row].rowNode
        if (rowItem.frozen === rowNode || rowItem.nonFrozen === rowNode) {
          return row | 0
        }
      }

      return null
    }

    function getCanvasFromEvent(e) {
      return $(e.target).closest('.grid-canvas')
    }

    function getCellFromEvent(e) {
      var closestCanvas = getCanvasFromEvent(e)
      var $cell = $(e.target).closest('.slick-cell', closestCanvas)
      if (!$cell.length) {
        return null
      }

      var row = getRowFromNode($cell[0].parentNode)
      var cell = getCellFromNode($cell[0])

      if (row == null || cell == null) {
        return null
      } else {
        return {
          row,
          cell,
        }
      }
    }

    function getCellNodeBox(row, cell) {
      if (!cellExists(row, cell)) {
        return null
      }

      var y1 = getRowTop(row)
      var y2 = y1 + options.rowHeight - 1
      var x1 = 0
      for (var i = 0; i < cell; i++) {
        x1 += columns[i].width
      }
      var x2 = x1 + columns[cell].width

      return {
        top: y1,
        [rear]: x1,
        bottom: y2,
        [front]: x2,
      }
    }

    // ////////////////////////////////////////////////////////////////////////////////////////////
    // Cell switching

    function resetActiveCell() {
      setActiveCellInternal(null, false)
    }

    function setFocus() {
      if (tabbingDirection == -1) {
        $focusSink[0].focus()
      } else {
        $focusSink2[0].focus()
      }
    }

    function scrollCellIntoView(row, cell, doPaging) {
      scrollRowIntoView(row, doPaging)

      var colspan = getColspan(row, cell)
      var rearVal = columnPosRear[cell],
        frontVal = columnPosFront[cell + (colspan > 1 ? colspan - 1 : 0)],
        scrollRight = scrollLeft + viewportW_1

      if ((rtl ? adjustXToRight(frontVal) : rearVal) < scrollLeft) {
        // cell is to left of displayed cells
        setScrollLeft($viewport_1[0], rtl ? Math.max(0, adjustXToRight(frontVal)) : rearVal)
        handleScroll()
        render()
      } else if ((rtl ? adjustXToRight(rearVal) : frontVal) > scrollRight) {
        // cell is to right of displayed cells
        setScrollLeft(
          $viewport_1[0],
          rtl ? adjustXToRight(frontVal) : Math.min(rearVal, frontVal - $viewport_1[0].clientWidth)
        )
        handleScroll()
        render()
      }
    }

    function setActiveCellInternal(newCell, opt_editMode) {
      if (activeCellNode !== null) {
        makeActiveCellNormal()
        $(activeCellNode).removeClass('active')
        if (rowsCache[activeRow]) {
          $(rowsCache[activeRow].rowNode.frozen).removeClass('active')
          $(rowsCache[activeRow].rowNode.nonFrozen).removeClass('active')
        }
      }

      var activeCellChanged = activeCellNode !== newCell
      activeCellNode = newCell

      if (activeCellNode != null) {
        activeRow = getRowFromNode(activeCellNode.parentNode)
        activeCell = activePosX = getCellFromNode(activeCellNode)

        if (opt_editMode == null) {
          opt_editMode =
            (activeRow == getDataLength() || options.autoEdit) && !isCustomColumn(activeCell)
        }

        $(activeCellNode).addClass('active')
        $(rowsCache[activeRow].rowNode.frozen).addClass('active')
        $(rowsCache[activeRow].rowNode.nonFrozen).addClass('active')

        if (options.editable && opt_editMode && isCellPotentiallyEditable(activeRow, activeCell)) {
          clearTimeout(h_editorLoader)

          if (options.asyncEditorLoading) {
            h_editorLoader = setTimeout(() => {
              makeActiveCellEditable()
            }, options.asyncEditorLoadDelay)
          } else {
            makeActiveCellEditable()
          }
        }
      } else {
        activeRow = activeCell = null
      }

      if (activeCellChanged) {
        trigger(self.onActiveCellChanged, getActiveCell())
      }
    }

    function clearTextSelection() {
      if (document.selection && document.selection.empty) {
        try {
          // IE fails here if selected element is not in dom
          document.selection.empty()
        } catch (e) {}
      } else if (window.getSelection) {
        var sel = window.getSelection()
        if (sel && sel.removeAllRanges) {
          sel.removeAllRanges()
        }
      }
    }

    function isCellPotentiallyEditable(row, cell) {
      // is the data for this row loaded?
      if (row < getDataLength() && !getDataItem(row)) {
        return false
      }

      // are we in the Add New row?  can we create new from this cell?
      if (columns[cell].cannotTriggerInsert && row >= getDataLength()) {
        return false
      }

      // does this cell have an editor?
      if (!getEditor(row, cell)) {
        return false
      }

      return true
    }

    function makeActiveCellNormal() {
      if (!currentEditor) {
        return
      }
      trigger(self.onBeforeCellEditorDestroy, {editor: currentEditor})
      currentEditor.destroy()
      currentEditor = null

      if (activeCellNode) {
        var d = getDataItem(activeRow)
        $(activeCellNode).removeClass('editable invalid')
        if (d) {
          var column = columns[activeCell]
          var formatter = getFormatter(activeRow, column)
          activeCellNode.innerHTML = formatter(
            activeRow,
            activeCell,
            getDataItemValueForColumn(d, column),
            column,
            d
          )
          invalidatePostProcessingResults(activeRow)
        }
      }

      // if there previously was text selected on a page (such as selected text in the edit cell just removed),
      // IE can't set focus to anything else correctly
      if (navigator.userAgent.toLowerCase().match(/msie/)) {
        clearTextSelection()
      }

      getEditorLock().deactivate(editController)
    }

    function makeActiveCellEditable(editor) {
      if (!activeCellNode) {
        return
      }
      if (!options.editable) {
        throw 'Grid : makeActiveCellEditable : should never get called when options.editable is false'
      }

      // cancel pending async call if there is one
      clearTimeout(h_editorLoader)

      if (!isCellPotentiallyEditable(activeRow, activeCell)) {
        return
      }

      var columnDef = columns[activeCell]
      var item = getDataItem(activeRow)

      if (
        trigger(self.onBeforeEditCell, {
          row: activeRow,
          cell: activeCell,
          item,
          column: columnDef,
        }) === false
      ) {
        setFocus()
        return
      }

      getEditorLock().activate(editController)
      $(activeCellNode).addClass('editable')

      // don't clear the cell if a custom editor is passed through
      if (!editor) {
        activeCellNode.innerHTML = ''
      }

      currentEditor = new (editor || getEditor(activeRow, activeCell))({
        activeRow,
        grid: self,
        gridPosition: absBox($outerContainer[0]),
        position: absBox(activeCellNode),
        container: activeCellNode,
        column: columnDef,
        item: item || {},
        commitChanges: commitEditAndSetFocus,
        cancelChanges: cancelEditAndSetFocus,
        maxLength: columns[activeCell].maxLength,
      })

      if (item) {
        currentEditor.loadValue(item)
      }

      serializedEditorValue = currentEditor.serializeValue()

      if (currentEditor.position) {
        handleActiveCellPositionChange()
      }
    }

    function commitEditAndSetFocus() {
      // if the commit fails, it would do so due to a validation error
      // if so, do not steal the focus from the editor
      if (getEditorLock().commitCurrentEdit()) {
        setFocus()
        if (options.autoEdit && !isCustomColumn(activeCell)) {
          navigateDown()
        }
      }
    }

    function cancelEditAndSetFocus() {
      if (getEditorLock().cancelCurrentEdit()) {
        setFocus()
      }
    }

    function adjustXToRight(x) {
      return canvasWidth_1 - x
    }

    function getScrollLeft(elm) {
      return elm.scrollLeft
    }

    function setScrollLeft(elm, val) {
      elm.scrollLeft = val
    }

    function getOffsetLeft(elm) {
      return elm.offsetLeft
    }

    function getOffsetRight(elm) {
      return document.body.offsetWidth - (elm.offsetLeft + elm.offsetWidth)
    }

    getOffsetRear = getOffsetLeft

    function absBox(elem) {
      var box = {
        top: elem.offsetTop,
        bottom: 0,
        width: $(elem).outerWidth(),
        height: $(elem).outerHeight(),
        visible: true,
      }
      box.bottom = box.top + box.height
      box[rear] = getOffsetRear(elem)
      box[front] = box[rear] + box.width

      // walk up the tree
      var offsetParent = elem.offsetParent
      while ((elem = elem.parentNode) != document.body) {
        if (
          box.visible &&
          elem.scrollHeight != elem.offsetHeight &&
          $(elem).css('overflowY') != 'visible'
        ) {
          box.visible = box.bottom > elem.scrollTop && box.top < elem.scrollTop + elem.clientHeight
        }

        if (
          box.visible &&
          elem.scrollWidth != elem.offsetWidth &&
          $(elem).css('overflowX') != 'visible'
        ) {
          box.visible =
            box[front] > elem.scrollLeft && box[rear] < elem.scrollLeft + elem.clientWidth
        }

        box[rear] -= elem.scrollLeft
        box.top -= elem.scrollTop

        if (elem === offsetParent) {
          box[rear] += elem.scrollLeft
          box.top += elem.offsetTop
          offsetParent = elem.offsetParent
        }

        box.bottom = box.top + box.height
        box[front] = box[rear] + box.width
      }

      return box
    }

    function getActiveCellPosition() {
      return absBox(activeCellNode)
    }

    function getGridPosition() {
      return absBox($outerContainer[0])
    }

    function handleActiveCellPositionChange() {
      if (!activeCellNode) {
        return
      }

      trigger(self.onActiveCellPositionChanged, {})

      if (currentEditor) {
        var cellBox = getActiveCellPosition()
        if (currentEditor.show && currentEditor.hide) {
          if (!cellBox.visible) {
            currentEditor.hide()
          } else {
            currentEditor.show()
          }
        }

        if (currentEditor.position) {
          currentEditor.position(cellBox)
        }
      }
    }

    function getCellEditor() {
      return currentEditor
    }

    function getActiveCell() {
      if (!activeCellNode) {
        return null
      } else {
        return {row: activeRow, cell: activeCell}
      }
    }

    function getActiveCellNode() {
      return activeCellNode
    }

    function scrollRowIntoView(row, doPaging) {
      var rowAtTop = row * options.rowHeight
      var rowAtBottom =
        (row + 1) * options.rowHeight -
        viewportH_1 +
        (viewportHasHScroll_1 ? scrollbarDimensions.height : 0)

      // need to page down?
      if ((row + 1) * options.rowHeight > scrollTop + viewportH_1 + offset) {
        scrollTo(doPaging ? rowAtTop : rowAtBottom)
        render()
      }
      // or page up?
      else if (row * options.rowHeight < scrollTop + offset) {
        scrollTo(doPaging ? rowAtBottom : rowAtTop)
        render()
      }
    }

    function scrollRowToTop(row) {
      scrollTo(row * options.rowHeight)
      render()
    }

    function scrollPage(dir) {
      var deltaRows = dir * numVisibleRows
      scrollTo((getRowFromPosition(scrollTop) + deltaRows) * options.rowHeight)
      render()

      if (options.enableCellNavigation && activeRow != null) {
        var row = activeRow + deltaRows
        if (row >= getDataLengthIncludingAddNew()) {
          row = getDataLengthIncludingAddNew() - 1
        }
        if (row < 0) {
          row = 0
        }

        var cell = 0,
          prevCell = null
        var prevActivePosX = activePosX
        while (cell <= activePosX) {
          if (canCellBeActive(row, cell)) {
            prevCell = cell
          }
          cell += getColspan(row, cell)
        }

        if (prevCell !== null) {
          setActiveCellInternal(getCellNode(row, prevCell))
          activePosX = prevActivePosX
        } else {
          resetActiveCell()
        }
      }
    }

    function navigatePageDown() {
      scrollPage(1)
    }

    function navigatePageUp() {
      scrollPage(-1)
    }

    function getColspan(row, cell) {
      var metadata = data.getItemMetadata && data.getItemMetadata(row)
      if (!metadata || !metadata.columns) {
        return 1
      }

      var columnData = metadata.columns[columns[cell].id] || metadata.columns[cell]
      var colspan = columnData && columnData.colspan
      if (colspan === '*') {
        colspan = columns.length - cell
      } else {
        colspan = colspan || 1
      }

      return colspan
    }

    function findFirstFocusableCell(row) {
      var cell = 0
      while (cell < columns.length) {
        if (canCellBeActive(row, cell)) {
          return cell
        }
        cell += getColspan(row, cell)
      }
      return null
    }

    function findLastFocusableCell(row) {
      var cell = 0
      var lastFocusableCell = null
      while (cell < columns.length) {
        if (canCellBeActive(row, cell)) {
          lastFocusableCell = cell
        }
        cell += getColspan(row, cell)
      }
      return lastFocusableCell
    }

    function gotoFront(row, cell, _posX) {
      if (cell >= columns.length) {
        return null
      }

      do {
        cell += getColspan(row, cell)
      } while (cell < columns.length && !canCellBeActive(row, cell))

      if (cell < columns.length) {
        return {
          row,
          cell,
          posX: cell,
        }
      }
      return null
    }

    function gotoRear(row, cell, _posX) {
      if (cell <= 0) {
        return null
      }

      var firstFocusableCell = findFirstFocusableCell(row)
      if (firstFocusableCell === null || firstFocusableCell >= cell) {
        return null
      }

      var prev = {
        row,
        cell: firstFocusableCell,
        posX: firstFocusableCell,
      }
      var pos
      while (true) {
        pos = gotoFront(prev.row, prev.cell, prev.posX)
        if (!pos) {
          return null
        }
        if (pos.cell >= cell) {
          return prev
        }
        prev = pos
      }
    }

    gotoRight = gotoFront
    gotoLeft = gotoRear

    function gotoDown(row, cell, posX) {
      var prevCell
      while (true) {
        if (++row >= getDataLengthIncludingAddNew()) {
          return null
        }

        prevCell = cell = 0
        while (cell <= posX) {
          prevCell = cell
          cell += getColspan(row, cell)
        }

        if (canCellBeActive(row, prevCell)) {
          return {
            row,
            cell: prevCell,
            posX,
          }
        }
      }
    }

    function gotoUp(row, cell, posX) {
      var prevCell
      while (true) {
        if (--row < 0) {
          return null
        }

        prevCell = cell = 0
        while (cell <= posX) {
          prevCell = cell
          cell += getColspan(row, cell)
        }

        if (canCellBeActive(row, prevCell)) {
          return {
            row,
            cell: prevCell,
            posX,
          }
        }
      }
    }

    function gotoNext(row, cell, posX) {
      if (row == null && cell == null) {
        row = cell = posX = 0
        if (canCellBeActive(row, cell)) {
          return {
            row,
            cell,
            posX: cell,
          }
        }
      }

      var pos = gotoFront(row, cell, posX)
      if (pos) {
        return pos
      }

      var firstFocusableCell = null
      while (++row < getDataLengthIncludingAddNew()) {
        firstFocusableCell = findFirstFocusableCell(row)
        if (firstFocusableCell !== null) {
          return {
            row,
            cell: firstFocusableCell,
            posX: firstFocusableCell,
          }
        }
      }
      return null
    }

    function gotoPrev(row, cell, posX) {
      if (row == null && cell == null) {
        row = getDataLengthIncludingAddNew() - 1
        cell = posX = columns.length - 1
        if (canCellBeActive(row, cell)) {
          return {
            row,
            cell,
            posX: cell,
          }
        }
      }

      var pos
      var lastSelectableCell
      while (!pos) {
        pos = gotoRear(row, cell, posX)
        if (pos) {
          break
        }
        if (--row < 0) {
          return null
        }

        cell = 0
        lastSelectableCell = findLastFocusableCell(row)
        if (lastSelectableCell !== null) {
          pos = {
            row,
            cell: lastSelectableCell,
            posX: lastSelectableCell,
          }
        }
      }
      return pos
    }

    function navigateRight() {
      return navigate('right')
    }

    function navigateLeft() {
      return navigate('left')
    }

    function navigateDown() {
      return navigate('down')
    }

    function navigateUp() {
      return navigate('up')
    }

    function navigateNext() {
      return navigate('next')
    }

    function navigatePrev() {
      return navigate('prev')
    }

    /**
     * @param {string} dir Navigation direction.
     * @return {boolean} Whether navigation resulted in a change of active cell.
     */
    function navigate(dir) {
      if (!options.enableCellNavigation) {
        return false
      }

      if (!activeCellNode && dir != 'prev' && dir != 'next') {
        return false
      }

      if (!getEditorLock().commitCurrentEdit()) {
        return true
      }
      setFocus()

      var tabbingDirections = {
        up: -1,
        down: 1,
        left: -1,
        right: 1,
        prev: -1,
        next: 1,
      }
      tabbingDirection = tabbingDirections[dir]

      var stepFunctions = {
        up: gotoUp,
        down: gotoDown,
        left: gotoLeft,
        right: gotoRight,
        prev: gotoPrev,
        next: gotoNext,
      }
      var stepFn = stepFunctions[dir]
      var pos = stepFn(activeRow, activeCell, activePosX)
      if (pos) {
        var isAddNewRow = pos.row == getDataLength()
        scrollCellIntoView(pos.row, pos.cell, !isAddNewRow)
        setActiveCellInternal(getCellNode(pos.row, pos.cell))
        activePosX = pos.posX
        return true
      } else if (activeRow === getDataLength() - 1) {
        if (activeCell === columns.length - 1) {
          // When focus is on the last cell in a row
          // and the last cell in a column.
          // Move focus outside of SlickGrid.
          return false
        }
        // Otherwise, when focus is on the last cell in a column.
        // Move focus to the first cell of the next column.
        setActiveCell(0, activeCell + 1)
        return true
      }
    }

    function getCellNode(row, cell) {
      if (rowsCache[row]) {
        ensureCellNodesInRowsCache(row)
        return rowsCache[row].cellNodesByColumnIdx[cell]
      }
      return null
    }

    function setActiveCell(row, cell) {
      if (!initialized) {
        return
      }
      if (row > getDataLength() || row < 0 || cell >= columns.length || cell < 0) {
        return
      }

      if (!options.enableCellNavigation) {
        return
      }

      scrollCellIntoView(row, cell, false)
      setActiveCellInternal(getCellNode(row, cell), false)
    }

    function canCellBeActive(row, cell) {
      if (
        !options.enableCellNavigation ||
        row >= getDataLengthIncludingAddNew() ||
        row < 0 ||
        cell >= columns.length ||
        cell < 0
      ) {
        return false
      }

      var rowMetadata = data.getItemMetadata && data.getItemMetadata(row)
      if (rowMetadata && typeof rowMetadata.focusable === 'boolean') {
        return rowMetadata.focusable
      }

      var columnMetadata = rowMetadata && rowMetadata.columns
      if (
        columnMetadata &&
        columnMetadata[columns[cell].id] &&
        typeof columnMetadata[columns[cell].id].focusable === 'boolean'
      ) {
        return columnMetadata[columns[cell].id].focusable
      }
      if (
        columnMetadata &&
        columnMetadata[cell] &&
        typeof columnMetadata[cell].focusable === 'boolean'
      ) {
        return columnMetadata[cell].focusable
      }

      return columns[cell].focusable
    }

    function canCellBeSelected(row, cell) {
      if (row >= getDataLength() || row < 0 || cell >= columns.length || cell < 0) {
        return false
      }

      var rowMetadata = data.getItemMetadata && data.getItemMetadata(row)
      if (rowMetadata && typeof rowMetadata.selectable === 'boolean') {
        return rowMetadata.selectable
      }

      var columnMetadata =
        rowMetadata &&
        rowMetadata.columns &&
        (rowMetadata.columns[columns[cell].id] || rowMetadata.columns[cell])
      if (columnMetadata && typeof columnMetadata.selectable === 'boolean') {
        return columnMetadata.selectable
      }

      return columns[cell].selectable
    }

    function gotoCell(row, cell, forceEdit) {
      if (!initialized) {
        return
      }
      if (!canCellBeActive(row, cell)) {
        return
      }

      if (!getEditorLock().commitCurrentEdit()) {
        return
      }

      scrollCellIntoView(row, cell, false)

      var newCell = getCellNode(row, cell)

      // Custom columns should not auto-edit when accessed via keyboard navigation
      const autoEditDestinationCell = options.autoEdit && !isCustomColumn(cell)
      // if selecting the 'add new' row, start editing right away
      setActiveCellInternal(
        newCell,
        forceEdit || row === getDataLength() || autoEditDestinationCell
      )

      // if no editor was created, set the focus back on the grid
      if (!currentEditor) {
        setFocus()
      }
    }

    // ////////////////////////////////////////////////////////////////////////////////////////////
    // IEditor implementation for the editor lock

    function commitCurrentEdit() {
      var item = getDataItem(activeRow)
      var column = columns[activeCell]

      if (currentEditor) {
        if (currentEditor.isValueChanged()) {
          var validationResults = currentEditor.validate()

          if (validationResults.valid) {
            if (activeRow < getDataLength()) {
              var editCommand = {
                row: activeRow,
                cell: activeCell,
                editor: currentEditor,
                serializedValue: currentEditor.serializeValue(),
                prevSerializedValue: serializedEditorValue,
                execute () {
                  this.editor.applyValue(item, this.serializedValue)
                  updateRow(this.row)
                },
                undo () {
                  this.editor.applyValue(item, this.prevSerializedValue)
                  updateRow(this.row)
                },
              }

              if (options.editCommandHandler) {
                makeActiveCellNormal()
                options.editCommandHandler(item, column, editCommand)
              } else {
                editCommand.execute()
                makeActiveCellNormal()
              }

              trigger(self.onCellChange, {
                row: activeRow,
                cell: activeCell,
                column,
                item,
              })
            } else {
              var newItem = {}
              currentEditor.applyValue(newItem, currentEditor.serializeValue())
              makeActiveCellNormal()
              trigger(self.onAddNewRow, {item: newItem, column})
            }

            // check whether the lock has been re-acquired by event handlers
            return !getEditorLock().isActive()
          } else {
            // Re-add the CSS class to trigger transitions, if any.
            $(activeCellNode).removeClass('invalid')
            $(activeCellNode).width() // force layout
            $(activeCellNode).addClass('invalid')

            trigger(self.onValidationError, {
              editor: currentEditor,
              cellNode: activeCellNode,
              validationResults,
              row: activeRow,
              cell: activeCell,
              column,
            })

            currentEditor.focus()
            return false
          }
        }

        makeActiveCellNormal()
      }
      return true
    }

    function cancelCurrentEdit() {
      makeActiveCellNormal()
      return true
    }

    function rowsToRanges(rows) {
      var ranges = []
      var lastCell = columns.length - 1
      for (var i = 0; i < rows.length; i++) {
        ranges.push(new Slick.Range(rows[i], 0, rows[i], lastCell))
      }
      return ranges
    }

    function getSelectedRows() {
      if (!selectionModel) {
        throw 'Selection model is not set'
      }
      return selectedRows
    }

    function setSelectedRows(rows) {
      if (!selectionModel) {
        throw 'Selection model is not set'
      }
      selectionModel.setSelectedRanges(rowsToRanges(rows))
    }

    function isCustomColumn(cell) {
      return columns[cell]?.type === 'custom_column'
    }

    // ////////////////////////////////////////////////////////////////////////////////////////////
    // Debug

    this.debug = function () {
      var s = ''

      s += '\n' + 'counter_rows_rendered:  ' + counter_rows_rendered
      s += '\n' + 'counter_rows_removed:  ' + counter_rows_removed
      s += '\n' + 'renderedRows:  ' + renderedRows
      s += '\n' + 'numVisibleRows:  ' + numVisibleRows
      s += '\n' + 'maxSupportedCssHeight:  ' + maxSupportedCssHeight
      s += '\n' + 'n(umber of pages):  ' + n
      s += '\n' + '(current) page:  ' + page
      s += '\n' + 'page height (ph):  ' + ph
      s += '\n' + 'vScrollDir:  ' + vScrollDir

      alert(s)
    }

    // a debug helper to be able to access private members
    this.eval = function (expr) {
      return eval(expr)
    }

    // ////////////////////////////////////////////////////////////////////////////////////////////
    // Public API

    $.extend(this, {
      slickGridVersion: '2.1',

      // Events
      onScroll: new Slick.Event(),
      onSort: new Slick.Event(),
      onHeaderMouseEnter: new Slick.Event(),
      onHeaderMouseLeave: new Slick.Event(),
      onHeaderContextMenu: new Slick.Event(),
      onHeaderClick: new Slick.Event(),
      onHeaderCellRendered: new Slick.Event(),
      onBeforeHeaderCellDestroy: new Slick.Event(),
      onHeaderRowCellRendered: new Slick.Event(),
      onBeforeHeaderRowCellDestroy: new Slick.Event(),
      onMouseEnter: new Slick.Event(),
      onMouseLeave: new Slick.Event(),
      onClick: new Slick.Event(),
      onDblClick: new Slick.Event(),
      onContextMenu: new Slick.Event(),
      onKeyDown: new Slick.Event(),
      onAddNewRow: new Slick.Event(),
      onValidationError: new Slick.Event(),
      onViewportChanged: new Slick.Event(),
      onColumnsReordered: new Slick.Event(),
      onColumnsResized: new Slick.Event(),
      onCellChange: new Slick.Event(),
      onBeforeEditCell: new Slick.Event(),
      onBeforeCellEditorDestroy: new Slick.Event(),
      onBeforeDestroy: new Slick.Event(),
      onActiveCellChanged: new Slick.Event(),
      onActiveCellPositionChanged: new Slick.Event(),
      onDragInit: new Slick.Event(),
      onDragStart: new Slick.Event(),
      onDrag: new Slick.Event(),
      onDragEnd: new Slick.Event(),
      onSelectedRowsChanged: new Slick.Event(),
      onCellCssStylesChanged: new Slick.Event(),

      // Methods
      registerPlugin,
      unregisterPlugin,
      getColumns,
      setColumns,
      getColumnIndex,
      updateColumnHeader,
      setNumberOfColumnsToFreeze,
      setSortColumn,
      setSortColumns,
      getSortColumns,
      autosizeColumns,
      getOptions,
      setOptions,
      getData,
      getDataLength,
      getDataItem,
      setData,
      getSelectionModel,
      setSelectionModel,
      getSelectedRows,
      setSelectedRows,
      getContainerNode,

      render,
      invalidate,
      invalidateRow,
      invalidateRows,
      invalidateAllRows,
      updateCell,
      updateRow,
      getViewport: getVisibleRange,
      getRenderedRange,
      resizeCanvas,
      updateRowCount,
      scrollRowIntoView,
      scrollRowToTop,
      scrollCellIntoView,
      getCanvasNode,
      focus: setFocus,

      getCellFromPoint,
      getCellFromEvent,
      getActiveCell,
      setActiveCell,
      getActiveCellNode,
      getActiveCellPosition,
      resetActiveCell,
      editActiveCell: makeActiveCellEditable,
      getCellEditor,
      getCellNode,
      getCellNodeBox,
      canCellBeSelected,
      canCellBeActive,
      navigatePrev,
      navigateNext,
      navigateUp,
      navigateDown,
      navigateLeft,
      navigateRight,
      navigatePageUp,
      navigatePageDown,
      gotoCell,
      getTopPanel,
      setTopPanelVisibility,
      setHeaderRowVisibility,
      getHeaderRow,
      getHeaderRowColumn,
      getColumnHeaderNode,
      getGridPosition,
      flashCell,
      addCellCssStyles,
      setCellCssStyles,
      removeCellCssStyles,
      getCellCssStyles,
      getUID,

      init: finishInitialization,
      destroy,

      // IEditor implementation
      getEditorLock,
      getEditController,
    })

    init()
  }
