#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'jquery'
  'Backbone'
  'compiled/views/accounts/admin_tools/CourseSearchResultsView'
  'compiled/models/CourseRestore'
  'helpers/assertions'
], ($, Backbone, CourseSearchResultsView, CourseRestore, assertions) ->
  errorMessageJSON =
    status: "not_found"
    message: "There was no foo bar in the baz"

  courseJSON =
    account_id: 6
    course_code: "Super"
    default_view: "feed"
    end_at: null
    enrollments: []
    hide_final_grades: false
    id: 58
    name: "Super Fun Deleted Course"
    sis_course_id: null
    start_at: null
    workflow_state: "deleted"

  QUnit.module "CourseSearchResultsView",
    setup: ->
      @courseRestore = new CourseRestore account_id: 6
      @courseSearchResultsView = new CourseSearchResultsView model: @courseRestore
      $('#fixtures').append $('<div id="flash_screenreader_holder" />')
      $('#fixtures').append @courseSearchResultsView.render().el
    teardown: ->
      $('#fixtures').empty()

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @courseSearchResultsView, done, {'a11yReport': true}

  test "restored is set to false when initialized", ->
    ok !@courseRestore.get('restored')

  test "render is called whenever the model has a change event triggered", ->
    @mock(@courseSearchResultsView).expects("render").once()

    @courseSearchResultsView.applyBindings()
    @courseRestore.trigger 'change'

  test "pressing the restore button calls restore on the model and view", ->
    @courseRestore.set courseJSON

    @mock(@courseRestore).expects("restore").once().
      returns($.Deferred().resolve())

    @courseSearchResultsView.$restoreCourseBtn.click()

  test "not found message is displayed when model has no id and a status", ->
    @courseRestore.clear silent: yes
    @courseRestore.set errorMessageJSON
    ok @courseSearchResultsView.$el.find('.alert-error').length > 0, "Error message is displayed"

  test "options to restore a course and its details should be displayed when a deleted course is found", ->
    @courseRestore.set courseJSON

    ok @courseSearchResultsView.$el.find('#restoreCourseBtn').length > 0, "Restore course button displayed"

  test "show screenreader text when course not found", ->
    $.initFlashContainer()
    @courseRestore.clear silent: yes
    @courseRestore.set errorMessageJSON
    @courseSearchResultsView.resultsFound()
    ok $('#flash_screenreader_holder').text().match('Course not found')

  test "show screenreader text on finding deleted course", ->
    $.initFlashContainer()
    @courseRestore.set courseJSON
    @courseSearchResultsView.resultsFound()
    ok $('#flash_screenreader_holder').text().match('Course found')

  test "show screenreader text on finding non-deleted course", ->
    $.initFlashContainer()
    @courseRestore.set Object.assign {}, courseJSON, {workflow_state: 'active'}
    @courseSearchResultsView.resultsFound()
    ok $('#flash_screenreader_holder').text().match(/Course found \(not deleted\)/)

  test "shows options to view a course or add enrollments if a course was restored", ->
    @courseRestore.set courseJSON, silent: yes
    @courseRestore.set 'restored', true, silent: yes
    @courseRestore.set 'workflow_state', 'active'

    ok @courseSearchResultsView.$el.find('.alert-success').length > 0, "Course restore displayed"
    ok @courseSearchResultsView.$el.find('#viewCourse').length > 0, "Viewing a course displayed"
    ok @courseSearchResultsView.$el.find('#addEnrollments').length > 0, "Adding enrollments displayed"

  test "shows options to view a course or add enrollments if non deleted course was found", ->
    @courseRestore.set courseJSON, silent: yes
    @courseRestore.set 'workflow_state', 'active'

    ok @courseSearchResultsView.$el.find('#viewCourse').length > 0, "Viewing a course displayed"
    ok @courseSearchResultsView.$el.find('#addEnrollments').length > 0, "Adding enrollments displayed"
