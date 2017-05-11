/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import NavigationView from 'compiled/views/course_settings/NavigationView'
import FeatureFlagAdminView from 'compiled/views/feature_flags/FeatureFlagAdminView'
import CourseImageSelector from 'jsx/course_settings/components/CourseImageSelector'
import configureStore from 'jsx/course_settings/store/configureStore'
import initialState from 'jsx/course_settings/store/initialState'
import 'jquery.cookie'
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
