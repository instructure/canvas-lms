define [
  'underscore'
  'i18n!react_files'
  'react'
  'compiled/models/Folder'
  'compiled/collections/FilesCollection'
  'compiled/react/shared/utils/withReactDOM'
  './ColumnHeaders'
  './LoadingIndicator'
  './FolderChild'
  '../utils/updateAPIQuerySortParams'
  '../utils/getAllPages'
], (_, I18n, React, Folder, FilesCollection, withReactDOM, ColumnHeaders, LoadingIndicator, FolderChild, updateAPIQuerySortParams, getAllPages) ->


  SearchResults = React.createClass

    getInitialState: ->
      return {
        collection: new FilesCollection
      }

    updateResults: (props) ->
      oldUrl = @state.collection.url
      @state.collection.url = "#{location.origin}/api/v1/#{@props.params.contextType}/#{@props.params.contextId}/files"
      updateAPIQuerySortParams(@state.collection, @props.query)

      return if @state.collection.url is oldUrl # if you doesn't search for the same thing twice
      @setState({collection: @state.collection})

      # Refactor this when given time. Maybe even use setState instead of forceUpdate
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
        if @state.collection.loadedAll and (@state.collection.length is 0)
          div ref: 'noResultsFound',
            p {}, I18n.t('errors.no_match.your_search', 'Your search - "%{search_term}" - did not match any files.', {search_term: @props.query.search_term})
            p {}, I18n.t('errors.no_match.suggestions', 'Suggestions:')
            ul {},
              li {}, I18n.t('errors.no_match.spelled', 'Make sure all words are spelled correctly.')
              li {}, I18n.t('errors.no_match.keywords', 'Try different keywords.')
              li {}, I18n.t('errors.no_match.three_chars', 'Enter at least 3 letters in the search box.')
