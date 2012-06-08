define [
  'Backbone'
  'compiled/collections/ActivityFeedItemsCollection'
  'compiled/views/ActivityFeed/activityFeedItemViewFactory'
  'jst/activityFeed/ActivityFeedItemsView'
], ({View, Collection, Model}, ActivityFeedItemsCollection, activityFeedItemViewFactory, template) ->

  class ActivityFeedItemsView extends View

    events:
      'click .activityFeedItemsFilter': 'onClickItemFilter'

    template: template

    els:
      '.activityFeedItemsList': '$itemList'
      '.activityFeedItemsFilter a': '$itemFilters'
      '.drawerToggle': '$drawerToggle'

    initialize: ->
      super
      @collection ?= new ActivityFeedItemsCollection
      @collection.on 'add', @addActivityFeedItem
      @collection.on 'reset', @onResetActivityFeedItems
      @collection.fetch()

    toggleDrawerIcon: (drawerClosed) ->
      if drawerClosed
        @$drawerToggle.removeClass 'icon-toggle-left'
        @$drawerToggle.addClass 'icon-toggle-right'
      else
        @$drawerToggle.addClass 'icon-toggle-left'
        @$drawerToggle.removeClass 'icon-toggle-right'

    addActivityFeedItem: (activityFeedItem, collection, fetchOptions) =>
      view = activityFeedItemViewFactory activityFeedItem
      @$itemList.prepend view.$el
      view.$el.hide() if fetchOptions.animate
      view.render()
      if fetchOptions.animate
        setTimeout ->
          view.$el.slideDown()
        , 150

    onResetActivityFeedItems: =>
      @$itemList.empty()
      if @collection.length
        @collection.each @addActivityFeedItem
      else
        # TODO: empty stream template
        @$itemList.html "TODO: empty stream template for #{@collection.urlKey}:#{@collection.filter}"

    filterByContextKey: (key) =>
      filter = @parseContextKey key
      @collection.urlKey = filter.type
      @collection.filter = filter.value
      @$itemList.html('<li>loading</li>')
      @collection.fetch()

      # remove item filter when filtering by context
      @setActiveFilterElement 'all'

    refresh: (opts) =>
      @collection.fetch add: true, animate: true

    ##
    # Splits something like "course:123" into {type: 'course', value: 123}
    # and "everything" into {type: 'everything'}
    parseContextKey: (key) ->
      filter = {}
      matches = key.match /(.+):(.+)/
      if matches
        filter.type = matches[1]
        filter.value = matches[2]
      else
        filter.type = key
      filter

    onClickItemFilter: (event) ->
      event.preventDefault()
      value = $(event.target).data 'value'
      @filterByItemType value

    ##
    # This is pretty disgusting, but when the API for filtering is written
    # it all goes away and we'll use regular filter method
    filterByItemType: (type) ->
      @setActiveFilterElement type
      if type is 'all'
        @$itemList.find('li').show()
      else
        @$itemList.find('li').hide()
        className = type.replace(/s$/, '')
        $els = @$itemList.find("li.#{className}")
        if $els.length
          $els.show()
        else
          @$itemList.append("<li class='none'>TODO: No items, wah wah</li>")

    setActiveFilterElement: (type) ->
      @$itemList.find('.none').remove() # kill empty result messages
      @$itemFilters.removeClass 'active'
      @$itemFilters.filter("[data-value=#{type}]").addClass 'active'

