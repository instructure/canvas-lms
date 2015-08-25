define [
  'react'
  'react-router'
  'i18n!react_files'
  'compiled/str/splitAssetString'
  './Toolbar'
  'jsx/files/Breadcrumbs'
  'jsx/files/FolderTree'
  'jsx/files/FilesUsage'
  '../mixins/MultiselectableMixin'
  '../mixins/dndMixin'
  '../modules/filesEnv'
], (React, ReactRouter, I18n, splitAssetString, ToolbarComponent, Breadcrumbs, FolderTree, FilesUsage, MultiselectableMixin, dndMixin, filesEnv) ->

  Toolbar = React.createFactory ToolbarComponent
  RouteHandler = React.createFactory ReactRouter.RouteHandler


  FilesApp =
    displayName: 'FilesApp'

    mixins: [ ReactRouter.State ]

    onResolvePath: ({currentFolder, rootTillCurrentFolder, showingSearchResults, searchResultCollection, pathname}) ->
      @setState
        currentFolder: currentFolder
        key: @getHandlerKey()
        pathname: pathname
        rootTillCurrentFolder: rootTillCurrentFolder
        showingSearchResults: showingSearchResults
        selectedItems: []
        searchResultCollection: searchResultCollection

    getInitialState: ->
      {
        currentFolder: null
        rootTillCurrentFolder: null
        showingSearchResults: false
        showingModal: false
        pathname: window.location.pathname
        key: @getHandlerKey()
        modalContents: null  # This should be a React Component to render in the modal container.
      }

    mixins: [MultiselectableMixin, dndMixin, ReactRouter.Navigation, ReactRouter.State]

    # For react-router handler keys
    getHandlerKey: ->
      childDepth = 1
      childName = @getRoutes()[childDepth].name
      id = @getParams().id
      key = childName + id
      key

    # for MultiselectableMixin
    selectables: ->
      if @state.showingSearchResults
        @state.searchResultCollection.models
      else
        @state.currentFolder.children(@getQuery())

    getPreviewQuery: ->
      retObj =
        preview: @state.selectedItems[0]?.id or true
      if @state.selectedItems.length > 1
        retObj.only_preview = @state.selectedItems.map((item) -> item.id).join(',')
      if @getQuery()?.search_term
        retObj.search_term = @getQuery().search_term
      retObj

    getPreviewRoute: ->
      if @getQuery()?.search_term
        'search'
      else if @state.currentFolder?.urlPath()
        'folder'
      else
        'rootFolder'

    openModal: (contents, afterClose) ->
      @setState
        modalContents: contents
        showingModal: true
        afterModalClose: afterClose

    closeModal: ->
      @setState(showingModal: false, -> @state.afterModalClose())

    previewItem: (item) ->
      @clearSelectedItems =>
        @toggleItemSelected item, null, =>
          params = {splat: @state.currentFolder?.urlPath()}
          @transitionTo(@getPreviewRoute(), params, @getPreviewQuery())
