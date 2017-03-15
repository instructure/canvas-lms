require [
  'jquery'
  'underscore'
  'Backbone'
  'react'
  'react-dom'
  'compiled/views/course_settings/NavigationView'
  'compiled/collections/UserCollection'
  'compiled/views/feature_flags/FeatureFlagAdminView'
  'jsx/course_settings/components/CourseImageSelector'
  'jsx/course_settings/store/configureStore'
  'jsx/course_settings/store/initialState'
  'vendor/jquery.cookie'
  'course_settings'
  'grading_standards'
], ($, _, Backbone, React, ReactDOM, NavigationView, UserCollection, FeatureFlagAdminView, CourseImageSelector, configureStore, initialState) ->
  nav_view = new NavigationView
    el: $('#tab-navigation')

  featureFlagView = new FeatureFlagAdminView(el: '#tab-features')
  featureFlagView.collection.fetchAll()

  $ ->
    nav_view.render()



  if (window.ENV.COURSE_IMAGES_ENABLED)
    courseImageStore = configureStore(initialState)

    ReactDOM.render(
      React.createElement(CourseImageSelector, {
        store: courseImageStore,
        name: "course[image]",
        courseId: window.ENV.COURSE_ID
      }), $('.CourseImageSelector__Container')[0]
    )
