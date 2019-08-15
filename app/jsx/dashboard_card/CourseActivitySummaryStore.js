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

import createStore from '../shared/helpers/createStore'

const CourseActivitySummaryStore = createStore({streams: {}})

// filter a response to raise an error on a 400+ status
function checkStatus(response) {
  if (response.status < 400) {
    return response
  } else {
    const error = new Error(response.statusText)
    error.response = response
    throw error
  }
}

CourseActivitySummaryStore.getStateForCourse = function(courseId) {
  if (typeof courseId === 'undefined') return CourseActivitySummaryStore.getState()

  const {streams} = CourseActivitySummaryStore.getState()
  if (!(courseId in streams)) {
    streams[courseId] = {}
    CourseActivitySummaryStore._fetchForCourse(courseId)
  }
  return streams[courseId]
}

CourseActivitySummaryStore._fetchForCourse = function(courseId) {
  const fetch = window.fetchIgnoredByNewRelic || window.fetch // don't let this count against us in newRelic's SPA load time stats
  return fetch(`/api/v1/courses/${courseId}/activity_stream/summary`, {
    headers: {Accept: 'application/json'}
  })
    .then(checkStatus)
    .then(res => res.json())
    .then(stream => {
      const state = CourseActivitySummaryStore.getState()
      state.streams[courseId] = {stream}
      CourseActivitySummaryStore.setState(state)
    })
}

export default CourseActivitySummaryStore
