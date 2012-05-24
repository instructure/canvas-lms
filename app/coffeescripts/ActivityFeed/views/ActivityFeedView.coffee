define ['Backbone'], ({View}) ->

  ##
  # Controls the activity feed and the panel that filters it
  class ActivityFeedView extends View

    ##
    # Requires these sub-views
    views:
      activityFeedFilter: null # new ActivityFeedFilterView
      activityFeedItems: null # new ActivityFeedItemsView

    events:
      'click .icon-drawer-toggle': 'toggleDrawer'

    initialize: ->
      super
      @options.views.activityFeedFilter.on 'filter', @options.views.activityFeedItems.filterByKey

    toggleDrawer: ->
      @$el.toggleClass 'drawerClosed'

    render: ->
      @$el.html """
        <div class="activityFeedFilter content-box border border-tbl border-round-tl"></div>
        <div class="activityFeedItems content-box border border-trbl border-round-t box-shadow"></div>
      """
      super

