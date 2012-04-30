define [
  'Backbone'
  'compiled/home/util/activityFeedItemViewFactory'
], ({View, Collection, Model}, activityFeedItemViewFactory) ->

  class ActivityFeedItemsCollection extends Collection
    model: Model.extend()
    url: '/api/v1/users/self/activity_stream'

  class ActivityFeedItemsView extends View

    initialize: ->
      @collection ?= new ActivityFeedItemsCollection
      @collection.on 'add', @addActivityFeedItem
      @collection.on 'reset', @resetActivityFeedItems
      @collection.fetch()

    addActivityFeedItem: (activityFeedItem) =>
      view = activityFeedItemViewFactory activityFeedItem
      view.render()
      @$itemList.append view.el

    resetActivityFeedItems: =>
      @collection.each @addActivityFeedItem

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

