define [
  'jquery'
  'react'
  'page'
  'underscore'
  'i18n!react_files'
  '../modules/filesEnv'
  '../utils/getAllPages'
  '../utils/updateAPIQuerySortParams'
  'compiled/models/Folder'
], ($, React, page, _, I18n, filesEnv, getAllPages, updateAPIQuerySortParams, Folder) ->

  LEADING_SLASH_TILL_BUT_NOT_INCLUDING_NEXT_SLASH = /^\/[^\/]*/

  ShowFolder =
    displayName: 'ShowFolder'

    debouncedForceUpdate: _.debounce ->
      @forceUpdate() if @isMounted()
    , 0

    previousIdentifier: ""

    registerListeners: (props) ->
      return unless props.currentFolder
      props.currentFolder.folders.on('all', @debouncedForceUpdate, this)
      props.currentFolder.files.on('all', @debouncedForceUpdate, this)

    unregisterListeners: ->
      # Ensure that we clean up any dangling references when the component is destroyed.
      @props.currentFolder?.off(null, null, this)

    getCurrentFolder: (options = {}) ->
      path = '/' + (options.splat || '')

      if filesEnv.showingAllContexts
        pluralAssetString = path.split('/')[1]
        context = filesEnv.contextsDictionary[pluralAssetString] or filesEnv.contexts[0]
        {contextType, contextId} = context
        path = path.replace(LEADING_SLASH_TILL_BUT_NOT_INCLUDING_NEXT_SLASH, '')
      else
        {contextType, contextId} = filesEnv

      Folder.resolvePath(contextType, contextId, path).then (rootTillCurrentFolder) =>
        currentFolder = rootTillCurrentFolder[rootTillCurrentFolder.length - 1]
        @props.onResolvePath {currentFolder, rootTillCurrentFolder, showingSearchResults: false}

        [currentFolder.folders, currentFolder.files].forEach (collection) =>
          updateAPIQuerySortParams(collection, @props.query)
          # TODO: use scroll position to only fetch the pages we need
          getAllPages(collection, @debouncedForceUpdate)
      , (jqXHR) =>
        try
          parsedResponse = $.parseJSON(jqXHR.responseText)
        if parsedResponse
          @setState errorMessages: parsedResponse.errors
          @redirectToCourseFiles() if @props.query.preview?

    componentWillMount: ->
      @registerListeners(@props)
      @getCurrentFolder(@props)

    componentWillUnmount: ->
      @unregisterListeners()

    componentDidUpdate: ->
      @redirectToCourseFiles() if not @props.currentFolder? or @props.currentFolder?.get('locked_for_user')

    componentWillReceiveProps: (newProps) ->
      @unregisterListeners()
      return unless newProps.currentFolder
      @getCurrentFolder(newProps) if @props.pathname isnt newProps.pathname
      @registerListeners(newProps)
      [newProps.currentFolder.folders, newProps.currentFolder.files].forEach (collection) =>
        updateAPIQuerySortParams(collection, @props.query)

    redirectToCourseFiles: ->
      isntPreviousFolder = @props.currentFolder? and (@previousIdentifier? isnt @props.currentFolder.get('id').toString())
      isPreviewForFile = window.location.pathname isnt filesEnv.baseUrl and @props.query.preview? and @previousIdentifier isnt @props.query.preview

      if isntPreviousFolder or isPreviewForFile
        @previousIdentifier = @props.currentFolder?.get('id').toString() or @props.query.preview.toString()

        unless isPreviewForFile
          message = I18n.t('This folder is currently locked and unavailable to view.')
          $.flashError message
          $.screenReaderFlashMessage message

        setTimeout(=>
          page("#{filesEnv.baseUrl}?#{$.param(@props.query)}")
        , 0)
