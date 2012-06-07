require [
  'jquery'
  'Backbone'
  'compiled/views/groups/dashboard/GroupDashboardView'
  'compiled/views/QuickStartBar/QuickStartBarView'
  'compiled/views/QuickStartBar/DiscussionView'
  'compiled/views/groups/dashboard/AnnouncementView'
  'compiled/views/QuickStartBar/MessageView'
  'compiled/views/ActivityFeed/ActivityFeedItemsView'
  'compiled/groups/dashboard/collections/ActivityFeedItemsCollection'
  'compiled/dashboardToggle'
], ($, {View}, GroupDashboardView, QuickStartBarView, DiscussionView, AnnouncementView, MessageView, ActivityFeedItemsView, GroupActivityFeedItemsCollection, dashboardToggle) ->

  $ ->
    window.dashboard = new GroupDashboardView

      el: document.getElementById('main')

      views:
        quickStartBar: new QuickStartBarView(formViews: [
          DiscussionView
          AnnouncementView
          MessageView
        ])
        activityFeedItems: new ActivityFeedItemsView
          collection: new GroupActivityFeedItemsCollection

    $('.sidebar-header').eq(0).prepend(dashboardToggle('disable'))    
