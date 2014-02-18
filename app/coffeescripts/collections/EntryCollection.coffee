define [
  'Backbone'
  'compiled/models/Entry'
  'compiled/arr/walk'
], (Backbone, Entry, walk) ->

  ##
  # Collection for Entries
  class EntryCollection extends Backbone.Collection

    defaults:
      perPage: 50
      initialPage: 0

    model: Entry

    totalPages: ->
      Math.ceil @length / @options.perPage

    getPage: (page) ->
      return @getPage(@currentPage + 1) if page is 'next'
      @currentPage = page
      indices = @getPageIndicies page
      @toArray().slice indices.start, indices.end

    getPageIndicies: (page) ->
      start = page * @options.perPage
      end = start + @options.perPage
      {start, end}

    getPageAsCollection: (page, options = @options) ->
      page = new @constructor @getPage(page), options
      page.fullCollection = this
      page

    setAllReadState: (newReadState) ->
      @each (entry) ->
        entry.set 'read_state', newReadState

    ##
    # This could have been two or three well-named methods, but it doesn't make
    # a whole lot of sense to walk the tree over and over to get each piece of
    # data that we're interested in.
    #
    # This takes an entry `id` and finds the entry and returns an object with
    # the entry, rootParent, page, and number of levels down
    getEntryData: (id) ->
      entry = null
      rootParent = null
      levels = 0
      walk @toJSON(), 'replies', (item) =>
        isARootEntry = @get(item.id)?
        rootParent = item if entry is null and isARootEntry
        if isARootEntry
          levels = 0
        else if entry is null
          levels = levels + 1
        if item.id+'' is id
          entry = item
      return null unless rootParent? and entry?
      rootParentIndex = @indexOf @get rootParent.id
      for page in [0..@totalPages()]
        {start, end} = @getPageIndicies page
        break if rootParentIndex >= start and rootParentIndex < end
      {entry, rootParent, page, levels}

