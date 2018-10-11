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
  'ember'
  '../start_app'
  '../../components/assignment_subtotal_grades_component'
  '../shared_ajax_fixtures'
], (Ember, startApp, AGGrades, fixtures) ->

  {run} = Ember

  originalWeightingScheme = null
  originalGradingStandard = null
  groupScores =
    assignment_group_1:
      possible: 100
      score: 54.5
      submission_count: 1
      submissions: []
      weight: 100

  QUnit.module 'assignment_subtotal_grades_component_letter_grade',
    setup: ->
      fixtures.create()
      App = startApp()
      @component = App.AssignmentSubtotalGradesComponent.create()
      @component.reopen
        gradingStandard: (->
          originalGradingStandard = this._super
          [["A", 0.80],["B+", 55.5],["B", 54.5],["C", 0.05],["F", 0.00]]
        ).property()
        weightingScheme: (->
          originalWeightingScheme = this._super
          "percent"
        ).property()
      run =>
        @assignment_group = Ember.copy(fixtures.assignment_groups, true).findBy('id', '1')
        @student = Ember.Object.create Ember.copy groupScores
        @component.setProperties
          student: @student
          subtotal:
            name: @assignment_group.name
            key: "assignment_group_#{@assignment_group.id}"
            weight: @assignment_group.group_weight

    teardown: ->
      run =>
        @component.destroy()
        App.destroy()

  test 'letterGrade', ->
    expected = "C"
    equal @component.get('letterGrade'), expected
