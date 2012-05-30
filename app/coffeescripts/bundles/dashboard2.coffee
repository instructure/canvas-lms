require [
  'jquery'
  'Backbone'
  'compiled/views/Dashboard/DashboardView'
  'compiled/views/QuickStartBar/QuickStartBarView'
  'compiled/views/ActivityFeed/ActivityFeedView'
  'compiled/views/Dashboard/SideBarView'
  'compiled/views/ActivityFeed/ActivityFeedFilterView'
  'compiled/views/ActivityFeed/ActivityFeedItemsView'
  'compiled/views/Dashboard/TodoView'
  'compiled/views/Dashboard/ComingUpView'
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
