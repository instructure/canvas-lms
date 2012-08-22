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
  'jquery'
  'jquery.ajaxJSON'
], ($) ->

  class
    constructor: (@list, options) ->
      @pageOffset = options.pageOffset ? 1 # i.e. api pages start with 1 rather than 0
      @perPage    = options.perPage    ? 25
      @pageKey    = options.pageKey    ? 'page'
      @perPageKey = options.perPageKey ? 'per_page'
      @itemIdsKey = options.itemIdsKey ? 'item_ids'
      @itemsKey   = options.itemsKey   ? 'items'
      @sortKey    = options.sortKey    ? 'id'
      @sortDir    = options.sortDir    ? 'asc'
      @params     = options.params     ? {}
      @baseUrl    = options.baseUrl
      @model      = options.model

    load: (options, cb) ->
      @initialized = true
      @sortKey = options.sortKey if options.sortKey?
      @params = options.params if options.params?
      @itemIds = null
      @items = []
      @pages = []
      @resetRequests()
      @fetchPage 0, cb

    addItem: (item) ->
      @_addItem(@modelize(item))
      @recompute()

    updateItems: (items) ->
      items = @modelize(items)
      doTransitions = (items.length <= 1)
      for item in items
        if not item.get('visible') and not item.get('defer_visibility_check')
          @_removeItem(item, doTransitions)
        else if @itemMap[item.id]?
          @_updateItem(item, doTransitions)
        else
          @_addItem(item, doTransitions)
      @recompute(not doTransitions)

    removeItem: (item) ->
      @_removeItem(@modelize(item))
      @recompute()

    modelize: (data) ->
      modelize = (item) =>
        item = new @model(item)
        item.list = @list
        item

      if data.length?
        (modelize(item) for item in data)
      else
        modelize(data)

    positionOrReload: (item, currPos) ->
      pos = @positionFor(item, currPos)
      if pos? and not @deferredPositionChecks
        pos
      else
        # we couldn't determine where they go, so we'll batch it up w/ any other
        # ones, refetch the first page (which might refetch other stale stuff),
        # and use the server-specified positions
        @deferredPositionChecks ?= []
        @deferredPositionChecks.push item.id
        null

    # if it returns:
    # 0..@itemIds.length  : we know exactly where it should go
    # null                : it goes in an unloaded section (intermediate or end)
    positionFor: (item, currPos) ->
      goesBefore = (if @sortDir is 'asc'
        (a, b) => a.get(@sortKey) < b.get(@sortKey)
      else
        (a, b) => a.get(@sortKey) > b.get(@sortKey)
      )
      for i in [0...(@items.length - 1)]
        if @items[i]
          unmoved = currPos is i and item.id is @items[i].id and item.get(@sortKey) is @items[i].get(@sortKey)
          if unmoved or goesBefore(item, @items[i])
            return null if i > 1 and not @items[i - 1] # i.e. unloaded section
            return i
      if @items.length is @itemIds.length or @itemIds.length is 0
        return @itemIds.length

    refreshList: () ->
      for page in [0...@pages.length] when @pages[page] is 'loaded'
        offset = page * @perPage
        @list.replaceItems(offset, @items.slice(offset, Math.min(offset + @perPage, @itemIds.length)), @itemIds.length)

    fetchRange: (start, end=start) ->
      return [] unless @itemIds
      startPage = Math.floor(start / @perPage)
      endPage = Math.floor(end / @perPage)
      endPage = Math.min(endPage, Math.floor(@itemIds.length / @perPage))
      @fetchPage page for page in [startPage..endPage] when not @pages[page]
      @requests

    fetchPage: (page, cb) ->
      params = $.extend({}, @params)
      params[@perPageKey] = @perPage
      params[@pageKey] = page + @pageOffset

      @pages[page] = 'loading'
      @requests[page]?.abort()
      @requests[page] = $.ajaxJSON @baseUrl,
        'GET',
        params,
        (data) =>
          delete @requests[page]
          items = @modelize(data[@itemsKey])
          itemIds = data[@itemIdsKey]
          @fetchedPage(page, itemIds, items)
          cb?(itemIds.length)

    fetchedPage: (page, itemIds, items) ->
      offset = page * @perPage
      numToReplace = items.length
      numToReplace = ([] ? @itemIds).length - offset if itemIds.length < (page + 1) * @perPage

      @setItemIds(itemIds, page)

      @items[offset] ?= null # make sure the array is big enough if we beat another request back
      @items.splice(offset, numToReplace, items...)
      @pages[page] = 'loaded'
      @list.replaceItems(offset, items, @itemIds.length)

    resetRequests: ->
      request?.abort() for request in @requests if @requests
      @requests = []

    setItemIds: (itemIds, requestingPage) ->
      initialFetch = not @itemIds?
      return if not initialFetch and @itemIds.toString() is itemIds.toString()
      @itemIds = itemIds
      @resetItemMap()

      # reload previously loaded pages, because they are stale now
      @refetchPages(requestingPage) unless initialFetch

    resetItemMap: ->
      @itemMap = {}
      for i in [0...@itemIds.length]
        @itemMap[@itemIds[i]] = i

    recompute: (refresh=false) ->
      if @deferredPositionChecks
        @fetchPage 0, =>
          # make sure we load any unloaded pages we need
          @fetchRange(@itemMap[id]) for id in @deferredPositionChecks
          delete @deferredPositionChecks
          @refreshList() if refresh
      else
        @checkPage(page) for page in [0...@pages.length] when @pages[page] is 'loaded'
        @refreshList() if refresh

    refetchPages: (except) ->
      for page in [0...@pages.length] when @pages[page] is 'loaded' and page isnt except
        if page * @perPage < @itemIds.length
          @fetchPage page
        else
          @requests[page]?.abort()
          delete @pages[page]

    checkPage: (page) ->
      offset = page * @perPage
      for i in [offset...Math.min(offset + @perPage, @itemIds.length)] when not @items[i]
        return @fetchPage(page)

    _addItem: (item, updateUi=true, overridePos=null) ->
      pos = overridePos ? @positionOrReload(item)
      return unless pos?
      @itemIds.splice(pos, 0, item.id)
      @items.splice(pos, 0, item)
      @list.addedItem(item, pos) if updateUi
      @resetItemMap()

    _updateItem: (item, updateUi=true, overridePos=null) ->
      currPos = @itemMap[item.id]
      newPos = overridePos ? @positionOrReload(item, currPos)
      item = @items[currPos].set(item.toJSON()) if @items[currPos]
      return unless newPos?
      @_moveItem(item, currPos, newPos) if newPos isnt currPos
      @list.updatedItem(item, currPos, newPos) if updateUi
      @resetItemMap()

    _moveItem: (item, currPos, newPos) ->
      newPos-- if newPos > currPos
      @_removeItem(item, false, currPos)
      @_addItem(item, false, newPos)

    _removeItem: (item, updateUi=true, pos=null) ->
      pos ?= @itemMap[item.id]
      return unless pos?

      @itemIds.splice(pos, 1)
      if @items.length >= pos
        @items.splice(pos, 1)
      @list.removedItem(item, pos) if updateUi
      @resetItemMap()
