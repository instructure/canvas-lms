define [
  'react'
  'react-router'
  'compiled/react_files/components/SearchResults'
  'compiled/collections/FilesCollection'
], (React, Router, SearchResults, FilesCollection) ->
  module 'SearchResults#render',
    setup: ->
      sinon.stub(Router, 'Link').returns('link')
      sinon.stub($, 'ajax').returns($.Deferred().resolve())

    teardown: ->
      Router.Link.restore()
      $.ajax.restore()

  test 'when collection is loaded and empty display no matches found', ->

    props =
      params: {}
      query: {}
      onResolvePath: ->
      selectedItems: []
      onResolvePath: ->
      toggleItemSelected: ->
      toggleAllSelected: ->
      areAllItemsSelected: -> false
      dndOptions:
        onItemDragStart: ->
        onItemDragEnterOrOver: ->
        onItemDragLeaveOrEnd: ->
        onItemDrop: ->

    @searchResults = React.renderComponent(SearchResults(props), $('#fixtures')[0])

    ok @searchResults.refs.noResultsFound, 'Displays the no results text'

    React.unmountComponentAtNode($('#fixtures')[0])

