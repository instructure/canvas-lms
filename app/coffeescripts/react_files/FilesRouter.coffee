define [
  'react'
  'underscore'
  'compiled/react_files/components/FilesApp'
  'compiled/str/splitAssetString'
  'compiled/models/Folder'
  'compiled/collections/FilesCollection'
  'Backbone'
], (React, _, FilesApp, splitAssetString, Folder, FilesCollection, Backbone) ->

  class FilesRouter extends Backbone.Router


    initialize: (@options) ->
      unless @options.contextType and @options.contextId
        throw new Error('contextType and contextId are required')

    routes:
      '': 'root'
      'folder': 'redirectToRoot'
      'folder*folderPath' : 'showFolder'
      'search': 'search'

    root: ->
      @showFolder('/')

    # if you come to courses/x/files/folder, it redirects you to courses/x/files
    redirectToRoot: ->
      @navigate('', {trigger: true, replace: true})

    showFolder: (folderPath) ->
      Folder.resolvePath(@options.contextType, @options.contextId, folderPath).then (folders) =>
        rootFolder = folders[0]
        window.currentFolder = currentFolder = folders[folders.length - 1]
        @_renderApp
          contextType: @options.contextType
          contextId: @options.contextId
          baseUrl: Backbone.history.root
          showBreadcrumb: true
          folderPath: folderPath
          rootFolder: rootFolder
          currentFolder: currentFolder

    _renderApp: (props) ->
      React.renderComponent(FilesApp(props), document.getElementById('content'))

    search: ->
      # see: https://canvas.instructure.com/doc/api/files.html#method.files.api_show
      # ALLOWED_QUERY_PARAMS = ['content_types', 'search_term', 'include', 'sort', 'order']
      # queryParams = _.pick(options, ALLOWED_QUERY_PARAMS)
      collection = new FilesCollection #({data: queryParams})
      collection.url = "/api/v1/#{@options.contextType}/#{@options.contextId}/files"

      @_renderApp
        showBreadcrumb: false
        searchResults: collection
        contextType: @options.contextType
        contextId: @options.contextId
        # baseUrl: Backbone.history.root

