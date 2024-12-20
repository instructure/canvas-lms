/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import _ from 'lodash'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import numberHelper from '@canvas/i18n/numberHelper'
import GradeSummary from '../index'

const $fixtures = $('#fixtures')

function createAssignmentGroups() {
  return [
    {
      id: '301',
      assignments: [
        {id: '201', muted: false, points_possible: 20},
        {id: '202', muted: true, points_possible: 20},
      ],
    },
    {id: '302', assignments: [{id: '203', muted: true, points_possible: 20}]},
  ]
}

function createSubmissions() {
  return [{assignment_id: '201', score: 10}]
}

function setPageHtmlFixture() {
  $fixtures.html(`
    <div id="grade_summary_fixture">
      <select class="grading_periods_selector">
        <option value="0" selected>All Grading Periods</option>
        <option value="701">Grading Period 1</option>
        <option value="702">Grading Period 2</option>
      </select>
      <input type="checkbox" id="only_consider_graded_assignments" checked="true">
      <div id="student-grades-right-content">
        <div class="student_assignment final_grade">
          <span class="grade"></span>
          (
            <span id="final_letter_grade_text" class="letter_grade">–</span>
          )
          <span class="score_teaser"></span>
        </div>
        <div id="student-grades-whatif" class="show_guess_grades" style="display: none;">
          <button type="button" class="show_guess_grades_link">Show Saved "What-If" Scores</button>
        </div>
        <div id="student-grades-revert" class="revert_all_scores" style="display: none;">
          *NOTE*: This is NOT your official score.<br/>
          <button id="revert-all-to-actual-score" class="revert_all_scores_link">Revert to Actual Score</button>
        </div>
        <button id="show_all_details_button">Show All Details</button>
      </div>
      <span id="aria-announcer"></span>
      <table id="grades_summary" class="editable">
        <tr class="student_assignment editable" data-muted="false">
          <td class="assignment_score" title="Click to test a different score">
            <div class="score_holder">
              <span class="tooltip">
                <span class="grade">
                  <span class="tooltip_wrap right">
                    <span class="tooltip_text score_teaser">Click to test a different score</span>
                  </span>
                  <span class="screenreader-only">Click to test a different score</span>
                </span>
                <span class="score_value">A</span>
              </span>
              <span style="display: none;">
                <span class="original_points">10</span>
                <span class="original_score">10</span>
                <span class="submission_status">pending_review</span>
                <span class="what_if_score"></span>
                <span class="assignment_id">201</span>
                <span class="student_entered_score">7</span>
              </span>
            </div>
          </td>
        </tr>
        <tr class="student_assignment editable" data-muted="true">
          <td class="assignment_score" title="Muted">
            <div class="score_holder">
              <span class="tooltip">
                <span class="grade">
                  <span class="tooltip_wrap right">
                    <span class="tooltip_text score_teaser">Instructor has not posted this grade</span>
                  </span>
                </span>
                <span class="score_value"></span>
              </span>
              <span style="display: none;">
                <span class="original_points"></span>
                <span class="original_score"></span>
                <span class="what_if_score"></span>
                <span class="assignment_id">202</span>
              </span>
              <span class="unread_dot grade_dot" id="submission_unread_dot_123">&nbsp;</span>
            </div>
          </td>
        </tr>
        <tr class="student_assignment editable" data-muted="true">
          <td class="assignment_score" title="Muted">
            <div class="score_holder">
              <span class="tooltip">
                <span class="grade">
                  <span class="tooltip_wrap right">
                    <span class="tooltip_text score_teaser">Instructor has not posted this grade</span>
                  </span>
                </span>
                <span class="score_value"></span>
              </span>
              <span style="display: none;">
                <span class="original_points"></span>
                <span class="original_score"></span>
                <span class="what_if_score"></span>
                <span class="assignment_id">203</span>
              </span>
              <span class="unread_dot grade_dot" id="submission_unread_dot_456">&nbsp;</span>
            </div>
          </td>
        </tr>
        <tr class="student_assignment editable final_grade" data-muted="false">
          <td class="status" scope="row"></td>
          <td class="assignment_score" title="Click to test a different score"></td>
        </tr>
      </table>
      <input type="text" id="grade_entry" style="display: none;" />
      <a id="revert_score_template" class="revert_score_link" >Revert Score</i></a>
      <a href="/assignments/{{ assignment_id }}" class="update_submission_url">&nbsp;</a>
      <div id="GradeSummarySelectMenuGroup"></div>
    </div>
  `)
}

function fullPageSetup() {
  fakeENV.setup()
  setPageHtmlFixture()
  ENV.submissions = createSubmissions()
  ENV.assignment_groups = createAssignmentGroups()
  ENV.group_weighting_scheme = 'points'
  GradeSummary.setup()
}

function commonTeardown() {
  fakeENV.teardown()
  $fixtures.html('')
}

QUnit.module('GradeSummary.onScoreChange', {
  setup() {
    fullPageSetup()
    sandbox.stub($, 'ajaxJSON')
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
    // reproduce the destructive part of .onEditWhatIfScore
    this.$assignment.find('.assignment_score').find('.grade').empty().append($('#grade_entry'))
  },

  onScoreChange(score, options = {}) {
    this.$assignment.find('#grade_entry').val(score)
    GradeSummary.onScoreChange(this.$assignment, {update: false, refocus: false, ...options})
  },

  teardown() {
    commonTeardown()
  },
})

