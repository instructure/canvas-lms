define [
  'react'
  'i18n!react_files'
  'compiled/react/shared/utils/withReactDOM'
  './ColumnHeaders'
  './LoadingIndicator'
  './FolderChild'
  '../utils/getAllPages'
  '../utils/updateAPIQuerySortParams'
  'compiled/models/Folder'
], (React, I18n, withReactDOM, ColumnHeaders, LoadingIndicator, FolderChild, getAllPages, updateAPIQuerySortParams, Folder) ->

  ShowFolder = React.createClass

    getCurrentFolder: ->
      path = '/' + (@props.params.splat || '')
      Folder.resolvePath(@props.params.contextType, @props.params.contextId, path).then (rootTillCurrentFolder) =>
        currentFolder = rootTillCurrentFolder[rootTillCurrentFolder.length - 1]
        @props.onResolvePath({currentFolder, rootTillCurrentFolder})

        [currentFolder.folders, currentFolder.files].forEach (collection) =>
          updateAPIQuerySortParams(collection, @props.query)
          # TODO: use scroll position to only fetch the pages we need
          getAllPages collection, => @forceUpdate() if @isMounted()

    componentWillMount: ->
      @getCurrentFolder()

    componentWillUnmount: ->
      setTimeout =>
        @props.onResolvePath({currentFolder:undefined, rootTillCurrentFolder:undefined})


    componentWillReceiveProps: (newProps) ->
      return unless newProps.currentFolder
      [newProps.currentFolder.folders, newProps.currentFolder.files].forEach (collection) ->
        updateAPIQuerySortParams(collection, newProps.query)

    render: withReactDOM ->
      return div({}) unless @props.currentFolder
      div className:'ef-directory',
        ColumnHeaders(to: (if @props.params.splat then 'folder' else 'rootFolder'), subject: @props.currentFolder, params: @props.params, query: @props.query),
        if @props.currentFolder.isEmpty()
          div className: 'muted', I18n.t('this_folder_is_empty', 'This folder is empty')
        else
          @props.currentFolder.children(@props.query).map (child) =>
            FolderChild key:child.cid, model: child, params: @props.params
        LoadingIndicator isLoading: @props.currentFolder.folders.fetchingNextPage || @props.currentFolder.files.fetchingNextPage




