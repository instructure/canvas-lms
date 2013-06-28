define [
  'jquery'
  'underscore'
  'compiled/views/PaginatedCollectionView'
], ($, _, PaginatedCollectionView) ->

  ##
  # Use this instead of PaginatedCollectionView when you have
  # multiple views sharing the same scrollContainer

  class SharedPaginatedCollectionView extends PaginatedCollectionView
    checkScroll: =>
      return if @fetchingPage
      distanceToBottom = (@$el.offset().top + @$el.height()) - (@scrollContainer.offset().top + @scrollContainer.height())
      if distanceToBottom < @options.buffer
        @collection.fetch page: 'next'