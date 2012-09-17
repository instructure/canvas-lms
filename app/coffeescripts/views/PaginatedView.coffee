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
      @startPaginationListener()
      @bindPaginationEvents()
      ret

    render: ->
      ret = super
      @showPaginationLoader() if @collection.fetchingNextPage
      ret

    showPaginationLoader: ->
      (@$paginationLoader ?= $(@paginationLoaderTemplate())).insertAfter @el

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
      $(@paginationScrollContainer).on "scroll.pagination#{@cid}, resize.pagination#{@cid}", $.proxy @fetchNextPageIfNeeded, this
      @fetchNextPageIfNeeded()

    stopPaginationListener: ->
      $(@paginationScrollContainer).off ".pagination#{@cid}"

    fetchNextPageIfNeeded: ->
      return if @collection.fetchingNextPage
      if !@collection.urls or !@collection.urls.next
        @stopPaginationListener() if @collection.length
        return
      if $(@paginationScrollContainer).is(':visible') and @distanceToBottom() < @distanceTillFetchNextPage
        @collection.fetch _.extend({page: 'next'}, @fetchOptions)

    bindPaginationEvents: ->
      @collection.on 'beforeFetch:next', @showPaginationLoader, this
      @collection.on 'fetch:next', @hidePaginationLoader, this
      @collection.on 'all', @fetchNextPageIfNeeded, this