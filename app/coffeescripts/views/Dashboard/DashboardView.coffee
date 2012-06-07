define ['Backbone'], ({View}) ->

  ##
  # Top-level view of the entire dashboard
  class DashboardView extends View

    ###
    views:
      quickStartBar:
      activityFeed:
        views:
          activityFeedFilter:
          activityFeedItems:
      dashboardAside:
        views:
          todo:
          comingUp:
    ###

    initialize: ->
      @renderViews()
      @options.views.quickStartBar.on 'save',
        @options.views.activityFeed.options.views.activityFeedItems.refresh

