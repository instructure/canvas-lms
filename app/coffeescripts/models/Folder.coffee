define [
  'Backbone'
  'underscore'
], (Backbone, _) ->

  class Folder extends Backbone.Model

    defaults:
      'name' : ''

    initialize: ->
      @setUpFilesAndFoldersIfNeeded()
      super

    parse: (response) ->
      @setUpFilesAndFoldersIfNeeded()

      @folders.url = response.folders_url
      @files.url   = response.files_url
      super

    setUpFilesAndFoldersIfNeeded: ->
      unless @folders
        @folders = new Backbone.Collection
        @folders.model = Folder
      unless @files
        @files = new Backbone.Collection

    expand: (force=false) ->
      @isExpanded = true
      @trigger 'expanded'
      unless @expandDfd || force
        @isExpanding = true
        @trigger 'beginexpanding'
        @expandDfd = $.Deferred().done =>
          @isExpanding = false
          @trigger 'endexpanding'

        selfHasntBeenFetched = @folders.url is @folders.constructor::url or @files.url is @files.constructor::url
        fetchDfd = @fetch() if selfHasntBeenFetched || force
        $.when(fetchDfd).done =>
          foldersDfd = @folders.fetch() unless @get('folders_count') is 0
          filesDfd = @files.fetch() unless @get('files_count') is 0
          $.when(foldersDfd, filesDfd).done(@expandDfd.resolve)

    collapse: ->
      @isExpanded = false
      @trigger 'collapsed'

    toggle: ->
      if @isExpanded
        @collapse()
      else
        @expand()

    contents: ->
      _(@files.models.concat(@folders.models)).sortBy (model) ->
        (model.get('name') || model.get('display_name') || '').toLowerCase()
        
    previewUrlForFile: (file) ->
      if @get('context_type') in ['Course', 'Group']
        "/#{ @get('context_type').toLowerCase() + 's' }/#{ @get('context_id') }/files/#{ file.get('id') }/preview"
      else
        # we need the full path with verifier for user files
        file.get('url')
