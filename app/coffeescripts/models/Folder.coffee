define [
  'require'
  'Backbone'
  'jquery'
  'underscore'
  'compiled/collections/PaginatedCollection'
  'compiled/collections/FilesCollection'
], (require, Backbone, $, _, PaginatedCollection, FilesCollection) ->

  # this breaks the circular dependency between Folder <-> FoldersCollection
  FoldersCollection = null
  require ['compiled/collections/FoldersCollection'], (fc) -> FoldersCollection = fc

  class Folder extends Backbone.Model

    defaults:
      'name' : ''

    initialize: (options) ->
      @contentTypes ||= options?.contentTypes
      @setUpFilesAndFoldersIfNeeded()
      super

    parse: (response) ->
      json = super
      @contentTypes ||= response.contentTypes
      @setUpFilesAndFoldersIfNeeded()

      @folders.url = response.folders_url
      @files.url   = response.files_url

      json

    setUpFilesAndFoldersIfNeeded: ->
      unless @folders
        @folders = new FoldersCollection [], parentFolder: this
      unless @files
        @files = new FilesCollection [], parentFolder: this

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

    previewUrl: ->
      if @get('context_type') in ['Course', 'Group']
        "/#{ @get('context_type').toLowerCase() + 's' }/#{ @get('context_id') }/files/{{id}}/preview"
