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
import GradeSummary from '../index'

const $fixtures = $('#fixtures')

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

function commonSetup() {
  fakeENV.setup({grade_calc_ignore_unposted_anonymous_enabled: true})
  $fixtures.html('')
}

function commonTeardown() {
  fakeENV.teardown()
  $fixtures.html('')
}

QUnit.module('GradeSummary.getGradingPeriodSet', {
  setup() {
    commonSetup()
  },

  teardown() {
    commonTeardown()
  },
})

test('normalizes the grading period set from the env', () => {
  ENV.grading_period_set = {
    id: '1501',
    grading_periods: [
      {id: '701', weight: 50},
      {id: '702', weight: 50},
    ],
    weighted: true,
  }
  const gradingPeriodSet = GradeSummary.getGradingPeriodSet()
  deepEqual(gradingPeriodSet.id, '1501')
  equal(gradingPeriodSet.gradingPeriods.length, 2)
  deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702'])
})

test('returns null when the grading period set is not defined in the env', () => {
  ENV.grading_period_set = undefined
  const gradingPeriodSet = GradeSummary.getGradingPeriodSet()
  deepEqual(gradingPeriodSet, null)
})

QUnit.module('GradeSummary.getAssignmentId', {
  setup() {
    commonSetup()
    setPageHtmlFixture()
  },

  teardown() {
    commonTeardown()
  },
})

test('returns the assignment id for the given .student_assignment element', () => {
  const $assignment = $fixtures.find('#grades_summary .student_assignment').first()
  strictEqual(GradeSummary.getAssignmentId($assignment), '201')
})

QUnit.module('GradeSummary.parseScoreText')

test('sets "numericalValue" to the parsed value', () => {
  const score = GradeSummary.parseScoreText('1,234')
  strictEqual(score.numericalValue, 1234)
})

test('sets "formattedValue" to the formatted value', () => {
  const score = GradeSummary.parseScoreText('1234')
  strictEqual(score.formattedValue, '1,234')
})

test('sets "numericalValue" to null when given an empty string', () => {
  const score = GradeSummary.parseScoreText('')
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to null when given null', () => {
  const score = GradeSummary.parseScoreText(null)
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to null when given undefined', () => {
  const score = GradeSummary.parseScoreText(undefined)
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to the "numericalDefault" when "numericalDefault" is a number', () => {
  const score = GradeSummary.parseScoreText(undefined, 5)
  strictEqual(score.numericalValue, 5)
})

test('sets "numericalValue" to null when "numericalDefault" is a string', () => {
  const score = GradeSummary.parseScoreText(undefined, '5')
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to null when "numericalDefault" is null', () => {
  const score = GradeSummary.parseScoreText(undefined, null)
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to null when "numericalDefault" is undefined', () => {
  const score = GradeSummary.parseScoreText(undefined, undefined)
  strictEqual(score.numericalValue, null)
})

test('sets "formattedValue" to "-" when given an empty string', () => {
  const score = GradeSummary.parseScoreText('')
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to "-" when given null', () => {
  const score = GradeSummary.parseScoreText(null)
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to "-" when given undefined', () => {
  const score = GradeSummary.parseScoreText(undefined)
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to the "formattedDefault" when "formattedDefault" is a string', () => {
  const score = GradeSummary.parseScoreText(undefined, null, 'default')
  strictEqual(score.formattedValue, 'default')
})

test('sets "formattedValue" to "-" when "formattedDefault" is a number', () => {
  const score = GradeSummary.parseScoreText(undefined, null, 5)
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to "-" when "formattedDefault" is null', () => {
  const score = GradeSummary.parseScoreText(undefined, null, null)
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to "-" when "formattedDefault" is undefined', () => {
  const score = GradeSummary.parseScoreText(undefined, null, undefined)
  strictEqual(score.formattedValue, '-')
})
