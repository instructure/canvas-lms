//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import startApp from '../start_app'
import Ember from 'ember'
import fixtures from '../shared_ajax_fixtures'

let App = null

QUnit.module('grading_cell_component integration test for isPoints', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(() => {
      this.controller = App.__container__.lookup('controller:screenreader_gradebook')
      this.assignment = this.controller.get('assignments').findBy('id', '6')
      this.student = this.controller.get('students').findBy('id', '1')
      return Ember.run(() =>
        this.controller.setProperties({
          submissions: Ember.copy(fixtures.submissions, true),
          selectedAssignment: this.assignment,
          selectedStudent: this.student
        })
      )
    })
  },

  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('fast-select instance is used for grade input', () => {
  ok(find('#student_and_assignment_grade').is('select'))
  equal(find('#student_and_assignment_grade').val(), 'incomplete')
})
