define [
  'underscore'
  'react'
  'i18n!react_files'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/filesEnv'
  './ColumnHeaders'
  './LoadingIndicator'
  './FolderChild'
  '../utils/getAllPages'
  '../utils/updateAPIQuerySortParams'
  'compiled/models/Folder'
  './CurrentUploads'
  './FilePreview'
  './UploadDropZone'
  '../utils/forceScreenreaderToReparse'
], (_, React, I18n, withReactDOM, filesEnv, ColumnHeaders, LoadingIndicator, FolderChild, getAllPages, updateAPIQuerySortParams, Folder, CurrentUploads, FilePreview, UploadDropZone, forceScreenreaderToReparse) ->


  LEADING_SLASH_TILL_BUT_NOT_INCLUDING_NEXT_SLASH = /^\/[^\/]*/

  ShowFolder = React.createClass
    displayName: 'ShowFolder'

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

    buildFolderPath: (splat) ->
      encodeURI('/' + (splat || ''))

    getCurrentFolder: ->
      path = @buildFolderPath(@props.params.splat)

      if filesEnv.showingAllContexts
        pluralAssetString = path.split('/')[1]
        context = filesEnv.contextsDictionary[pluralAssetString] or filesEnv.contexts[0]
        {contextType, contextId} = context
        path = path.replace(LEADING_SLASH_TILL_BUT_NOT_INCLUDING_NEXT_SLASH, '')
      else
        {contextType, contextId} = filesEnv

      Folder.resolvePath(contextType, contextId, path).then (rootTillCurrentFolder) =>
        currentFolder = rootTillCurrentFolder[rootTillCurrentFolder.length - 1]
        @props.onResolvePath({currentFolder, rootTillCurrentFolder, showingSearchResults:false})

        [currentFolder.folders, currentFolder.files].forEach (collection) =>
          updateAPIQuerySortParams(collection, @props.query)
          # TODO: use scroll position to only fetch the pages we need
          getAllPages(collection, @debouncedForceUpdate)
      , (jqXHR) =>
        try
          parsedResponse = $.parseJSON(jqXHR.responseText)
        if parsedResponse
          @setState errorMessages: parsedResponse.errors

    componentWillMount: ->
      @registerListeners(@props)
      @getCurrentFolder()

    componentWillUnmount: ->
      @unregisterListeners()

      setTimeout =>
        @props.onResolvePath({currentFolder:undefined, rootTillCurrentFolder:undefined})

    componentDidUpdate: ->
      # hooray for a11y
      forceScreenreaderToReparse(@getDOMNode())

    componentWillReceiveProps: (newProps) ->
      @unregisterListeners()
      return unless newProps.currentFolder
      @registerListeners(newProps)
      [newProps.currentFolder.folders, newProps.currentFolder.files].forEach (collection) ->
        updateAPIQuerySortParams(collection, newProps.query)

    render: withReactDOM ->
      if @state?.errorMessages
        return div {},
          @state.errorMessages.map (error) ->
            div className: 'muted', error.message
      return div({ref: 'emptyDiv'}) unless @props.currentFolder
      div role: 'grid',
        UploadDropZone(currentFolder: @props.currentFolder)
        CurrentUploads({})
        ColumnHeaders {
          to: (if @props.params.splat then 'folder' else 'rootFolder')
          query: @props.query
          params: @props.params
          toggleAllSelected: @props.toggleAllSelected
          areAllItemsSelected: @props.areAllItemsSelected
          splat: @props.params.splat
        }
        if @props.currentFolder.isEmpty()
          div ref: 'folderEmpty', className: 'muted', I18n.t('this_folder_is_empty', 'This folder is empty')
        else
          @props.currentFolder.children(@props.query).map (child) =>
            FolderChild
              key:child.cid
              model: child
              isSelected: child in @props.selectedItems
              toggleSelected: @props.toggleItemSelected.bind(null, child)
              userCanManageFilesForContext: @props.userCanManageFilesForContext
              dndOptions: @props.dndOptions

        LoadingIndicator isLoading: @props.currentFolder.folders.fetchingNextPage || @props.currentFolder.files.fetchingNextPage

        # Prepare and render the FilePreview if needed.
        # As long as ?preview is present in the url.
        if @props.query.preview?
          FilePreview
            currentFolder: @props.currentFolder
            params: @props.params
            query: @props.query
