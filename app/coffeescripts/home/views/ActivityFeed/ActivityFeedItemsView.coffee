define [
  'Backbone'
  'compiled/home/util/activityFeedItemViewFactory'
], ({View, Collection, Model}, activityFeedItemViewFactory) ->

  class ActivityFeedItemsCollection extends Collection
    model: Model.extend()
    urlKey: 'everything'
    filter: ''
    urls:
      everything: '/api/v1/users/self/activity_stream'
      course: '/api/v1/courses/:filter/activity_stream'
    url: ->
      @urls[@urlKey].replace /:filter/, @filter



  class ActivityFeedItemsView extends View

    initialize: ->
      super
      @collection ?= new ActivityFeedItemsCollection
      @collection.on 'add', @addActivityFeedItem
      @collection.on 'reset', @resetActivityFeedItems
      @collection.fetch()

    addActivityFeedItem: (activityFeedItem) =>
      view = activityFeedItemViewFactory activityFeedItem
      view.render()
      @$itemList.append view.el

    resetActivityFeedItems: =>
      @$itemList.empty()
      @collection.each @addActivityFeedItem

    filterByKey: (key) =>
      filter = @parseKey key
      @collection.urlKey = filter.type
      @collection.filter = filter.value
      @$itemList.html('<li>loading</li>')
      @collection.fetch()

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
      @$el.html """
        <header class="activityFeedItemsToolbar toolbar border border-trbl border-round-t">
          <div class="row-fluid">
            <div class="span5">
              <h2 class="header"><i class="icon-drawer-toggle">☭</i>Recent Activity</h2>
            </div>
            <div class="span7">
              <ul class="activityFeedItemsFilter nav nav-links">
                <li><a href="#" class="active">All</a>
                <li><a href="#">Announcements</a>
                <li><a href="#">Discussions</a>
                <li><a href="#">Messages</a>
              </ul>
            </div>
          </div>
        </header>
        <ul class="activityFeedItemsList"></ul>
      """
      @cacheElements()
      super

    cacheElements: ->
      @$itemList = @$ '.activityFeedItemsList'

