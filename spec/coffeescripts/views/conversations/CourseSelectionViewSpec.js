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

import Course from '@canvas/courses/backbone/models/Course'
import CourseSelectionView from 'ui/features/conversations/backbone/views/CourseSelectionView'
import CourseCollection from 'ui/features/conversations/backbone/collections/CourseCollection'
import FavoriteCourseCollection from 'ui/features/conversations/backbone/collections/FavoriteCourseCollection'
import GroupCollection from '@canvas/groups/backbone/collections/GroupCollection'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'

const courseSelectionView = function () {
  const courses = {
    favorites: new FavoriteCourseCollection(),
    all: new CourseCollection(),
    groups: new GroupCollection(),
  }
  return new CourseSelectionView({courses})
}

QUnit.module('CourseSelectionView', {
  setup() {
    this.now = $.fudgeDateForProfileTimezone(new Date())
    fakeENV.setup({CONVERSATIONS: {CAN_MESSAGE_ACCOUNT_CONTEXT: false}})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('it should be accessible', assert => {
  const course = new Course()
  const done = assert.async()
  assertions.isAccessible(courseSelectionView(), done, {a11yReport: true})
})

test('does not label an un-favorited course as concluded', function () {
  const course = new Course()
  const view = courseSelectionView()
  ok(!view.is_complete(course, this.now))
})

test('labels a concluded course as concluded', function () {
  const course = new Course({workflow_state: 'completed'})
  const view = courseSelectionView()
  ok(view.is_complete(course, this.now))
})

test('does not label a course with a term with no end_at as concluded', function () {
  const course = new Course({term: 'foo'})
  const view = courseSelectionView()
  ok(!view.is_complete(course, this.now))
})

test('labels as completed a course with a term with an end_at date in the past', function () {
  const course = new Course({
    term: {
      end_at: Date.today().last().monday().toISOString(),
    },
  })
  const view = courseSelectionView()
  ok(view.is_complete(course, this.now))
})

test('does not label as completed a course with a term overriding end_at in the future', function () {
  const course = new Course({
    end_at: Date.today().next().monday().toISOString(),
    restrict_enrollments_to_course_dates: true,
    term: {
      end_at: Date.today().last().monday().toISOString(),
    },
  })
  const view = courseSelectionView()
  ok(!view.is_complete(course, this.now))
})

test('does not label as completed a course with a term with an end_at date in the future', function () {
  const course = new Course({
    term: {
      end_at: Date.today().next().monday().toISOString(),
    },
  })
  const view = courseSelectionView()
  ok(!view.is_complete(course, this.now))
})

test('does not label as completed a course with a term with an end_at that is null', function () {
  const course = new Course({term: {end_at: null}})
  const view = courseSelectionView()
  ok(!view.is_complete(course, this.now))
})
