require [
  'jquery'
  'Backbone'
  'compiled/groups/dashboard/views/GroupDashboardView'
  'compiled/quickStartBar/views/QuickStartBarView'
  'compiled/ActivityFeed/views/ActivityFeedItemsView'
  'compiled/groups/dashboard/collections/ActivityFeedItemsCollection'
], ($, {View}, GroupDashboardView, QuickStartBarView, ActivityFeedItemsView, GroupActivityFeedItemsCollection) ->

  $ ->
    window.dashboard = new GroupDashboardView

      el: document.getElementById('main')

      views:
        quickStartBar: new QuickStartBarView
        activityFeedItems: new ActivityFeedItemsView
          collection: new GroupActivityFeedItemsCollection
