define [
  'underscore'
  'react'
  'compiled/models/Folder'
  'compiled/collections/FilesCollection'
  'compiled/react/shared/utils/withReactDOM'
  './ColumnHeaders'
  './LoadingIndicator'
  './FolderChild'
  '../utils/updateAPIQuerySortParams'
  '../utils/getAllPages'
], (_, React, Folder, FilesCollection, withReactDOM, ColumnHeaders, LoadingIndicator, FolderChild, updateAPIQuerySortParams, getAllPages) ->


  SearchResults = React.createClass

    getInitialState: ->
      return {
        collection: new FilesCollection
      }

    updateResults: (props) ->
      oldUrl = @state.collection.url
      @state.collection.url = "#{location.origin}/api/v1/#{@props.params.contextType}/#{@props.params.contextId}/files"
      updateAPIQuerySortParams(@state.collection, @props.query)

      return if @state.collection.url is oldUrl
      @setState({collection: @state.collection})

      unless @state.collection.loadedAll and _.isEqual(@props.query.search_term, props.query.search_term)
        forceUpdate = => @forceUpdate() if @isMounted()
        @state.collection.fetch({data: props.query}).then(forceUpdate)
        # TODO: use scroll position to only fetch the pages we need
          .then getAllPages.bind(null, @state.collection, forceUpdate)

    componentWillReceiveProps: (newProps) ->
      @updateResults(newProps)

    componentWillMount: ->
      @updateResults(@props)

    render: withReactDOM ->
      div className:'ef-directory',
        ColumnHeaders to: 'search', subject: @state.collection, params: @props.params, query: @props.query
        @state.collection.models.sort(Folder::childrenSorter.bind(@state.collection, @props.query.sort, @props.query.order)).map (child) =>
          FolderChild key:child.cid, model: child, params: @props.params
        LoadingIndicator isLoading: !@state.collection.loadedAll
