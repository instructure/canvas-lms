define [
  'underscore'
  'i18n!react_files'
  'react'
  'react-router'
  'compiled/models/Folder'
  'compiled/collections/FilesCollection'
  'compiled/react/shared/utils/withReactElement'
  'jsx/files/ColumnHeaders'
  'jsx/files/LoadingIndicator'
  './FolderChild'
  '../modules/customPropTypes'
  '../utils/updateAPIQuerySortParams'
  '../utils/getAllPages'
  'jsx/files/FilePreview'
  'jsx/files/NoResults'
  '../utils/locationOrigin'
], (_, I18n, React, ReactRouter, Folder, FilesCollection, withReactElement, ColumnHeadersComponent, LoadingIndicator, FolderChildComponent, customPropTypes, updateAPIQuerySortParams, getAllPages, FilePreviewComponent, NoResults) ->

  ColumnHeaders = ColumnHeadersComponent
  FolderChild = React.createFactory FolderChildComponent
  FilePreview = React.createFactory FilePreviewComponent

  SearchResults = React.createClass
    displayName: 'SearchResults'

    propTypes:
      contextType: customPropTypes.contextType
      contextId: customPropTypes.contextId

    mixins: [ReactRouter.State]

    name: 'search'

    getInitialState: ->
      return {
        collection: new FilesCollection
        errors: null
      }

    onFetchError: (jqXHR, textStatus, errorThrown) ->
      message = I18n.t('An unknown server error occurred.  Please try again.')

      try
        responseText = JSON.parse(textStatus.responseText)
      catch e
        responseText =
          errors: [{message}]

      @setState errors: if _.isArray(responseText.errors)
                          responseText.errors
                        else if responseText.errors?.base?
                          [{message: "#{responseText.errors.base}, #{responseText.status}"}]
                        else
                          [{message}]

    displayErrors: (errors) ->
      div {},
        p {},
          I18n.t({one: 'Your search encountered the following error:', other: 'Your search encountered the following errors:'}, {count: errors.length})
        ul {},
          errors.map (error) ->
            li {}, error.message if error?.message?

    updateResults: (props) ->
      oldUrl = @state.collection.url
      @state.collection.url = "#{window.location.origin}/api/v1/#{@props.contextType}/#{@props.contextId}/files"
      updateAPIQuerySortParams(@state.collection, @getQuery())

      return if @state.collection.url is oldUrl # if you doesn't search for the same thing twice
      @setState({collection: @state.collection})

      # Refactor this when given time. Maybe even use setState instead of forceUpdate
      unless @state.collection.loadedAll and _.isEqual(@getQuery().search_term, props.query?.search_term?)
        forceUpdate = =>
          @setState({errors: null})
          @forceUpdate() if @isMounted()
          $.screenReaderFlashMessageExclusive I18n.t('results_count', "Showing %{num_results} search results", {num_results: @state.collection.length})
        @state.collection.fetch({data: props.query, error: @onFetchError}).then(forceUpdate)
          # TODO: use scroll position to only fetch the pages we need
          .then getAllPages.bind(null, @state.collection, forceUpdate)

    componentWillReceiveProps: (newProps) ->
      @updateResults(newProps)

    componentDidMount: ->
      @updateResults(@props)

      # this setTimeout is to handle a race condition with the setTimeout in the componentWillUnmount method of ShowFolder
      setTimeout =>
        @props.onResolvePath({currentFolder: null, rootTillCurrentFolder: null, showingSearchResults: true, searchResultCollection: @state.collection})

    render: withReactElement ->
      if @state.errors
        @displayErrors(@state.errors)
      else if @state.collection.loadedAll and (@state.collection.length is 0)
        NoResults {search_term: @getQuery().search_term}
      else
        div role: 'grid',
          div {
            ref: 'accessibilityMessage'
            className: 'SearchResults__accessbilityMessage col-xs'
            tabIndex: 0
          },
            I18n.t("Warning: For improved accessibility in moving files, please use the Move To Dialog option found in the menu.")
          ColumnHeaders {
            to: 'search'
            query: @getQuery()
            params: @getParams()
            toggleAllSelected: @props.toggleAllSelected
            areAllItemsSelected: @props.areAllItemsSelected
            usageRightsRequiredForContext: @props.usageRightsRequiredForContext
          }
          @state.collection.models.sort(Folder::childrenSorter.bind(@state.collection, @getQuery().sort, @getQuery().order)).map (child) =>
            FolderChild
              key: child.cid
              model: child
              isSelected: child in @props.selectedItems
              toggleSelected: @props.toggleItemSelected.bind(null, child)
              userCanManageFilesForContext: @props.userCanManageFilesForContext
              usageRightsRequiredForContext: @props.usageRightsRequiredForContext
              externalToolsForContext: @props.externalToolsForContext
              previewItem: @props.previewItem.bind(null, child)
              dndOptions: @props.dndOptions
              modalOptions: @props.modalOptions
              clearSelectedItems: @props.clearSelectedItems
          LoadingIndicator isLoading: !@state.collection.loadedAll

          # Prepare and render the FilePreview if needed.
          # As long as ?preview is present in the url.
          if @getQuery().preview? and @state.collection.length
            FilePreview
              params: @getParams()
              query: @getQuery()
              collection: @state.collection
              usageRightsRequiredForContext: @props.usageRightsRequiredForContext
