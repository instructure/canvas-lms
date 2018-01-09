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
  'jquery'
  'ember'
  'timezone'
  '../start_app'
  '../shared_ajax_fixtures'
  'jsx/gradebook/shared/helpers/GradeFormatHelper'
], ($, Ember, tz, startApp, fixtures, GradeFormatHelper) ->

  {run} = Ember

  setType = null

  QUnit.module 'grading_cell',
    setup: ->
      window.ENV = {}
      fixtures.create()
      App = startApp()
      @component = App.GradingCellComponent.create()

      ENV.GRADEBOOK_OPTIONS.grading_period_set =
        id: '1'
        weighted: false
        display_totals_for_all_grading_periods: false
      ENV.current_user_roles = []

      setType = (type) =>
        run => @assignment.set('grading_type', type)
      @component.reopen
        changeGradeURL: ->
          "/api/v1/assignment/:assignment/:submission"
      run =>
        @submission = Ember.Object.create
          grade: 'B'
          entered_grade: 'A'
          score: 8
          entered_score: 10
          points_deducted: 2
          gradeLocked: false
          assignment_id: 1
          user_id: 1
        @assignment = Ember.Object.create
          due_at: tz.parse("2013-10-01T10:00:00Z")
          grading_type: 'points'
          points_possible: 10
        @component.setProperties
          'submission': @submission
          assignment: @assignment
        @component.append()

    teardown: ->
      run =>
        @component.destroy()
        App.destroy()
        window.ENV = {}

  test "setting value on init", ->
    component = App.GradingCellComponent.create()
    equal(component.get('value'), '-')
    equal(@component.get('value'), 'A')

  test "entered_score", ->
    equal(@component.get('entered_score'), 10)

  test "late_penalty", ->
    equal(@component.get('late_penalty'), -2)

  test "points_possible", ->
    equal(@component.get('points_possible'), 10)

  test "final_grade", ->
    equal(@component.get('final_grade'), 'B')

  test "saveURL", ->
    equal(@component.get('saveURL'), "/api/v1/assignment/1/1")

  test "isPoints", ->
    setType 'points'
    ok @component.get('isPoints')

  test "isPercent", ->
    setType 'percent'
    ok @component.get('isPercent')

  test "isLetterGrade", ->
    setType 'letter_grade'
    ok @component.get('isLetterGrade')

  test "isInPastGradingPeriodAndNotAdmin is true when the submission is gradeLocked", ->
    run => @submission.set('gradeLocked', true)
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), true

  test "isInPastGradingPeriodAndNotAdmin is false when the submission is not gradeLocked", ->
    run => @submission.set('gradeLocked', false)
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), false

  test "nilPointsPossible", ->
    run => @assignment.set('points_possible', null)
    ok @component.get('nilPointsPossible')
    run => @assignment.set('points_possible', 10)
    equal @component.get('nilPointsPossible'), false

  test "isGpaScale", ->
    setType 'gpa_scale'
    ok @component.get('isGpaScale')

  test "isPassFail", ->
    setType 'pass_fail'
    ok @component.get('isPassFail')

  test "does not translate pass_fail grades", ->
    setType 'pass_fail'
    @stub(GradeFormatHelper, 'formatGrade').returns 'completo'
    run => @submission.set('entered_grade', 'complete')
    @component.submissionDidChange()
    equal(@component.get('value'), 'complete')

  test "formats percent grades", ->
    setType 'percent'
    @stub(GradeFormatHelper, 'formatGrade').returns '32,4%'
    run => @submission.set('entered_grade', '32.4')
    @component.submissionDidChange()
    equal(@component.get('value'), '32,4%')

  test "focusOut", (assert) ->
    done = assert.async()
    stub = @stub @component, 'boundUpdateSuccess'
    submissions = []

    requestStub = null
    run =>
      requestStub = Ember.RSVP.resolve all_submissions: submissions

    @stub(@component, 'ajax').returns requestStub

    run =>
      @component.set('value', 'ohai')
      @component.send('focusOut', {target: {id: 'student_and_assignment_grade'}})
      
    Promise.resolve().then ->
      ok stub.called
      done()

  test "onUpdateSuccess", ->
    run => @assignment.set('points_possible', 100)
    flashWarningStub = @stub $, 'flashWarning'
    @component.onUpdateSuccess({all_submissions: [], score: 150})
    ok flashWarningStub.called
