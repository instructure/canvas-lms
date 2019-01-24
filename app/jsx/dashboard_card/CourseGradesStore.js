/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import _ from 'underscore'
import createStore from 'jsx/shared/helpers/createStore'
import $ from 'jquery'
import DefaultUrlMixin from 'compiled/backbone-ext/DefaultUrlMixin'
import 'compiled/fn/parseLinkHeader'

  var CourseGradesStore = createStore({grades: {}})

  CourseGradesStore.getStateForCourse = function(courseId) {
    if (_.isUndefined(courseId)) return CourseGradesStore.getState()

    if (_.has(CourseGradesStore.getState()['grades'], courseId)) {
      return CourseGradesStore.getState()['grades'][courseId]
    } else {
      CourseGradesStore.getState()['grades'][courseId] = {}
      CourseGradesStore._fetchForCourse(courseId)
      return {}
    }
  }

  function getActiveStudentGrade(course){
    if (course.enrollments) {
      return _.findWhere(course.enrollments, {"type": "student", "enrollment_state": "active"})  || {}
    } else {
      return {}
    }
  }

  CourseGradesStore._fetchForCourse = function(courseId) {
    var state
    // console.log()
    $.getJSON('/api/v1/courses/' + courseId + '/?include[]=total_scores&include[]=observed_users', function(grades) {
      state = CourseGradesStore.getState()
      state['grades'][courseId] = {
        grades: getActiveStudentGrade(grades)
      }
      CourseGradesStore.setState(state)
    })
  }

export default CourseGradesStore
