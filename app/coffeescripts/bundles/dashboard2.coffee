require [
  'jquery'
  'Backbone'
  'compiled/views/Dashboard/DashboardView'
  'compiled/views/QuickStartBar/QuickStartBarView'
  'compiled/views/QuickStartBar/allViews'
  'compiled/views/ActivityFeed/ActivityFeedView'
  'compiled/views/Dashboard/SideBarView'
  'compiled/views/ActivityFeed/ActivityFeedFilterView'
  'compiled/views/ActivityFeed/ActivityFeedItemsView'
  'compiled/views/Dashboard/TodoView'
  'compiled/views/Dashboard/ComingUpView'
  'compiled/dashboardToggle'
  'compiled/registration/incompleteRegistrationWarning'
], ($, {View}, DashboardView, QuickStartBarView, allViews, ActivityFeedView, SideBarView, ActivityFeedFilterView, ActivityFeedItemsView, TodoView, ComingUpView, dashboardToggle, incompleteRegistrationWarning) ->

  $ ->
    window.dashboard = new DashboardView

      el: $('#main')[0]

      views:
        quickStartBar: new QuickStartBarView(formViews: allViews)
        activityFeed: new ActivityFeedView
          views:
            activityFeedFilter: new ActivityFeedFilterView
            activityFeedItems: new ActivityFeedItemsView
        dashboardAside: new SideBarView
          views:
            todo: new TodoView
            comingUp: new ComingUpView

    $('#right-side').prepend(dashboardToggle('disable'))
    incompleteRegistrationWarning(ENV.USER_EMAIL) if ENV.INCOMPLETE_REGISTRATION
