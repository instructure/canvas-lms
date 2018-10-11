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
      possible: 1000
      score: 946.65
      submission_count: 10
      submissions: []
      weight: 90
  periodScores =
    grading_period_1:
      possible: 1800.111
      score: 95.1225
      submission_count: 30
      submissions: []
      weight: 60

  QUnit.module 'assignment_subtotal_grades_component by group',
    setup: ->
      fixtures.create()
      App = startApp()
      @component = App.AssignmentSubtotalGradesComponent.create()
      @component.reopen
        gradingStandard: (->
          originalGradingStandard = this._super
          [["A", 0.50],["C", 0.05],["F", 0.00]]
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
            weight: @assignment_group.group_weight
            key: "assignment_group_#{@assignment_group.id}"


    teardown: ->
      run =>
        @component.destroy()
        App.destroy()


  test 'values', ->
    deepEqual @component.get('values'), groupScores.assignment_group_1

  test 'points', ->
    expected = "946.65 / 1,000"
    equal @component.get('points'), expected

  test 'percent', ->
    expected = "94.67%"
    strictEqual(946.65/1000 * 100, 94.66499999999999)
    strictEqual @component.get('percent'), expected

  test 'letterGrade', ->
    expected = "A"
    equal @component.get('letterGrade'), expected

  test 'scoreDetail', ->
    expected = "(946.65 / 1,000)"
    equal @component.get('scoreDetail'), expected

  QUnit.module 'assignment_subtotal_grades_component by period',
    setup: ->
      fixtures.create()
      App = startApp()
      @component = App.AssignmentSubtotalGradesComponent.create()
      @component.reopen
        gradingStandard: (->
          originalGradingStandard = this._super
          [["A", 0.50],["C", 0.05],["F", 0.00]]
        ).property()
      run =>
        @student = Ember.Object.create Ember.copy periodScores
        @component.setProperties
          student: @student
          subtotal:
            name: 'Grading Period 1'
            weight: 0.65
            key: "grading_period_1"

    teardown: ->
      run =>
        @component.destroy()
        App.destroy()


  test 'values', ->
    deepEqual @component.get('values'), periodScores.grading_period_1

  test 'points', ->
    expected = "95.12 / 1,800.11"
    equal @component.get('points'), expected

  test 'percent', ->
    expected = "5.28%"
    equal @component.get('percent'), expected

  test 'letterGrade', ->
    expected = "C"
    equal @component.get('letterGrade'), expected

  test 'scoreDetail', ->
    expected = "(95.12 / 1,800.11)"
    equal @component.get('scoreDetail'), expected
