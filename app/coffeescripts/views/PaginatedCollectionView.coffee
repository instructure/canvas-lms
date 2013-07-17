define [
  'jquery'
  'underscore'
  'compiled/views/CollectionView'
  'jst/paginatedCollection'
], ($, _, CollectionView, template) ->

  ##
  # General purpose lazy-load view. It must have a PaginatedCollection.
  #
  # TODO: We should replace all PaginatedView instances with this
  #
  # example:
  #
  #   new PaginatedCollectionView
  #     collection: somePaginatedCollection
  #     itemView: SomeItemView

  class PaginatedCollectionView extends CollectionView

    defaults:

      ##
      # Distance to begin fetching the next page

      buffer: 500

      ##
      # Container with observed scroll position, can be a jQuery element, raw
      # dom node, or selector

      scrollContainer: window

    ##
    # Adds a loading indicator element

    els: _.extend({}, CollectionView::els,
      '.paginatedLoadingIndicator': '$loadingIndicator'
    )

    @optionProperty 'scrollContainer'

    template: template

    ##
    # Initializes the view

    initialize: ->
      super
      @initScrollContainer()

    ##
    # Extends parent to detach scroll container event
    #
    # @api private

    attachCollection: ->
      super
      @collection.on 'reset', @attachScroll
      @collection.on 'fetched:last', @detachScroll
      @collection.on 'beforeFetch', @showLoadingIndicator
      @collection.on 'fetch', @hideLoadingIndicator

    ##
    # Sets instance properties regarding the scrollContainer
    #
    # @api private

    initScrollContainer: ->
      @scrollContainer = $ @scrollContainer
      @heightContainer = if @scrollContainer[0] is window
        # window has no scrollHeight
        document.body
      else
        @scrollContainer[0]

    ##
    # Attaches scroll event to scrollContainer
    #
    # @api private

    attachScroll: =>
      scroll = "scroll.pagination:#{@cid}"
      resize = "resize.pagination:#{@cid}"
      @scrollContainer.on scroll, @checkScroll
      @scrollContainer.on resize, @checkScroll

    ##
    # Removes the scoll event from scrollContainer
    #
    # @api private

    detachScroll: =>
      @scrollContainer.off ".pagination:#{@cid}"

    ##
    # Determines if we need to fetch the collection's next page
    #
    # @api public

    checkScroll: =>
      return if @fetchingPage
      distanceToBottom = @heightContainer.scrollHeight -
        @scrollContainer.scrollTop() -
        @scrollContainer.height()
      if distanceToBottom < @options.buffer
        @collection.fetch page: 'next'

    ##
    # Remove scroll event if view is removed
    #
    # @api public

    remove: ->
      @detachScroll()
      super

    ##
    # Hides the loading indicator after render
    #
    # @api private

    afterRender: ->
      super
      @hideLoadingIndicator()

    ##
    # Hides the loading indicator
    #
    # @api private

    hideLoadingIndicator: =>
      @$loadingIndicator?.hide()

    ##
    # Shows the loading indicator
    #
    # @api private

    showLoadingIndicator: =>
      @$loadingIndicator?.show()

