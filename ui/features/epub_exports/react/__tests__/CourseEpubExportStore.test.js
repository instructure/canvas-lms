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

import CourseStore from '../CourseStore'
import $ from 'jquery'

describe('CourseEpubExportStore', () => {
  let courses

  beforeEach(() => {
    CourseStore.clearState()
    courses = {
      courses: [
        {
          name: 'Maths 101',
          id: 1,
          epub_export: {id: 1},
        },
        {
          name: 'Physics 101',
          id: 2,
        },
      ],
    }

    jest.spyOn($, 'getJSON').mockImplementation((url, callback) => {
      callback(url.includes('courses/1/epub_exports/1') ? courses.courses[0] : courses)
      return {fail: () => {}}
    })

    jest.spyOn($, 'post').mockImplementation((url, data, callback) => {
      const course_id = url.match(/courses\/(\d+)/)[1]
      const response = {
        name: 'Creative Writing',
        id: parseInt(course_id, 10),
        epub_export: {
          permissions: {},
          workflow_state: 'created',
        },
      }
      callback(response)
      return {fail: () => {}}
    })
  })

  afterEach(() => {
    CourseStore.clearState()
    jest.restoreAllMocks()
  })

  it('gets all courses', () => {
    expect(CourseStore.getState()).toEqual({})
    CourseStore.getAll()
    const state = CourseStore.getState()
    courses.courses.forEach(course => {
      expect(state[course.id]).toEqual(course)
    })
    expect($.getJSON).toHaveBeenCalledWith('/api/v1/epub_exports', expect.any(Function))
  })

  it('gets a specific course', () => {
    expect(CourseStore.getState()).toEqual({})
    CourseStore.get(1, 1)
    const state = CourseStore.getState()
    expect(state[courses.courses[0].id]).toEqual(courses.courses[0])
    expect($.getJSON).toHaveBeenCalledWith('/api/v1/courses/1/epub_exports/1', expect.any(Function))
  })

  it('creates a new epub export', () => {
    const course_id = 3
    expect(CourseStore.getState()[course_id]).toBeUndefined()
    CourseStore.create(course_id)
    const state = CourseStore.getState()
    expect(state[course_id]).toEqual({
      name: 'Creative Writing',
      id: course_id,
      epub_export: {
        permissions: {},
        workflow_state: 'created',
      },
    })
    expect($.post).toHaveBeenCalledWith(
      `/api/v1/courses/${course_id}/epub_exports`,
      {},
      expect.any(Function),
      'json',
    )
  })
})
