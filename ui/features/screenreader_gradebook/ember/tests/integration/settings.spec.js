//
// Copyright (C) 2013 - present Instructure, Inc.
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
import fixtures from '../ajax_fixtures'
import $ from 'jquery'
import 'jquery-tinypubsub'

let App = null

QUnit.module('global settings', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(() => {
      this.controller = App.__container__.lookup('controller:screenreader_gradebook')
      return this.controller.set('hideStudentNames', false)
    })
  },
  teardown() {
    return Ember.run(App, 'destroy')
  },
})

test('student names are hidden', () => {
  const selection = '#student_select option[value=1]'
  equal($(selection).text(), 'Barnes, Bob')
  return click('#hide_names_checkbox').then(() => {
    return click('#hide_names_checkbox').then(() => {
      equal($(selection).text(), 'Barnes, Bob')
    })
  })
})

// unskip in EVAL-2505
QUnit.skip('secondary id says hidden', function () {
  Ember.run(() => {
    const student = this.controller.get('students.firstObject')
    Ember.setProperties(student, {
      isLoaded: true,
      isLoading: false,
    })
    return this.controller.set('selectedStudent', student)
  })

  equal(Ember.$.trim(find('.secondary_id').text()), '')
  click('#hide_names_checkbox')
  return andThen(() => {
    equal($.trim(find('.secondary_id:first').text()), 'hidden')
  })
})

// unskip in EVAL-2505
QUnit.skip('view concluded enrollments', function () {
  let enrollments = this.controller.get('enrollments')
  ok(enrollments.content.length > 1)
  enrollments.content.forEach(enrollment => ok(enrollment.workflow_state === undefined))

  return click('#concluded_enrollments').then(() => {
    enrollments = this.controller.get('enrollments')
    equal(enrollments.content.length, 1)
    const en = enrollments.objectAt(0)
    ok(en.workflow_state === 'completed')
    const completed_at = new Date(en.completed_at)
    ok(completed_at.getTime() < new Date().getTime())

    return click('#concluded_enrollments').then(() => {
      enrollments = this.controller.get('enrollments')
      return ok(enrollments.content.length > 1)
    })
  })
})
