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

import Backbone from 'Backbone'
import CourseFindSelectView from 'compiled/views/content_migrations/subviews/CourseFindSelectView'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'

QUnit.module('CourseFindSelectView: #setSourceCourseId', {
  setup() {
    fakeENV.setup()
    this.url = '/users/101/manageable_courses'
    this.server = sinon.fakeServer.create()
    this.courses = [
      {
        id: 5,
        term: 'Default Term',
        label: 'A',
        enrollment_start: null
      },
      {
        id: 4,
        term: 'Spring 2016',
        label: 'B',
        enrollment_start: '2016-01-01T07:00:00Z'
      },
      {
        id: 3,
        term: 'Spring 2016',
        label: 'A',
        enrollment_start: '2016-01-01T07:00:00Z'
      },
      {
        id: 2,
        term: 'Fall 2016',
        label: 'B',
        enrollment_start: '2016-10-01T09:00:00Z'
      },
      {
        id: 1,
        term: 'Fall 2016',
        label: 'A',
        enrollment_start: '2016-10-01T09:00:00Z'
      }
    ]
    return this.server.respondWith('GET', this.url, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.courses)
    ])
  },

  teardown() {
    fakeENV.teardown()
    return this.server.restore()
  }
})

test('it should be accessible', assert => {
  const courseFindSelectView = new CourseFindSelectView({model: new Backbone.Model()})
  const done = assert.async()
  assertions.isAccessible(courseFindSelectView, done, {a11yReport: true})
})

test('Triggers "course_changed" when course is found by its id', function() {
  const courseFindSelectView = new CourseFindSelectView({model: new Backbone.Model()})
  const course = {id: 42}
  courseFindSelectView.courses = [course]
  courseFindSelectView.render()

  const sinonSpy = this.spy(courseFindSelectView, 'trigger')
  courseFindSelectView.setSourceCourseId(42)
  ok(sinonSpy.calledWith('course_changed', course), 'Triggered course_changed with a course')
})

test('Sorts courses by most recent term to least, then alphabetically', function() {
  const courseFindSelectView = new CourseFindSelectView({
    model: new Backbone.Model(),
    current_user_id: 101,
    show_select: true
  })

  courseFindSelectView.courses = this.courses
  courseFindSelectView.render()
  this.server.respond()

  // Gets the array of arrays (terms) of course objects
  const sortedCourses = courseFindSelectView.toJSON().terms

  // Gets the courses in grouped arrays
  // with each group corresponding to the term,
  // then flattens by ID in the order they
  // should be in
  const groupedIds = sortedCourses.map(item => item.courses.map(course => course.id))
  const result = [].concat.apply([], groupedIds)

  // Array of ordered IDs from @courses
  const expected = [1, 2, 3, 4, 5]
  deepEqual(result, expected)
})
