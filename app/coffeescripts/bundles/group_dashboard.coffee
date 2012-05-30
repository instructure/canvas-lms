require [
  'jquery'
  'Backbone'
  'compiled/groups/dashboard/views/GroupDashboardView'
  'compiled/views/QuickStartBar/QuickStartBarView'
  'compiled/views/ActivityFeed/ActivityFeedItemsView'
  'compiled/groups/dashboard/collections/ActivityFeedItemsCollection'
], ($, {View}, GroupDashboardView, QuickStartBarView, ActivityFeedItemsView, GroupActivityFeedItemsCollection) ->

  $ ->
    window.dashboard = new GroupDashboardView

      el: document.getElementById('main')

      views:
        quickStartBar: new QuickStartBarView
        activityFeedItems: new ActivityFeedItemsView
          collection: new GroupActivityFeedItemsCollection
