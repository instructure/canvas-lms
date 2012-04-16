define [
  'jquery'
  'Backbone'
  'jst/PaginatedView'
], ($, Backbone, template) ->

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
      @collection.on 'beforeFetchNextPage', @showPaginationLoader, this
      @collection.on 'didFetchNextPage', @hidePaginationLoader, this
      @collection.on 'all', @fetchNextPageIfNeeded, this
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
      $(@paginationScrollContainer).on "scroll.pagination#{@cid} resize.pagination#{@cid}", $.proxy @fetchNextPageIfNeeded, this
      @fetchNextPageIfNeeded()

    stopPaginationListener: ->
      $(@paginationScrollContainer).off ".pagination#{@cid}"

    fetchNextPageIfNeeded: ->
      return if @collection.fetchingNextPage
      unless @collection.nextPageUrl
        @stopPaginationListener() if @collection.length
        return
      if @distanceToBottom() < @distanceTillFetchNextPage
        @collection.fetchNextPage @fetchOptions