test('updates .what_if_score with the parsed value from #grade_entry', function () {
  this.onScoreChange('5')
  equal(this.$assignment.find('.what_if_score').text(), '5')
})

test('includes pending_review to for total grade when changing what-if score', function () {
  ENV.submissions = [
    {assignment_id: '201', score: 0, workflow_state: 'pending_review'},
    {assignment_id: '203', score: 10, workflow_state: 'graded'},
  ]

  // Page load should not include pending_review
  // Score should be 50% (10/20) for graded assignment 203
  const $grade = $fixtures.find('.final_grade .grade').first()
  strictEqual($grade.text(), '50%')

  this.onScoreChange('20')
  equal(this.$assignment.find('.what_if_score').text(), '20')

  // Total grade should include pending_review
  // Score should be 75% (10/20 & 20/20) for both assignments
  strictEqual($grade.text(), '75%')
  strictEqual(ENV.submissions[0].workflow_state, 'graded')
})

test('uses I18n to parse the #grade_entry score', function () {
  sandbox.stub(numberHelper, 'parse').withArgs('1.234,56').returns('654321')
  this.onScoreChange('1.234,56')
  equal(this.$assignment.find('.what_if_score').text(), '654321')
})

test('uses the previous .what_if_score value when #grade_entry is blank', function () {
  this.$assignment.find('.what_if_score').text('9.0')
  this.onScoreChange('')
  equal(this.$assignment.find('.what_if_score').text(), '9')
})

test('uses I18n to parse the previous .what_if_score value', function () {
  sandbox.stub(numberHelper, 'parse').withArgs('9.0').returns('654321')
  this.$assignment.find('.what_if_score').text('9.0')
  this.onScoreChange('')
  equal(this.$assignment.find('.what_if_score').text(), '654321')
})

test('removes the .dont_update class from the .student_assignment element when present', function () {
  this.$assignment.addClass('dont_update')
  this.onScoreChange('5')
  notOk(this.$assignment.hasClass('dont_update'))
})

test('saves the "What-If" grade using the api', function () {
  this.onScoreChange('5', {update: true})
  equal($.ajaxJSON.callCount, 1, '$.ajaxJSON was called once')
  const [url, method, params] = $.ajaxJSON.getCall(0).args
  equal(url, '/assignments/201', 'constructs the url from elements in the DOM')
  equal(method, 'PUT', 'uses PUT for updates')
  equal(params['submission[student_entered_score]'], 5)
})

test('updates the .student_entered_score element upon success api update', function () {
  $.ajaxJSON.callsFake((_url, _method, args, onSuccess) => {
    onSuccess({submission: {student_entered_score: args['submission[student_entered_score]']}})
  })
  this.onScoreChange('5', {update: true})
  equal(this.$assignment.find('.student_entered_score').text(), '5')
})

test('does not save the "What-If" grade when .dont_update class is present', function () {
  this.$assignment.addClass('dont_update')
  this.onScoreChange('5', {update: true})
  equal($.ajaxJSON.callCount, 0, '$.ajaxJSON was not called')
})

test('does not save the "What-If" grade when the "update" option is false', function () {
  this.onScoreChange('5', {update: false})
  equal($.ajaxJSON.callCount, 0, '$.ajaxJSON was not called')
})

test('hides the #grade_entry input', function () {
  this.onScoreChange('5')
  ok($('#grade_entry').is(':hidden'))
})

test('moves the #grade_entry to the body', function () {
  this.onScoreChange('5')
  ok($('#grade_entry').parent().is('body'))
})

test('sets the .assignment_score title to ""', function () {
  this.onScoreChange('5')
  equal(this.$assignment.find('.assignment_score').attr('title'), '')
})

test('sets the .assignment_score teaser text', function () {
  this.onScoreChange('5')
  equal(this.$assignment.find('.score_teaser').text(), 'This is a What-If score')
})

test('copies the "revert score" link into the .score_holder element', function () {
  this.onScoreChange('5')
  equal(
    this.$assignment.find('.score_holder .revert_score_link').length,
    1,
    'includes a "revert score" link'
  )
  equal(this.$assignment.find('.score_holder .revert_score_link').text(), 'Revert Score')
})

test('adds the "changed" class to the .grade element', function () {
  this.onScoreChange('5')
  ok(this.$assignment.find('.grade').hasClass('changed'))
})

test('sets the .grade element content to the updated score', function () {
  this.onScoreChange('5')
  const gradeText = this.$assignment.find('.grade').text()
  ok(gradeText.includes('5'))
})

test('sets the .grade element content to the previous score when the updated score is falsy', function () {
  this.$assignment.find('.grade').data('originalValue', '10.0')
  this.onScoreChange('')
  const gradeText = this.$assignment.find('.grade').text()
  ok(gradeText.includes('10'))
})

test('updates the score for the given assignment', function () {
  sandbox.stub(GradeSummary, 'updateScoreForAssignment')
  this.onScoreChange('5')
  equal(GradeSummary.updateScoreForAssignment.callCount, 1)
  const [assignmentId, score] = GradeSummary.updateScoreForAssignment.getCall(0).args
  equal(assignmentId, '201', 'the assignment id is 201')
  equal(score, 5, 'the parsed score is used to update the assignment score')
})
