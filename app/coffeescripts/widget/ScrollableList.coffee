#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'compiled/util/ScrollableListDataSource'
  'compiled/util/shortcut'
  'compiled/jquery/scrollIntoView'
  'jquery.disableWhileLoading'
], (ScrollableListDataSource, shortcut) ->

  class
    shortcut this, 'ds',
      'addItem'
      'updateItems'
      'removeItem'

    constructor: (@$scroller, options={}) ->
      @$scroller.css('overflow', 'auto')
      @ds = new ScrollableListDataSource(this, options)
      @$scroller.scroll (e) =>
        @scroll(e)
      @$list = @$scroller.find('ul').eq(0)
      @$list = $('<ul>').appendTo(@$scroller) unless @$list.length
      @$list.addClass('scrollable-list')

      @itemTemplate  = options.itemTemplate  ? (data) => "<li>#{data}</li>"
      @elementHeight = options.elementHeight ? @inferElementHeight()
      @fetchBuffer   = options.fetchBuffer   ? 20 # how many items to fetch on either side of the viewable pane
      @firstLoad     = true
      @load() unless options.noAutoLoad
      @$list.delegate '.scrollable-list > li', 'click', @clicked if @clicked

    item: (id) ->
      @ds.items[@positionFor(id)]

    $item: (id) ->
      $item = @$itemAt(@positionFor(id))
      $item if $item.length

    $itemAt: (pos) ->
      @$items().eq pos

    $items: ->
      @$list.find('> li').not('.scrollable-list-item-deleting,.scrollable-list-item-moving')

    addedItem: (item, offset) ->
      @prepareItems(offset - 1) # ensure enough li's are created if we're inserting it toward the bottom
      $newItem = $(@itemTemplate(item))
      if offset is 0
        $newItem.prependTo @$list
      else
        $newItem.insertAfter @$itemAt(offset - 1)
      @setCount(@ds.itemIds.length)
      @added?(item, $newItem)

    updateItem: (item) ->
      @updateItems([item])

    updatedItem: (item, currOffset, newOffset) ->
      @prepareItems(Math.max(newOffset - 1, currOffset)) # ensure enough li's are created if we're moving it toward (or from) the bottom
      @$itemAt(currOffset).replaceWith(@itemTemplate(item))
      $items = @$items()
      $item = $items.eq(currOffset)

      if currOffset isnt newOffset
        $newItem = $item.clone()
        $item.addClass('scrollable-list-item-moving').animate {opacity: 'toggle', height: 'toggle'}, 200, ->
          $item.remove()
        if newOffset is 0
          $newItem.prependTo @$list
        else
          $newItem.insertAfter $items.eq(newOffset - 1)
        $newItem.animate({opacity: 'toggle', height: 'toggle'}, 0).
          animate {opacity: 'toggle', height: 'toggle'}, 200, =>
            $newItem.scrollIntoView()
      @updated?(item, $newItem ? $item)

    removedItem: (item, offset) ->
      $item = @$itemAt(offset)
      $item.addClass('scrollable-list-item-deleting').fadeOut 'fast', =>
        $item.remove()
        @setCount(@ds.itemIds.length)
        @fetchVisible()
      @removed?(item, $item)

    replaceItems: (offset, items, totalCount) ->
      @setCount(totalCount)
      @prepareItems(offset - 1)
      $items = @$items().slice(offset, offset + items.length)
      newItems = []
      if $items.length < items.length
        newItems = items.slice($items.length)
        items = items.slice(0, $items.length)
      $((@itemTemplate(item) for item in items).join('')).insertBefore($items.eq(0))
      $items.remove()
      @$list.append (@itemTemplate(item) for item in newItems).join("") if newItems.length

    fetchVisible: ->
      return [] unless @ds.itemIds

      fetchStart = Math.floor(@$scroller.scrollTop() / @elementHeight)
      fetchEnd   = Math.floor((@$scroller.scrollTop() + @$scroller.height() - 1) / @elementHeight) + @fetchBuffer
      fetchEnd   = Math.max(@numItems, 1) - 1 if fetchEnd >= @numItems
      fetchStart = Math.max(0, fetchStart - @fetchBuffer)

      @prepareItems(fetchEnd)
      @ds.fetchRange(fetchStart, fetchEnd)

    prepareItems: (renderThrough) ->
      newItems = renderThrough - @$items().length
      if newItems > 0
        # create placeholders for the stuff we're getting
        @$list.append ("<li class='scrollable-list-item-loading' />" for i in [0..newItems]).join('')

    scroll: ->
      clearTimeout @scrollCb if @scrollCb
      @scrollCb = setTimeout =>
        delete @scrollCb
        @fetchVisible()
      , 50

    inferElementHeight: ->
      $dummy = $(@itemTemplate({})).appendTo(@$list)
      height = $dummy.height()
      $dummy.remove()
      height

    positionFor: (id) ->
      @ds.itemMap[id]

    loadItem: (id) ->
      if id? and (pos = @positionFor(id))?
        @prepareItems(pos) # ensure the li exists
        @$item(id).scrollIntoView(toTop: @firstLoad)
      deferreds = @fetchVisible()
      deferreds = [{}] unless deferreds.length
      $.when(deferreds...).done =>
        [item, $node] = [@ds.items[pos], @$item(id)] if pos?
        @loaded?(id, item, $node)

    load: (options={}) ->
      sortKeyChanged = options.sortKey and options.sortKey isnt @ds.sortKey
      paramsChanged = options.params and JSON.stringify(options.params) isnt JSON.stringify(@ds.params)
      if sortKeyChanged or paramsChanged or not @ds.initialized
        @fetchThrough = 0
        @$list.empty()
        @$list.css('min-height', '0px')
        deferred = @ds.load options, (totalCount) =>
          @setCount(totalCount)
          @loadItem(options.loadId)
          options.cb?()
          @firstLoad = false
        @$scroller.disableWhileLoading deferred
      else
        @loadItem(options.loadId)
        @firstLoad = false

    setCount: (@numItems) ->
      @$list.css('min-height', (@elementHeight * @numItems) + 'px')
      $items = @$items()
      if $items.length > @numItems
        $items.slice(@numItems).remove()
