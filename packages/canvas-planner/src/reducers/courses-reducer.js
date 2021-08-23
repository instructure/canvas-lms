/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import {handleActions} from 'redux-actions'

function mergeGradesIntoCourses(courses, action) {
  const grades = action.payload
  return courses.map(course => {
    const newCourse = {...course, ...grades[course.id]}
    delete newCourse.courseId // remove confusing duplicate field
    return newCourse
  })
}

const getPlannerCourses = ({
  payload: {
    env: {COURSE, STUDENT_PLANNER_COURSES}
  }
}) => {
  if (!STUDENT_PLANNER_COURSES.length && COURSE) {
    return [COURSE]
  }
  return STUDENT_PLANNER_COURSES
}

export default handleActions(
  {
    INITIAL_OPTIONS: (state, action) => getPlannerCourses(action),
    GOT_GRADES_SUCCESS: mergeGradesIntoCourses
  },
  []
)
