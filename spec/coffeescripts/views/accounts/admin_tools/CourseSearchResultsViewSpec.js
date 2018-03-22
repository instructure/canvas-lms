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

import $ from 'jquery'
import Backbone from 'Backbone'
import CourseSearchResultsView from 'compiled/views/accounts/admin_tools/CourseSearchResultsView'
import CourseRestore from 'compiled/models/CourseRestore'
import assertions from 'helpers/assertions'

const errorMessageJSON = {
  status: 'not_found',
  message: 'There was no foo bar in the baz'
}
const courseJSON = {
  account_id: 6,
  course_code: 'Super',
  default_view: 'feed',
  end_at: null,
  enrollments: [],
  hide_final_grades: false,
  id: 58,
  name: 'Super Fun Deleted Course',
  sis_course_id: null,
  start_at: null,
  workflow_state: 'deleted'
}

QUnit.module('CourseSearchResultsView', {
  setup() {
    this.courseRestore = new CourseRestore({account_id: 6})
    this.courseSearchResultsView = new CourseSearchResultsView({model: this.courseRestore})
    $('#fixtures').append($('<div id="flash_screenreader_holder" />'))
    return $('#fixtures').append(this.courseSearchResultsView.render().el)
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.courseSearchResultsView, done, {a11yReport: true})
})

test('restored is set to false when initialized', function() {
  ok(!this.courseRestore.get('restored'))
})

test('render is called whenever the model has a change event triggered', function() {
  this.mock(this.courseSearchResultsView)
    .expects('render')
    .once()
  this.courseSearchResultsView.applyBindings()
  return this.courseRestore.trigger('change')
})

test('pressing the restore button calls restore on the model and view', function() {
  this.courseRestore.set(courseJSON)
  this.mock(this.courseRestore)
    .expects('restore')
    .once()
    .returns($.Deferred().resolve())
  return this.courseSearchResultsView.$restoreCourseBtn.click()
})

test('not found message is displayed when model has no id and a status', function() {
  this.courseRestore.clear({silent: true})
  this.courseRestore.set(errorMessageJSON)
  ok(this.courseSearchResultsView.$el.find('.alert-error').length > 0, 'Error message is displayed')
})

test('options to restore a course and its details should be displayed when a deleted course is found', function() {
  this.courseRestore.set(courseJSON)
  ok(
    this.courseSearchResultsView.$el.find('#restoreCourseBtn').length > 0,
    'Restore course button displayed'
  )
})

test('show screenreader text when course not found', function() {
  $.initFlashContainer()
  this.courseRestore.clear({silent: true})
  this.courseRestore.set(errorMessageJSON)
  this.courseSearchResultsView.resultsFound()
  ok(
    $('#flash_screenreader_holder')
      .text()
      .match('Course not found')
  )
})

test('show screenreader text on finding deleted course', function() {
  $.initFlashContainer()
  this.courseRestore.set(courseJSON)
  this.courseSearchResultsView.resultsFound()
  ok(
    $('#flash_screenreader_holder')
      .text()
      .match('Course found')
  )
})

test('show screenreader text on finding non-deleted course', function() {
  $.initFlashContainer()
  this.courseRestore.set({
    ...courseJSON,
    workflow_state: 'active'
  })
  this.courseSearchResultsView.resultsFound()
  ok(
    $('#flash_screenreader_holder')
      .text()
      .match(/Course found \(not deleted\)/)
  )
})

test('shows options to view a course or add enrollments if a course was restored', function() {
  this.courseRestore.set(courseJSON, {silent: true})
  this.courseRestore.set('restored', true, {silent: true})
  this.courseRestore.set('workflow_state', 'active')
  ok(this.courseSearchResultsView.$el.find('.alert-success').length > 0, 'Course restore displayed')
  ok(this.courseSearchResultsView.$el.find('#viewCourse').length > 0, 'Viewing a course displayed')
  ok(
    this.courseSearchResultsView.$el.find('#addEnrollments').length > 0,
    'Adding enrollments displayed'
  )
})

test('shows options to view a course or add enrollments if non deleted course was found', function() {
  this.courseRestore.set(courseJSON, {silent: true})
  this.courseRestore.set('workflow_state', 'active')
  ok(this.courseSearchResultsView.$el.find('#viewCourse').length > 0, 'Viewing a course displayed')
  ok(
    this.courseSearchResultsView.$el.find('#addEnrollments').length > 0,
    'Adding enrollments displayed'
  )
})
