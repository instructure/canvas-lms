/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import CourseFindSelectView from '../CourseFindSelectView'
import fakeENV from '@canvas/test-utils/fakeENV'
import sinon from 'sinon'
import {isAccessible} from '@canvas/test-utils/assertions'

describe('CourseFindSelectView: #setSourceCourseId', () => {
  let server
  let courses
  const urlPattern = /\/users\/101\/manageable_courses/

  beforeEach(() => {
    fakeENV.setup()
    server = sinon.fakeServer.create()
    courses = [
      {
        id: 5,
        term: 'Default Term',
        label: 'A',
        enrollment_start: null,
      },
      {
        id: 4,
        term: 'Spring 2016',
        label: 'B',
        enrollment_start: '2016-01-01T07:00:00Z',
      },
      {
        id: 3,
        term: 'Spring 2016',
        label: 'A',
        enrollment_start: '2016-01-01T07:00:00Z',
      },
      {
        id: 2,
        term: 'Fall 2016',
        label: 'B',
        enrollment_start: '2016-10-01T09:00:00Z',
      },
      {
        id: 1,
        term: 'Fall 2016',
        label: 'A',
        enrollment_start: '2016-10-01T09:00:00Z',
      },
    ]
    server.respondWith('GET', urlPattern, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(courses),
    ])
  })

  afterEach(() => {
    fakeENV.teardown()
    server.restore()
  })

  test('Triggers "course_changed" when course is found by its id', () => {
    const courseFindSelectView = new CourseFindSelectView({model: new Backbone.Model()})
    const course = {id: 42}
    courseFindSelectView.courses = [course]
    courseFindSelectView.render()

    const sinonSpy = sinon.spy(courseFindSelectView, 'trigger')
    courseFindSelectView.setSourceCourseId(42)
    expect(sinonSpy.calledWith('course_changed', course)).toBe(true)
  })

  test('Sorts courses by most recent term to least, then alphabetically', () => {
    const courseFindSelectView = new CourseFindSelectView({
      model: new Backbone.Model(),
      current_user_id: 101,
      show_select: true,
    })

    courseFindSelectView.courses = courses
    courseFindSelectView.render()
    server.respond()

    const sortedCourses = courseFindSelectView.toJSON().terms
    const groupedIds = sortedCourses.map(item => item.courses.map(course => course.id))
    const result = [].concat(...groupedIds)

    const expected = [1, 2, 3, 4, 5]
    expect(result).toEqual(expected)
  })
})
