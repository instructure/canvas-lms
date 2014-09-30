define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/str/splitAssetString'
  './Toolbar'
  './Breadcrumbs'
  './FolderTree'
  './FilesUsage'
  '../mixins/MultiselectableMixin'
], (React, withReactDOM, splitAssetString, Toolbar, Breadcrumbs, FolderTree, FilesUsage, MultiselectableMixin) ->

  FilesApp = React.createClass

    onResolvePath: ({currentFolder, rootTillCurrentFolder}) ->
      @setState({currentFolder, rootTillCurrentFolder})

    getInitialState: ->
      {
        currentFolder: undefined
        rootTillCurrentFolder: undefined
      }

    mixins: [MultiselectableMixin]

    # for MultiselectableMixin
    selectables: -> @state.currentFolder.children(@props.query)

    render: withReactDOM ->
      div null,
        Toolbar({
          currentFolder: @state.currentFolder,
          query: @props.query,
          params: @props.params
          selectedItems: @state.selectedItems
        })
        if @state.rootTillCurrentFolder
          Breadcrumbs({
            rootTillCurrentFolder: @state.rootTillCurrentFolder,
            contextType: @props.params.contextType,
            contextId: @props.params.contextId
          })
        div className: 'ef-main',
          aside className: 'visible-desktop ef-folder-content',
            if @state.rootTillCurrentFolder
              FolderTree({
                rootTillCurrentFolder: @state.rootTillCurrentFolder,
                contextType: @props.params.contextType,
                contextId: @props.params.contextId
              })
            FilesUsage({
              contextType: @props.params.contextType
              contextId: @props.params.contextId
            })
          @props.activeRouteHandler
            onResolvePath: @onResolvePath
            currentFolder: @state.currentFolder
            selectedItems: @state.selectedItems
            toggleItemSelected: @toggleItemSelected
