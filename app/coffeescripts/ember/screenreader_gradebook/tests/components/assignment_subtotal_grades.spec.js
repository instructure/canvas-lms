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

import Ember from 'ember'
import startApp from '../start_app'
import AGGrades from '../../components/assignment_subtotal_grades_component'
import fixtures from '../shared_ajax_fixtures'

const {run} = Ember

let originalWeightingScheme = null
let originalGradingStandard = null
const groupScores = {
  assignment_group_1: {
    possible: 1000,
    score: 946.65,
    submission_count: 10,
    submissions: [],
    weight: 90
  }
}
const periodScores = {
  grading_period_1: {
    possible: 1800.111,
    score: 95.1225,
    submission_count: 30,
    submissions: [],
    weight: 60
  }
}

QUnit.module('assignment_subtotal_grades_component by group', {
  setup() {
    fixtures.create()
    const App = startApp()
    this.component = App.AssignmentSubtotalGradesComponent.create()
    this.component.reopen({
      gradingStandard: function() {
        originalGradingStandard = this._super
        return [['A', 0.5], ['C', 0.05], ['F', 0.0]]
      }.property(),
      weightingScheme: function() {
        originalWeightingScheme = this._super
        return 'percent'
      }.property()
    })
    return run(() => {
      this.assignment_group = Ember.copy(fixtures.assignment_groups, true).findBy('id', '1')
      this.student = Ember.Object.create(Ember.copy(groupScores))
      return this.component.setProperties({
        student: this.student,
        subtotal: {
          name: this.assignment_group.name,
          weight: this.assignment_group.group_weight,
          key: `assignment_group_${this.assignment_group.id}`
        }
      })
    })
  },

  teardown() {
    return run(() => {
      this.component.destroy()
      return App.destroy()
    })
  }
})

test('values', function() {
  deepEqual(this.component.get('values'), groupScores.assignment_group_1)
})

test('points', function() {
  const expected = '946.65 / 1,000'
  equal(this.component.get('points'), expected)
})

test('percent', function() {
  const expected = '94.67%'
  strictEqual((946.65 / 1000) * 100, 94.66499999999999)
  strictEqual(this.component.get('percent'), expected)
})

test('letterGrade', function() {
  const expected = 'A'
  equal(this.component.get('letterGrade'), expected)
})

test('scoreDetail', function() {
  const expected = '(946.65 / 1,000)'
  equal(this.component.get('scoreDetail'), expected)
})

QUnit.module('assignment_subtotal_grades_component by period', {
  setup() {
    fixtures.create()
    const App = startApp()
    this.component = App.AssignmentSubtotalGradesComponent.create()
    this.component.reopen({
      gradingStandard: function() {
        originalGradingStandard = this._super
        return [['A', 0.5], ['C', 0.05], ['F', 0.0]]
      }.property()
    })
    return run(() => {
      this.student = Ember.Object.create(Ember.copy(periodScores))
      return this.component.setProperties({
        student: this.student,
        subtotal: {
          name: 'Grading Period 1',
          weight: 0.65,
          key: 'grading_period_1'
        }
      })
    })
  },

  teardown() {
    return run(() => {
      this.component.destroy()
      return App.destroy()
    })
  }
})

test('values', function() {
  deepEqual(this.component.get('values'), periodScores.grading_period_1)
})

test('points', function() {
  const expected = '95.12 / 1,800.11'
  equal(this.component.get('points'), expected)
})

test('percent', function() {
  const expected = '5.28%'
  equal(this.component.get('percent'), expected)
})

test('letterGrade', function() {
  const expected = 'C'
  equal(this.component.get('letterGrade'), expected)
})

test('scoreDetail', function() {
  const expected = '(95.12 / 1,800.11)'
  equal(this.component.get('scoreDetail'), expected)
})
