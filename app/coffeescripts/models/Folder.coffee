define [
  'require'
  'Backbone'
  'underscore'
  'compiled/collections/PaginatedCollection'
  'compiled/collections/FilesCollection'
  'compiled/collections/FoldersCollection'
], (require, Backbone, _, PaginatedCollection, FilesCollection, _THIS_WILL_BE_NULL_) ->

  class Folder extends Backbone.Model

    defaults:
      'name' : ''

    initialize: (options) ->
      @contentTypes ||= options?.contentTypes
      @setUpFilesAndFoldersIfNeeded()
      @on 'change:sort change:order', @setQueryStringParams
      super

    url: ->
      if @isNew()
        super
      else
        "/api/v1/folders/#{@id}"

    parse: (response) ->
      json = super
      @contentTypes ||= response.contentTypes
      @setUpFilesAndFoldersIfNeeded()

      @folders.url = response.folders_url
      @files.url   = response.files_url

      json

    setUpFilesAndFoldersIfNeeded: ->
      unless @folders
        # this breaks the circular dependency between Folder <-> FoldersCollection
        FoldersCollection = require('compiled/collections/FoldersCollection')
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

    isEmpty: ->
      !!(@files.loadedAll and (@files.length is 0)) and (@folders.loadedAll and (@folders.length is 0))

    # `full_name` will be something like "course files/some folder/another".
    # For routing in the react app in the browser, we want something that will take that "course files"
    # out. because urls will end up being /courses/2/files/folder/some folder/another
    EVERYTHING_BEFORE_THE_FIRST_SLASH = /^[^\/]+\/?/
    urlPath: ->
      (@get('full_name') or '').replace(EVERYTHING_BEFORE_THE_FIRST_SLASH, '')

    @resolvePath = (contextType, contextId, folderPath) ->
      url = "/api/v1/#{contextType}/#{contextId}/folders/by_path#{folderPath}"
      $.get(url).pipe (folders) ->
        folders.map (folderAttrs) ->
          new Folder(folderAttrs, {parse: true})


    getSortProp = (model, sortProp) ->
      # if we are sorting by name use 'display_name' for files and 'name' for folders.
      if sortProp is 'name' and not (model instanceof Folder)
        model.get('display_name')
      else if sortProp is 'user'
        model.get('user')?.display_name
      else
        model.get(sortProp)

    childrenSorter: (sortProp='name', sortOrder='asc', a, b) ->
      a = getSortProp(a, sortProp)
      b = getSortProp(b, sortProp)
      res = if a is b
              0
            else if a > b or a is undefined
              1
            else if a < b or b is undefined
              -1
            else
              throw new Error("wat? error sorting")

      res = 0 - res if sortOrder is 'desc'
      res

    children: ({sort, order}) ->
      (@folders.toArray().concat @files.toArray()).sort(@childrenSorter.bind(null, sort, order))
