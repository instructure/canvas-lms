define [
  'react'
  'react-router'
  'compiled/react_files/components/SearchResults'
  'compiled/collections/FilesCollection'
], (React, Router, SearchResults, FilesCollection) ->
  module 'SearchResults#render',
  test 'when collection is loaded and empty display no matches found', ->
    sinon.stub(Router, 'Link').returns('link')
    sinon.stub($, 'ajax').returns($.Deferred().resolve())
    props =
      params: {}
      query: {}
      onResolvePath: ->
    @searchResults = React.renderComponent(SearchResults(props), $('#fixtures')[0])

    ok @searchResults.refs.noResultsFound, 'Displays the no results text'

    React.unmountComponentAtNode($('#fixtures')[0])
    Router.Link.restore()
    $.ajax.restore()
