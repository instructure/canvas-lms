require [
  'jquery'
  'Backbone'
  'compiled/home/views/DashboardView'
  'compiled/quickStartBar/views/QuickStartBarView'
  'compiled/ActivityFeed/views/ActivityFeedView'
  'compiled/home/views/SideBar/SideBarView'
  'compiled/ActivityFeed/views/ActivityFeedFilterView'
  'compiled/ActivityFeed/views/ActivityFeedItemsView'
  'compiled/home/views/SideBar/TodoView'
  'compiled/home/views/SideBar/ComingUpView'
], ($, {View}, DashboardView, QuickStartBarView, ActivityFeedView, SideBarView, ActivityFeedFilterView, ActivityFeedItemsView, TodoView, ComingUpView) ->

  $ ->
    window.dashboard = new DashboardView

      el: document.getElementById('content')

      views:
        quickStartBar: new QuickStartBarView
        activityFeed: new ActivityFeedView
          views:
            activityFeedFilter: new ActivityFeedFilterView
            activityFeedItems: new ActivityFeedItemsView
        dashboardAside: new SideBarView
          views:
            todo: new TodoView
            comingUp: new ComingUpView
