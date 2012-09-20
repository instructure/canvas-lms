define [
  'jst/discussions/noResults'
  'underscore'
  'compiled/views/DiscussionTopic/FilterEntryView'
  'compiled/views/DiscussionTopic/EntryCollectionView'
  'compiled/collections/EntryCollection'
  'compiled/regexp/rEscape'
], (noResultsTemplate, _, FilterEntryView, EntryCollectionView, EntryCollection, rEscape) ->

  class DiscussionFilterResultsView extends EntryCollectionView

    defaults: _.extend({}, EntryCollectionView::defaults,
      descendants: 0
      displayShowMore: true
      threaded: true
    )

    initialize: ->
      super
      @allData = @options.allData

    attach: ->
      @model.on 'change', @renderOrTeardownResults

    createEntryView: ->
      new FilterEntryView
        model: entry
        treeView: EntryCollectionView
        descendants: @options.descendants
        children: @collection.options.perPage
        showMoreDescendants: @options.showMoreDescendants
        threaded: @options.threaded

    resetCollection: (models) =>
      collection = new EntryCollection models, perPage: 10
      @collection = collection.getPageAsCollection 0
      @collection.on 'add', @add
      @render()

    add: (entry) =>
      view = new FilterEntryView model: entry
      view.render()
      view.on 'click', =>
        @clearModel()
        setTimeout =>
          @trigger 'clickEntry', view.model
        , 1
      @list.append view.el

    clearModel: =>
      @model.set
        unread: false
        query: null

    render: =>
      super if @collection?
      @$el.removeClass 'hidden'

    renderOrTeardownResults: =>
      if @model.hasFilter()
        results = (entry for id, entry of @allData.flattened)
        for filter, value of @model.toJSON()
          results = @["#{filter}Filter"](value, results)
        if results.length
          @resetCollection results
        else
          @renderNoResults()
      else
        @$el.addClass 'hidden' unless @model.hasFilter()

    renderNoResults: ->
      @render()
      @$el.html noResultsTemplate

    unreadFilter: (unread, results) =>
      return results unless unread
      unread = _.filter results, (entry) ->
        entry.read_state is 'unread'
      unread.sort (a, b) ->
        Date.parse(a.created_at) - Date.parse(b.created_at)

    queryFilter: (query, results) =>
      regexps = for word in (query ? '').trim().split(/\s+/g)
        new RegExp rEscape(word), 'i'
      return results unless regexps.length
      _.filter results, (entry) ->
        concat = """
          #{entry.message}
          #{entry.author.display_name} 
        """
        for regexp in regexps
          return false unless regexp.test concat
        true

