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
import CourseStore from 'jsx/epub_exports/CourseStore'

QUnit.module('CourseEpubExportStoreSpec', {
  setup() {
    CourseStore.clearState()
    this.courses = {
      courses: [
        {
          name: 'Maths 101',
          id: 1,
          epub_export: {id: 1}
        },
        {
          name: 'Physics 101',
          id: 2
        }
      ]
    }
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    CourseStore.clearState()
    return this.server.restore()
  }
})

test('getAll', function() {
  this.server.respondWith('GET', '/api/v1/epub_exports', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.courses)
  ])
  ok(isEmpty(CourseStore.getState()), 'precondition')
  CourseStore.getAll()
  this.server.respond()
  const state = CourseStore.getState()
  return this.courses.courses.forEach(course => deepEqual(state[course.id], course))
})

test('get', function() {
  const url = '/api/v1/courses/1/epub_exports/1'
  const course = this.courses.courses[0]
  this.server.respondWith('GET', url, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(course)
  ])
  ok(isEmpty(CourseStore.getState()), 'precondition')
  CourseStore.get(1, 1)
  this.server.respond()
  const state = CourseStore.getState()
  deepEqual(state[course.id], course)
})

test('create', function() {
  const course_id = 3
  const epub_export = {
    name: 'Creative Writing',
    id: course_id,
    epub_export: {
      permissions: {},
      workflow_state: 'created'
    }
  }
  this.server.respondWith('POST', `/api/v1/courses/${course_id}/epub_exports`, [
    200,
    {'Content-Type': 'application/josn'},
    JSON.stringify(epub_export)
  ])
  ok(isUndefined(CourseStore.getState()[course_id]), 'precondition')
  CourseStore.create(course_id)
  this.server.respond()
  const state = CourseStore.getState()
  deepEqual(state[course_id], epub_export, 'should add new object to state')
})
