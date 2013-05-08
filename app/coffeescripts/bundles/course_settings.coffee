require [
  'compiled/views/course_settings/NavigationView'
  'compiled/collections/UserCollection'
  'vendor/jquery.cookie'
  'course_settings'
  'grading_standards'
], (NavigationView, UserCollection) ->

  nav_view = new NavigationView
    el: $('#tab-navigation')

  $ ->
    nav_view.render()

