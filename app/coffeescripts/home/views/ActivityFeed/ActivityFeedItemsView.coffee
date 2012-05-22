define [
  'Backbone'
  'compiled/home/collections/ActivityFeedItemsCollection'
  'compiled/home/util/activityFeedItemViewFactory'
  'jst/activityFeed/ActivityFeedItemsView'
], ({View, Collection, Model}, ActivityFeedItemsCollection, activityFeedItemViewFactory, template) ->

  class ActivityFeedItemsView extends View

    initialize: ->
      super
      @collection ?= new ActivityFeedItemsCollection
      @collection.on 'add', @addActivityFeedItem
      @collection.on 'reset', @onResetActivityFeedItems
      @collection.fetch()

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
      @collection.each @addActivityFeedItem

    filterByKey: (key) =>
      filter = @parseKey key
      @collection.urlKey = filter.type
      @collection.filter = filter.value
      @$itemList.html('<li>loading</li>')
      @collection.fetch()

    refresh: (opts) =>
      @collection.fetch add: true, animate: true

    ##
    # Splits something like "course:123" into {type: 'course', value: 123}
    # and "everything" into {type: 'everything'}
    parseKey: (key) ->
      filter = {}
      matches = key.match /(.+):(.+)/

      if matches
        filter.type = matches[1]
        filter.value = matches[2]
      else
        filter.type = key

      filter

    render: ->
      @$el.html template()
      @cacheElements()
      super

    cacheElements: ->
      @$itemList = @$ '.activityFeedItemsList'

