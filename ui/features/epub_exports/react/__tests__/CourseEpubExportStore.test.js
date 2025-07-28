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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

describe('CourseEpubExportStore', () => {
  let courses

  beforeAll(() => {
    server.listen()
  })

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

    server.use(
      http.get('/api/v1/epub_exports', () => {
        return HttpResponse.json(courses)
      }),
      http.get('/api/v1/courses/:courseId/epub_exports/:exportId', ({params}) => {
        if (params.courseId === '1' && params.exportId === '1') {
          return HttpResponse.json(courses.courses[0])
        }
        return new HttpResponse(null, {status: 404})
      }),
      http.post('/api/v1/courses/:courseId/epub_exports', ({params}) => {
        const course_id = parseInt(params.courseId, 10)
        const response = {
          name: 'Creative Writing',
          id: course_id,
          epub_export: {
            permissions: {},
            workflow_state: 'created',
          },
        }
        return HttpResponse.json(response)
      }),
    )
  })

  afterEach(() => {
    CourseStore.clearState()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('gets all courses', async () => {
    expect(CourseStore.getState()).toEqual({})
    CourseStore.getAll()

    // Wait for the async request to complete
    await new Promise(resolve => setTimeout(resolve, 10))

    const state = CourseStore.getState()
    courses.courses.forEach(course => {
      expect(state[course.id]).toEqual(course)
    })
  })

  it('gets a specific course', async () => {
    expect(CourseStore.getState()).toEqual({})
    CourseStore.get(1, 1)

    // Wait for the async request to complete
    await new Promise(resolve => setTimeout(resolve, 10))

    const state = CourseStore.getState()
    expect(state[courses.courses[0].id]).toEqual(courses.courses[0])
  })

  it('creates a new epub export', async () => {
    const course_id = 3
    expect(CourseStore.getState()[course_id]).toBeUndefined()
    CourseStore.create(course_id)

    // Wait for the async request to complete
    await new Promise(resolve => setTimeout(resolve, 10))

    const state = CourseStore.getState()
    expect(state[course_id]).toEqual({
      name: 'Creative Writing',
      id: course_id,
      epub_export: {
        permissions: {},
        workflow_state: 'created',
      },
    })
  })
})
