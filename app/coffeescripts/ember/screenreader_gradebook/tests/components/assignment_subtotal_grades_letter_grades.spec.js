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
    possible: 100,
    score: 54.5,
    submission_count: 1,
    submissions: [],
    weight: 100
  }
}

QUnit.module('assignment_subtotal_grades_component_letter_grade', {
  setup() {
    fixtures.create()
    const App = startApp()
    this.component = App.AssignmentSubtotalGradesComponent.create()
    this.component.reopen({
      gradingStandard: function() {
        originalGradingStandard = this._super
        return [['A', 0.8], ['B+', 55.5], ['B', 54.5], ['C', 0.05], ['F', 0.0]]
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
          key: `assignment_group_${this.assignment_group.id}`,
          weight: this.assignment_group.group_weight
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

test('letterGrade', function() {
  const expected = 'C'
  equal(this.component.get('letterGrade'), expected)
})
