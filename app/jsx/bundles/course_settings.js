import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import NavigationView from 'compiled/views/course_settings/NavigationView'
import FeatureFlagAdminView from 'compiled/views/feature_flags/FeatureFlagAdminView'
import CourseImageSelector from 'jsx/course_settings/components/CourseImageSelector'
import configureStore from 'jsx/course_settings/store/configureStore'
import initialState from 'jsx/course_settings/store/initialState'
import 'vendor/jquery.cookie'
import 'course_settings'
import 'grading_standards'

const navView = new NavigationView({el: $('#tab-navigation')})

const featureFlagView = new FeatureFlagAdminView({el: '#tab-features'})
featureFlagView.collection.fetchAll()

$(() => navView.render())


if (window.ENV.COURSE_IMAGES_ENABLED) {
  const courseImageStore = configureStore(initialState)

  ReactDOM.render(
    <CourseImageSelector
      store={courseImageStore}
      name="course[image]"
      courseId={window.ENV.COURSE_ID}
    />,
    $('.CourseImageSelector__Container')[0]
  )
}
