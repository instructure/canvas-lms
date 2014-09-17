define [
  'react'
  'i18n!react_files'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/str/splitAssetString'
  './Toolbar'
  './Breadcrumbs'
  './FolderTree'
  './FilesUsage'
  '../mixins/MultiselectableMixin'
], (React, I18n, withReactDOM, splitAssetString, Toolbar, Breadcrumbs, FolderTree, FilesUsage, MultiselectableMixin) ->

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
        Breadcrumbs({
          rootTillCurrentFolder: @state.rootTillCurrentFolder,
          contextType: @props.params.contextType,
          contextId: @props.params.contextId
        })
        Toolbar({
          currentFolder: @state.currentFolder,
          query: @props.query,
          params: @props.params
          selectedItems: @state.selectedItems
        })

        div className: 'ef-main',
          aside className: 'visible-desktop ef-folder-content',
            if @state.rootTillCurrentFolder
              FolderTree({
                rootTillCurrentFolder: @state.rootTillCurrentFolder,
                contextType: @props.params.contextType,
                contextId: @props.params.contextId
              })
          @props.activeRouteHandler
            onResolvePath: @onResolvePath
            currentFolder: @state.currentFolder
            selectedItems: @state.selectedItems
            toggleItemSelected: @toggleItemSelected
        div className: 'ef-footer grid-row',
          FilesUsage({
            className: 'col-xs-3'
            contextType: @props.params.contextType
            contextId: @props.params.contextId
          }),
          div className: 'col-xs',
            div {},
              a className: 'pull-right', href: '/files?show_all_contexts=1',
                I18n.t('all_my_files', 'All My Files')
