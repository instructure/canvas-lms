define [
  'underscore'
  'react'
  'i18n!react_files'
  'compiled/react/shared/utils/withReactDOM'
  './ColumnHeaders'
  './LoadingIndicator'
  './FolderChild'
  '../utils/getAllPages'
  '../utils/updateAPIQuerySortParams'
  'compiled/models/Folder'
], (_, React, I18n, withReactDOM, ColumnHeaders, LoadingIndicator, FolderChild, getAllPages, updateAPIQuerySortParams, Folder) ->

  ShowFolder = React.createClass

    debouncedForceUpdate: _.debounce ->
      @forceUpdate() if @isMounted()
    , 0


    registerListeners: (props) ->
      return unless props.currentFolder
      props.currentFolder.folders.on('all', @debouncedForceUpdate, this)
      props.currentFolder.files.on('all', @debouncedForceUpdate, this)

    unregisterListeners: ->
      # Ensure that we clean up any dangling references when the component is destroyed.
      @props.currentFolder?.off(null, null, this)

    componentWillUnmount: ->
      @unregisterListeners()


    getCurrentFolder: ->
      path = '/' + (@props.params.splat || '')
      Folder.resolvePath(@props.params.contextType, @props.params.contextId, path).then (rootTillCurrentFolder) =>
        currentFolder = rootTillCurrentFolder[rootTillCurrentFolder.length - 1]
        @props.onResolvePath({currentFolder, rootTillCurrentFolder})

        [currentFolder.folders, currentFolder.files].forEach (collection) =>
          updateAPIQuerySortParams(collection, @props.query)
          # TODO: use scroll position to only fetch the pages we need
          getAllPages(collection, @debouncedForceUpdate)

    componentWillMount: ->
      @registerListeners(@props)
      @getCurrentFolder()

    componentWillUnmount: ->
      setTimeout =>
        @props.onResolvePath({currentFolder:undefined, rootTillCurrentFolder:undefined})


    componentWillReceiveProps: (newProps) ->
      @unregisterListeners()
      return unless newProps.currentFolder
      @registerListeners(newProps)
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




