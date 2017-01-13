define [
  'underscore'
  'jquery'
  'jst/DiscussionTopics/pageNav'
  'Backbone'
  'compiled/views/DiscussionTopic/EntryCollectionView'
  'compiled/jquery/scrollIntoView'
  'underscore.flattenObjects'
], (_, $, pageNavTemplate, Backbone, EntryCollectionView) ->

  class EntriesView extends Backbone.View

    defaults:
      initialPage: 0
      descendants: 2
      showMoreDescendants: 50
      children: 3

    $window: $ window

    events:
      'keydown': 'handleKeyDown'

    initialize: ->
      super
      @collection.on 'add', @addEntry
      @model.on 'change', @hideIfFiltering

    showDeleted: (show) =>
      @$el.toggleClass 'show-deleted', show

    hideIfFiltering: =>
      if @model.hasFilter()
        @$el.addClass 'hidden'
      else
        @$el.removeClass 'hidden'

    addEntry: (entry) =>
      @collectionView.collection.add entry

    goToEntry: (id) =>
      # can take an id or an entry object so we don't have to get the entry
      # data when we're trying again
      if typeof id is 'object'
        entryData = id
        id = entryData.entry.id
      # dom is the fastest access to see if the entry is already rendered
      $el = $ "#entry-#{id}"
      if $el.length
        return @scrollToEl $el
      entryData ?= @collection.getEntryData id
      if @collection.currentPage is entryData.page
        if entryData.levels is 0
          @expandToUnrenderedEntry entryData
        else
          @descendToUnrenderedEntry entryData
      else
        @renderAndGoToEntry entryData

    expandToUnrenderedEntry: (entryData) ->
      {entry} = entryData
      $el = {}
      until $el.length
        entry = entry.parent
        $el = $ "#entry-#{entry.id}"
      view = $el.data 'view'
      if view.treeView
        view.treeView.loadNext()
      else
        view.renderTree()
      # try again, will do this as many times as it takes
      @goToEntry entryData

    ##
    # finds the last rendered parent, re-orders the parents to be the first
    # child, renders the tree down to the entry
    descendToUnrenderedEntry: (entryData) ->
      {entry} = entryData
      parent = entry
      descendants = -1
      $el = {}
      # look for last rendered parent
      until $el.length
        child = parent
        parent = child.parent
        descendants++
        # put the child on top so we can easily render it
        replies = _.without parent.replies, child
        replies.unshift child
        parent.replies = replies
        # see if its rendered
        $el = $ "#entry-#{child.id}"
      view = $el.data 'view'
      view.renderTree descendants: descendants
      # try again
      @goToEntry entryData

    renderAndGoToEntry: (entryData) ->
      @render entryData.page + 1
      # try again
      @goToEntry entryData

    scrollToEl: ($el) ->
      @$window.scrollTo $el, 200,
        offset: -150
        onAfter: =>
          $el.find('.discussion-title a').first().focus()
          # pretty blinking
          setTimeout (-> $el.addClass 'highlight' ), 200
          setTimeout (-> $el.removeClass 'highlight' ), 400
          setTimeout (-> $el.addClass 'highlight' ), 600
          once = =>
            $el.removeClass 'highlight'
            @$window.off 'scroll', once
            @trigger 'scrollAwayFromEntry'
          # behind setTimeout because onAfter doesn't seem to work properly,
          # and triggers the scroll event we're adding here
          setTimeout =>
            @$window.on "scroll", once
            setTimeout once, 5000
          , 10

    ##
    # Render a specific page with `page: n`
    render: (page=1) =>
      @teardown()
      @collectionView = new EntryCollectionView
        el: @$el[0]
        collection: @collection.getPageAsCollection(page - 1, perPage: @options.children)
        descendants: @options.descendants
        showMoreDescendants: @options.showMoreDescendants
        displayShowMore: no
        threaded: @options.threaded
        root: true
        collapsed: @model.get 'collapsed'
      @collectionView.render()
      @renderPageNav()
      this

    teardown: ->
      @$el.empty()

    renderPageNav: ->
      total = @collection.totalPages()
      current = @collection.currentPage + 1
      return if total < 2
      pagesToShow = 3
      locals = current: current
      locals.showFirst = total > pagesToShow and current isnt 1
      locals.lastPage = total if total > pagesToShow and current isnt total
      locals.pages = if total < pagesToShow + 1
        [1..total]
      else if locals.showFirst and locals.lastPage
        [current - 1, current, current + 1]
      else if locals.showFirst and !locals.lastPage
        [current - 2, current - 1, current]
      else if !locals.showFirst and locals.lastPage
        [current, current + 1, current + 2]
      html = pageNavTemplate locals
      @$el.prepend(html).append(html)

    handleKeyDown: (e) =>
      nodeName = e.target.nodeName.toLowerCase()
      return if nodeName == 'input' || nodeName == 'textarea'
      return if e.which != 74 && e.which != 75 # j, k
      entry = $(e.target).closest('.entry')
      @traverse(entry, reverse = e.which == 75)
      e.preventDefault()
      e.stopPropagation()

    traverse: (el, reverse) ->
      id = el.attr('id').replace('entry-', '')

      json = @collection.toJSON()
      # sub-collections are displayed in reverse when flat, in imitation of Facebook
      list = _.flattenObjects(json, 'replies', backward = !@options.threaded)
      entry = _.find(list, (x) -> x.id+'' is id)
      pos = _.indexOf(list, entry)
      pos += if reverse then -1 else 1
      pos = Math.min(Math.max(0, pos), list.length - 1)
      next = list[pos]
      @goToEntry(next.id)
