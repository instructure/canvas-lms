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

import $ from 'jquery'
import Ember from 'ember'
import * as tz from '@canvas/datetime'
import startApp from '../start_app'
import fixtures from '../ajax_fixtures'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const {run} = Ember

let setType = null

QUnit.module('grading_cell', {
  setup() {
    window.ENV = {}
    fixtures.create()
    const App = startApp()
    this.component = App.GradingCellComponent.create()

    ENV.GRADEBOOK_OPTIONS.grading_period_set = {
      id: '1',
      weighted: false,
      display_totals_for_all_grading_periods: false,
    }
    ENV.current_user_roles = []

    setType = type => run(() => this.assignment.set('grading_type', type))
    this.component.reopen({
      changeGradeURL() {
        return '/api/v1/assignment/:assignment/:submission'
      },
    })
    return run(() => {
      this.submission = Ember.Object.create({
        grade: 'B',
        entered_grade: 'A',
        score: 8,
        entered_score: 10,
        points_deducted: 2,
        gradeLocked: false,
        assignment_id: 1,
        user_id: 1,
      })
      this.assignment = Ember.Object.create({
        due_at: tz.parse('2013-10-01T10:00:00Z'),
        grading_type: 'points',
        points_possible: 10,
      })
      this.component.setProperties({
        submission: this.submission,
        assignment: this.assignment,
      })
      return this.component.append()
    })
  },

  teardown() {
    return run(() => {
      this.component.destroy()
      App.destroy()
      return (window.ENV = {})
    })
  },
})

test('setting value on init', function () {
  const component = App.GradingCellComponent.create()
  equal(component.get('value'), '-')
  equal(this.component.get('value'), 'A')
})

test('entered_score', function () {
  equal(this.component.get('entered_score'), 10)
})

test('late_penalty', function () {
  equal(this.component.get('late_penalty'), -2)
})

test('points_possible', function () {
  equal(this.component.get('points_possible'), 10)
})

test('final_grade', function () {
  equal(this.component.get('final_grade'), 'B')
})

test('saveURL', function () {
  equal(this.component.get('saveURL'), '/api/v1/assignment/1/1')
})

test('isPoints', function () {
  setType('points')
  ok(this.component.get('isPoints'))
})

test('isPercent', function () {
  setType('percent')
  ok(this.component.get('isPercent'))
})

test('isLetterGrade', function () {
  setType('letter_grade')
  ok(this.component.get('isLetterGrade'))
})

test('isInPastGradingPeriodAndNotAdmin is true when the submission is gradeLocked', function () {
  run(() => this.submission.set('gradeLocked', true))
  equal(this.component.get('isInPastGradingPeriodAndNotAdmin'), true)
})

test('isInPastGradingPeriodAndNotAdmin is false when the submission is not gradeLocked', function () {
  run(() => this.submission.set('gradeLocked', false))
  equal(this.component.get('isInPastGradingPeriodAndNotAdmin'), false)
})

test('nilPointsPossible', function () {
  run(() => this.assignment.set('points_possible', null))
  ok(this.component.get('nilPointsPossible'))
  run(() => this.assignment.set('points_possible', 10))
  equal(this.component.get('nilPointsPossible'), false)
})

test('isGpaScale', function () {
  setType('gpa_scale')
  ok(this.component.get('isGpaScale'))
})

test('isPassFail', function () {
  setType('pass_fail')
  ok(this.component.get('isPassFail'))
})

test('does not translate pass_fail grades', function () {
  setType('pass_fail')
  sandbox.stub(GradeFormatHelper, 'formatGrade').returns('completo')
  run(() => this.submission.set('entered_grade', 'complete'))
  this.component.submissionDidChange()
  equal(this.component.get('value'), 'complete')
})

test('formats percent grades', function () {
  setType('percent')
  sandbox.stub(GradeFormatHelper, 'formatGrade').returns('32,4%')
  run(() => this.submission.set('entered_grade', '32.4'))
  this.component.submissionDidChange()
  equal(this.component.get('value'), '32,4%')
})

test('focusOut', function (assert) {
  const done = assert.async()
  const stub = sandbox.stub(this.component, 'boundUpdateSuccess')
  const submissions = []

  let requestStub = null
  run(() => {
    requestStub = Ember.RSVP.resolve({all_submissions: submissions})
  })

  sandbox.stub(this.component, 'ajax').returns(requestStub)

  run(() => {
    this.component.set('value', '10')
    return this.component.send('focusOut', {target: {id: 'student_and_assignment_grade'}})
  })

  // eslint-disable-next-line promise/catch-or-return
  Promise.resolve().then(() => {
    ok(stub.called)
    // eslint-disable-next-line promise/no-callback-in-promise
    done()
  })
})

test('onUpdateSuccess', function () {
  run(() => this.assignment.set('points_possible', 100))
  const flashWarningStub = sandbox.stub($, 'flashWarning')
  this.component.onUpdateSuccess({all_submissions: [], score: 150})
  ok(flashWarningStub.called)
})
