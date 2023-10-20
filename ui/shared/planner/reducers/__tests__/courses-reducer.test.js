/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import reducer from '../courses-reducer'
import {gotGradesSuccess, clearCourses} from '../../actions'

it('merges grades into courses', () => {
  const courses = [
    {id: '1', otherData: 'first-other-fields'},
    {id: '2', otherData: 'second-other-fields'},
  ]
  const grades = {
    1: {courseId: '1', hasGradingPeriods: true, grade: '34.42%'},
    2: {courseId: '2', hasGradingPeriods: false, grade: '42.34%'},
  }
  const action = gotGradesSuccess(grades)
  const nextState = reducer(courses, action)
  expect(nextState).toMatchSnapshot()
})

describe('CLEAR_COURSES', () => {
  it('clears courses', () => {
    const courses = [
      {id: '1', otherData: 'first-other-fields'},
      {id: '2', otherData: 'second-other-fields'},
    ]

    const action = clearCourses()
    const nextState = reducer(courses, action)
    expect(nextState).toEqual([])
  })

  it('does not clear courses in singleCourse mode', () => {
    const courses = [{id: '1', otherData: 'just-one-course'}]

    const action = clearCourses(true)
    const nextState = reducer(courses, action)
    expect(nextState).toBe(courses)
  })
})
