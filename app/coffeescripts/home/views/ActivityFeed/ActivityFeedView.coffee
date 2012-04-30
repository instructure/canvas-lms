define ['Backbone'], ({View}) ->

  ##
  # Controls the activity feed and the panel that filters it
  class ActivityFeedView extends View

    events:
      'click .icon-drawer-toggle': 'toggleDrawer'
    
    toggleDrawer: ->
      @$el.toggleClass 'drawerClosed'

    render: ->
      @$el.html """
        <div class="activityFeedFilter content-box border border-tbl border-round-tl"></div>
        <div class="activityFeedItems content-box border border-trbl border-round-t box-shadow"></div>
      """
      super

