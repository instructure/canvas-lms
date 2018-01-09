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
import createStore from '../shared/helpers/createStore'
import $ from 'jquery'
import DefaultUrlMixin from 'compiled/backbone-ext/DefaultUrlMixin'
import 'compiled/fn/parseLinkHeader'

  var CourseActivitySummaryStore = createStore({streams: {}})

  CourseActivitySummaryStore.getStateForCourse = function(courseId) {
    if (_.isUndefined(courseId)) return CourseActivitySummaryStore.getState()

    if (_.has(CourseActivitySummaryStore.getState()['streams'], courseId)) {
      return CourseActivitySummaryStore.getState()['streams'][courseId]
    } else {
      CourseActivitySummaryStore.getState()['streams'][courseId] = {}
      CourseActivitySummaryStore._fetchForCourse(courseId)
      return {}
    }
  }

  CourseActivitySummaryStore._fetchForCourse = function(courseId) {
    var state

    $.getJSON('/api/v1/courses/' + courseId + '/activity_stream/summary', function(stream) {
      state = CourseActivitySummaryStore.getState()
      state['streams'][courseId] = {
        stream: stream
      }
      CourseActivitySummaryStore.setState(state)
    })
  }

export default CourseActivitySummaryStore
