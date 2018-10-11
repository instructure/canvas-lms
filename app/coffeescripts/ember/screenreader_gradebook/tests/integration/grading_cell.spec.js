#
# Copyright (C) 2014 - present Instructure, Inc.
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
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  App = null

  QUnit.module 'grading_cell_component integration test for isPoints',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        @assignment = @controller.get('assignments').findBy('id', '6')
        @student = @controller.get('students').findBy('id', '1')
        Ember.run =>
          @controller.setProperties
            submissions: Ember.copy(fixtures.submissions, true)
            selectedAssignment: @assignment
            selectedStudent: @student

    teardown: ->
      Ember.run App, 'destroy'

  test 'fast-select instance is used for grade input', ->
    ok find('#student_and_assignment_grade').is('select')
    equal find('#student_and_assignment_grade').val(), 'incomplete'
