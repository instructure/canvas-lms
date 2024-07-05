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

import {isEmpty, isUndefined} from 'lodash'
import CourseStore from '../CourseStore'
import sinon from 'sinon'

const ok = x => expect(x).toBeTruthy()
const deepEqual = (x, y) => expect(x).toEqual(y)

let courses
let server

describe('CourseEpubExportStoreSpec', () => {
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
    server = sinon.fakeServer.create()
  })

  afterEach(() => {
    CourseStore.clearState()
    server.restore()
  })

  test('getAll', function () {
    server.respondWith('GET', '/api/v1/epub_exports', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(courses),
    ])
    ok(isEmpty(CourseStore.getState()), 'precondition')
    CourseStore.getAll()
    server.respond()
    const state = CourseStore.getState()
    return courses.courses.forEach(course => deepEqual(state[course.id], course))
  })

  test('get', function () {
    const url = '/api/v1/courses/1/epub_exports/1'
    const course = courses.courses[0]
    server.respondWith('GET', url, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(course),
    ])
    ok(isEmpty(CourseStore.getState()), 'precondition')
    CourseStore.get(1, 1)
    server.respond()
    const state = CourseStore.getState()
    deepEqual(state[course.id], course)
  })

  test('create', function () {
    const course_id = 3
    const epub_export = {
      name: 'Creative Writing',
      id: course_id,
      epub_export: {
        permissions: {},
        workflow_state: 'created',
      },
    }
    server.respondWith('POST', `/api/v1/courses/${course_id}/epub_exports`, [
      200,
      {'Content-Type': 'application/josn'},
      JSON.stringify(epub_export),
    ])
    ok(isUndefined(CourseStore.getState()[course_id]), 'precondition')
    CourseStore.create(course_id)
    server.respond()
    const state = CourseStore.getState()
    deepEqual(state[course_id], epub_export, 'should add new object to state')
  })
})
