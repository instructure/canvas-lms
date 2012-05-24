require [
  'jquery'
  'Backbone'
  'compiled/groups/dashboard/views/GroupDashboardView'
  'compiled/home/views/quickStartBar/QuickStartBarView'
  'compiled/ActivityFeed/views/ActivityFeedItemsView'
  'compiled/groups/dashboard/collections/ActivityFeedItemsCollection'
  'compiled/home/views/SideBar/SideBarView'
], ($, {View}, GroupDashboardView, QuickStartBarView, ActivityFeedItemsView, ActivityFeedItemsCollection, SideBarView) ->

  $ ->
    window.dashboard = new GroupDashboardView

      el: document.getElementById('main')

      views:
        quickStartBar: new QuickStartBarView
        activityFeedItems: new ActivityFeedItemsView
          collection: new ActivityFeedItemsCollection
    dashboardAside: new SideBarView
