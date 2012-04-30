##
# Controls the activity feed and the panel that filters it
class ActivityFeedView extends View
  views:
    '.activityFeedFilter': ActivityFeedFilterView
    '.activityFeedItems' : ActivityFeedItemView

##
# Filters the activity feed
class ActivityFeedFilterView extends DrawerView
  views:
    '.courseList' : CourseListView
    '.community'  : CommunityView

##
# List of courses that filters the activity feed
class CourseListView extends NavListView

##
# A course item in a CourseListView
class CourseListItemView extends View

##
# Community items that filter the activity feed
class CommunityView extends NavListView

##
# A group item the a CommunityView
class GroupItemView extends NavListView

##
# Controls the items in an ActivityFeed
class ActivityFeedItemsView extends View
  views:
    '.activityFeedItemsFilterView': ActivityFeedItemsFilterView

##
# Filters the items in an ActivityFeedItemsView
class ActivityFeedItemsFilterView extends View

##
# Controls an activity feed item
class ActivityFeedItemView extends View

##
# Controls the todos and coming up items on the dashboard
class DashboardAsideView extends View
  views:
    '.todoView'    : TodoView
    '.comingUpView': ComingUpView

##
# Controls the todo items on the Dashboard
class TodoView extends AsideListView
class TodoItemView extends AsideListItemView

##
# Controls the coming up items on the Dashboard
class ComingUpView extends AsideListView
class ComingUpItemView extends AsideListItemView

##
# Creates LMS objects quickly from one interface
class QuickStartBarView

##
# Controls the global dashboard actions
class DashboardActionsView


