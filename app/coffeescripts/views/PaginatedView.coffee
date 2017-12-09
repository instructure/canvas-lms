#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'underscore'
  'jquery'
  'Backbone'
  'jst/PaginatedView'
], (_, $, Backbone, template) ->

  class PaginatedView extends Backbone.View

    paginationLoaderTemplate: template

    paginationScrollContainer: window

    distanceTillFetchNextPage: 100

    # options
    #   fetchOptions: options passed to the collection's fetch function
    initialize: (options) ->
      ret = super options
      @fetchOptions = options.fetchOptions
      @bindPaginationEvents()
      @paginationStopped = false
      ret

    render: ->
      ret = super
      @showPaginationLoader() if @collection.fetchingNextPage
      @startPaginationListener()
      ret

    showPaginationLoader: ->
      @$paginationLoader ?= $(@paginationLoaderTemplate())
      @placePaginationLoader()

    placePaginationLoader: ->
      @$paginationLoader?.insertAfter @el

    hidePaginationLoader: ->
      @$paginationLoader?.remove()

    distanceToBottom: ->
      $container = $(@paginationScrollContainer)
      containerScrollHeight = if $container[0] is window
        $(document).height()
      else
        $container[0].scrollHeight
      containerScrollHeight - $container.scrollTop() - $container.height()

    startPaginationListener: ->
      return if @paginationStopped
      fn = $.proxy @fetchNextPageIfNeeded, this
      $(@paginationScrollContainer).on "scroll.pagination:#{@cid}", fn
      $(@paginationScrollContainer).on "resize.pagination:#{@cid}", fn
      @fetchNextPageIfNeeded()

    stopPaginationListener: ->
      @paginationStopped = true
      $(@paginationScrollContainer).off ".pagination:#{@cid}"

    fetchNextPageIfNeeded: ->
      # let the call stack play out before checking the scroll position.
      setTimeout =>
        return if @collection.fetchingNextPage
        if !@collection.urls or !@collection.urls.next
          @stopPaginationListener() if @collection.length
          return
        shouldFetchNextPage = @distanceToBottom() < @distanceTillFetchNextPage or !@collection.length
        if $(@paginationScrollContainer).is(':visible') and shouldFetchNextPage
          @collection.fetch _.extend({page: 'next'}, @fetchOptions)
      , 0

    bindPaginationEvents: ->
      @collection.on 'beforeFetch:next', @showPaginationLoader, this
      @collection.on 'fetch:next', @hidePaginationLoader, this
      @collection.on 'all', @fetchNextPageIfNeeded, this
