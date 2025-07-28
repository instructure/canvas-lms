/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {handleActions} from 'redux-actions'

const defaultState = []

function mergeGradesIntoCourses(courses, action) {
  const grades = action.payload
  return courses.map(course => {
    const newCourse = {...course, ...grades[course.id]}
    delete newCourse.courseId // remove confusing duplicate field
    return newCourse
  })
}

export default handleActions(
  {
    INITIAL_OPTIONS: (state, action) => {
      if (action.payload.singleCourse) {
        return [action.payload.env.COURSE]
      }
      return []
    },
    GOT_COURSE_LIST: (state, action) => {
      // Ensure we always return an array
      return Array.isArray(action.payload) ? action.payload : []
    },
    GOT_GRADES_SUCCESS: mergeGradesIntoCourses,
    CLEAR_COURSES: (state, action) => {
      if (action.payload) return state
      return defaultState
    },
  },
  defaultState,
)
