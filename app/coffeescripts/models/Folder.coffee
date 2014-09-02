define [
  'require'
  'Backbone'
  'jquery'
  'underscore'
  'compiled/util/deparam'
  'compiled/collections/PaginatedCollection'
  'compiled/collections/FilesCollection'
  'compiled/collections/FoldersCollection'
], (require, Backbone, $, _, deparam, PaginatedCollection, FilesCollection, _THIS_WILL_BE_NULL_) ->

  class Folder extends Backbone.Model

    defaults:
      'name' : ''
      sort: 'name'
      order: 'asc' #or 'desc'

    initialize: (options) ->
      @contentTypes ||= options?.contentTypes
      @setUpFilesAndFoldersIfNeeded()
      @on 'change:sort change:order', @setQueryStringParams
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

    childrenSorter: (a, b) ->
      sortProp = @get('sort')
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

      res = 0 - res if @get('order') is 'desc'
      res

    children: ->
      (@folders.toArray().concat @files.toArray()).sort(@childrenSorter.bind(this))

    loadAll: ->
      loadType = (type) =>
        getNextPage = => @[type].fetch(page: 'next').pipe(getNextPage) unless @[type].loadedAll
        getNextPage()
      $.when ['folders', 'files'].map(loadType)...

    # getNextPage: ->
    #   loadType = (type) => @[type].fetch(page: 'next') unless @[type].loadedAll
    #   $.when ['folders', 'files'].map(loadType)...
    #   res = dfd.promise()
    #   res.then -> console.log('got next page', this, arguments)
    #   res

    # loadAll: ->
    #   return if @files.loadedAll and @files.loadedAll
    #   res = @getNextPage().pipe @loadAll.bind(this)
    #   res.then -> console.log('got All', this, arguments)
    #   res


    # TODO: It would be better to do this in a way that doesn't assume we
    # need to have 'include[]=user' and keeps other query string params around
    setQueryStringParams: ->
      newParams =
        include: ['user']
        per_page: 20
        sort: @get('sort')
        order: @get('order')

      ['folders', 'files'].map (type) =>
        return if @[type].loadedAll
        url = new URL(@[type].url)
        params = deparam(url.search)
        url.search = $.param _.extend(params, newParams)
        @[type].url = url.toString()
        @[type].reset()
