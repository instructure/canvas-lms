define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/str/splitAssetString'
  './Toolbar'
  './Breadcrumbs'
  './FolderTree'
  './FilesUsage'
], (React, withReactDOM, splitAssetString, Toolbar, Breadcrumbs, FolderTree, FilesUsage) ->

  FilesApp = React.createClass

    onResolvePath: ({currentFolder, rootTillCurrentFolder}) ->
      @setState({currentFolder, rootTillCurrentFolder})

    getInitialState: ->
      {
        currentFolder: undefined
        rootTillCurrentFolder: undefined
      }

    render: withReactDOM ->
      div null,
        Toolbar(currentFolder: @state.currentFolder, query: @props.query, params: @props.params)
        Breadcrumbs(rootTillCurrentFolder: @state.rootTillCurrentFolder, contextType:@props.params.contextType, contextId:@props.params.contextId) if @state.rootTillCurrentFolder
        div className: 'ef-main',
          aside className: 'visible-desktop ef-folder-content',
            FolderTree(rootTillCurrentFolder: @state.rootTillCurrentFolder, contextType:@props.params.contextType, contextId:@props.params.contextId) if @state.rootTillCurrentFolder
            FilesUsage(contextType:@props.params.contextType, contextId:@props.params.contextId)
          @props.activeRouteHandler
            onResolvePath: @onResolvePath
            currentFolder: @state.currentFolder
