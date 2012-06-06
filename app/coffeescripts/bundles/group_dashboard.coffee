require [
  'jquery'
  'Backbone'
  'compiled/groups/dashboard/views/GroupDashboardView'
  'compiled/views/QuickStartBar/QuickStartBarView'
  'compiled/views/ActivityFeed/ActivityFeedItemsView'
  'compiled/groups/dashboard/collections/ActivityFeedItemsCollection'
  'compiled/dashboardToggle'
], ($, {View}, GroupDashboardView, QuickStartBarView, ActivityFeedItemsView, GroupActivityFeedItemsCollection, dashboardToggle) ->

  $ ->
    window.dashboard = new GroupDashboardView

      el: document.getElementById('main')

      views:
        quickStartBar: new QuickStartBarView([
          {type: 'discussion'}
          {type: 'announcement'}
          {type: 'message'}
        ])
        activityFeedItems: new ActivityFeedItemsView
          collection: new GroupActivityFeedItemsCollection

    $('.sidebar-header').eq(0).prepend(dashboardToggle('disable'))    
