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
  '../modules/customPropTypes'
  '../utils/updateAPIQuerySortParams'
  '../utils/getAllPages'
  './FilePreview'
  './NoResults'
], (_, I18n, React, Folder, FilesCollection, withReactDOM, ColumnHeaders, LoadingIndicator, FolderChild, customPropTypes, updateAPIQuerySortParams, getAllPages, FilePreview, NoResults) ->


  SearchResults = React.createClass
    displayName: 'SearchResults'

    propTypes:
      contextType: customPropTypes.contextType
      contextId: customPropTypes.contextId

    getInitialState: ->
      return {
        collection: new FilesCollection
      }

    updateResults: (props) ->
      oldUrl = @state.collection.url
      @state.collection.url = "#{window.location.origin}/api/v1/#{@props.contextType}/#{@props.contextId}/files"
      updateAPIQuerySortParams(@state.collection, @props.query)

      return if @state.collection.url is oldUrl # if you doesn't search for the same thing twice
      @setState({collection: @state.collection})

      # Refactor this when given time. Maybe even use setState instead of forceUpdate
      unless @state.collection.loadedAll and _.isEqual(@props.query.search_term, props.query.search_term)
        forceUpdate = =>
          @forceUpdate() if @isMounted()
          $.screenReaderFlashMessage I18n.t('results_count', "Showing %{num_results} search results", {num_results: @state.collection.length})
        @state.collection.fetch({data: props.query}).then(forceUpdate)
        # TODO: use scroll position to only fetch the pages we need
          .then getAllPages.bind(null, @state.collection, forceUpdate)

    componentWillReceiveProps: (newProps) ->
      @updateResults(newProps)

    componentWillMount: ->
      @updateResults(@props)

    componentDidMount: ->
      # this setTimeout is to handle a race condition with the setTimeout in the componentWillUnmount method of ShowFolder
      setTimeout =>
        @props.onResolvePath({currentFolder: null, rootTillCurrentFolder: null, showingSearchResults: true, searchResultCollection: @state.collection})

    render: withReactDOM ->
      if @state.collection.loadedAll and (@state.collection.length is 0)
        NoResults {search_term: @props.query.search_term}
      else
        div role: 'grid',
          ColumnHeaders {
            to: 'search'
            query: @props.query
            params: @props.params
            toggleAllSelected: @props.toggleAllSelected
            areAllItemsSelected: @props.areAllItemsSelected
          }
          @state.collection.models.sort(Folder::childrenSorter.bind(@state.collection, @props.query.sort, @props.query.order)).map (child) =>
            FolderChild
              key: child.cid
              model: child
              isSelected: child in @props.selectedItems
              toggleSelected: @props.toggleItemSelected.bind(null, child)
              userCanManageFilesForContext: @props.userCanManageFilesForContext
              dndOptions: @props.dndOptions
          LoadingIndicator isLoading: !@state.collection.loadedAll

          # Prepare and render the FilePreview if needed.
          # As long as ?preview is present in the url.
          if @props.query.preview? and @state.collection.length
            FilePreview
              params: @props.params
              query: @props.query
              collection: @state.collection