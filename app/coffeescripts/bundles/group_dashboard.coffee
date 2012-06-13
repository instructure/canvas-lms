require [
  'jquery'
  'Backbone'
  'compiled/views/groups/dashboard/GroupDashboardView'
  'compiled/views/QuickStartBar/QuickStartBarView'
  'compiled/views/groups/dashboard/DiscussionView'
  'compiled/views/groups/dashboard/AnnouncementView'
  'compiled/views/groups/dashboard/MessageView'
  'compiled/views/ActivityFeed/ActivityFeedItemsView'
  'compiled/groups/dashboard/collections/ActivityFeedItemsCollection'
  'compiled/views/Kollections/IndexView'
  'compiled/collections/KollectionCollection'

], ($, {View}, GroupDashboardView, QuickStartBarView, DiscussionView, AnnouncementView, MessageView, ActivityFeedItemsView, GroupActivityFeedItemsCollection, KollectionIndexView, KollectionCollection) ->

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
        kollectionIndexView: new KollectionIndexView
          collection: do ->
            collection = new KollectionCollection
            collection.url = "/api/v1/groups/#{ENV.GROUP_ID}/collections"
            collection
