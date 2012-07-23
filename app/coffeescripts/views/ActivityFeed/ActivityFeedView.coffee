define ['Backbone'], ({View}) ->

  ##
  # Controls the activity feed and the panel that filters it
  class ActivityFeedView extends View

    ##
    # Requires these sub-views
    #
    # ActivityFeedFilterView
    # ActivityFeedItemsView

    events:
      'click .drawerToggle': 'toggleDrawer'

    initialize: ->
      super
      @options.views.activityFeedFilter.on 'filter',
        @options.views.activityFeedItems.filterByContextKey

    toggleDrawer: ->
      @drawerClosed = not @drawerClosed
      @$el.toggleClass 'drawerClosed', @drawerClosed
      @options.views.activityFeedItems.toggleDrawerIcon @drawerClosed

    render: ->
      @$el.html """
        <div class="activityFeedFilter content-box border border-tbl border-round-tl"></div>
        <div class="activityFeedItems content-box border border-trbl border-round-t box-shadow"></div>
      """
      super

    filter: ->
      @drawerClosed = @$el.hasClass 'drawerClosed'

