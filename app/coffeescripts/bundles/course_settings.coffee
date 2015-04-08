require [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/course_settings/NavigationView'
  'compiled/collections/UserCollection'
  'compiled/views/feature_flags/FeatureFlagAdminView'
  'vendor/jquery.cookie'
  'course_settings'
  'grading_standards'
], ($, _, Backbone, NavigationView, UserCollection, FeatureFlagAdminView) ->
  nav_view = new NavigationView
    el: $('#tab-navigation')

  featureFlagView = new FeatureFlagAdminView(el: '#tab-features')
  featureFlagView.collection.fetchAll()

  $ ->
    nav_view.render()

