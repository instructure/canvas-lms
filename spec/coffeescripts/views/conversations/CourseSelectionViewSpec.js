#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'compiled/models/Course'
  'compiled/views/conversations/CourseSelectionView'
  'compiled/collections/CourseCollection'
  'compiled/collections/FavoriteCourseCollection'
  'compiled/collections/GroupCollection'
  'helpers/fakeENV'
  'helpers/assertions'
], (Course, CourseSelectionView, CourseCollection, FavoriteCourseCollection, GroupCollection, fakeENV, assertions) ->
  courseSelectionView = () ->
    courses =
      favorites: new FavoriteCourseCollection()
      all: new CourseCollection()
      groups: new GroupCollection()

    app = new CourseSelectionView
      courses: courses

  QUnit.module 'CourseSelectionView',
    setup: ->
      @now = $.fudgeDateForProfileTimezone(new Date)
      fakeENV.setup(CONVERSATIONS: {CAN_MESSAGE_ACCOUNT_CONTEXT: false})
    teardown: ->
      fakeENV.teardown()

  test 'it should be accessible', (assert) ->
    course = new Course
    done = assert.async()
    assertions.isAccessible courseSelectionView(), done, {'a11yReport': true}

  test 'does not label an un-favorited course as concluded', ->
    course = new Course
    view = courseSelectionView()
    ok !view.is_complete(course, @now)

  test 'labels a concluded course as concluded', ->
    course = new Course
      workflow_state: 'completed'
    view = courseSelectionView()
    ok view.is_complete(course, @now)

  test 'does not label a course with a term with no end_at as concluded', ->
    course = new Course
      term: "foo"
    view = courseSelectionView()
    ok !view.is_complete(course, @now)

  test 'labels as completed a course with a term with an end_at date in the past', ->
    course = new Course
      term:
        end_at: Date.today().last().monday().toISOString()
    view = courseSelectionView()
    ok view.is_complete(course, @now)

  test 'does not label as completed a course with a term overriding end_at in the future', ->
    course = new Course
      end_at: Date.today().next().monday().toISOString()
      restrict_enrollments_to_course_dates: true
      term:
        end_at: Date.today().last().monday().toISOString()
    view = courseSelectionView()
    ok !view.is_complete(course, @now)

  test 'does not label as completed a course with a term with an end_at date in the future', ->
    course = new Course
      term:
        end_at: Date.today().next().monday().toISOString()
    view = courseSelectionView()
    ok !view.is_complete(course, @now)

  test 'does not label as completed a course with a term with an end_at that is null', ->
    course = new Course
      term: {end_at: null}
    view = courseSelectionView()
    ok !view.is_complete(course, @now)
