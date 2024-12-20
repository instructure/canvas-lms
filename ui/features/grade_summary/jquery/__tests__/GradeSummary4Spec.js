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
import axios from '@canvas/axios'
import fakeENV from '@canvas/test-utils/fakeENV'
import numberHelper from '@canvas/i18n/numberHelper'
import GradeSummary from '../index'

const $fixtures = $('#fixtures')

const awhile = (milliseconds = 2) => new Promise(resolve => setTimeout(resolve, milliseconds))

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

QUnit.module('GradeSummary.setup', {
  setup() {
    fakeENV.setup()
    setPageHtmlFixture()
    ENV.submissions = createSubmissions()
    ENV.assignment_groups = createAssignmentGroups()
    ENV.group_weighting_scheme = 'points'
    this.$showWhatIfScoresContainer = $fixtures.find('#student-grades-whatif')
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
  },

  teardown() {
    commonTeardown()
  },
})

test('sends an axios request to mark unread submissions as read', async function () {
  ENV.assignments_2_student_enabled = true
  const axiosSpy = sandbox.spy(axios, 'put')
  GradeSummary.setup()
  await awhile()
  const expectedUrl = `/api/v1/courses/1/submissions/bulk_mark_read`
  equal(axiosSpy.callCount, 1)
  deepEqual(axiosSpy.getCall(0).args, [expectedUrl, {submissionIds: ['123', '456']}])
})

test('does not mark unread submissions as read if assignments_2_student_enabled feature flag off', async function () {
  ENV.assignments_2_student_enabled = false
  const axiosSpy = sandbox.spy(axios, 'put')
  GradeSummary.setup()
  await awhile()
  equal(axiosSpy.callCount, 0)
})

test('shows the "Show Saved What-If Scores" button when any assignment has a What-If score', async function () {
  GradeSummary.setup()
  await awhile()
  ok(this.$showWhatIfScoresContainer.is(':visible'), 'button container is visible')
})

test('uses I18n to parse the .student_entered_score value', async function () {
  sandbox.spy(GradeSummary, 'parseScoreText')
  this.$assignment.find('.student_entered_score').text('7')
  GradeSummary.setup()
  await awhile()
  equal(GradeSummary.parseScoreText.callCount, 1, 'GradeSummary.parseScoreText was called once')
  const [value] = GradeSummary.parseScoreText.getCall(0).args
  equal(value, '7', 'GradeSummary.parseScoreText was called with the .student_entered_score')
})

test('shows the "Show Saved What-If Scores" button for assignments with What-If scores of "0"', async function () {
  this.$assignment.find('.student_entered_score').text('0')
  GradeSummary.setup()
  await awhile()
  ok(this.$showWhatIfScoresContainer.is(':visible'), 'button container is visible')
})

test('does not show the "Show Saved What-If Scores" button for assignments without What-If scores', async function () {
  this.$assignment.find('.student_entered_score').text('')
  GradeSummary.setup()
  await awhile()
  ok(this.$showWhatIfScoresContainer.is(':hidden'), 'button container is hidden')
})

test('does not show the "Show Saved What-If Scores" button for assignments with What-If invalid scores', async function () {
  this.$assignment.find('.student_entered_score').text('null')
  GradeSummary.setup()
  await awhile()
  ok(this.$showWhatIfScoresContainer.is(':hidden'), 'button container is hidden')
})

QUnit.module('Grade Summary "Show Saved What-If Scores" button', {
  setup() {
    fakeENV.setup()
    setPageHtmlFixture()
    ENV.submissions = createSubmissions()
    ENV.assignment_groups = createAssignmentGroups()
    ENV.group_weighting_scheme = 'points'
    GradeSummary.setup()
    this.$showWhatIfScoresButton = $fixtures.find('.show_guess_grades_link')
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
  },

  teardown() {
    commonTeardown()
  },
})

test('reveals all What-If scores when clicked', function () {
  this.$showWhatIfScoresButton.click()
  equal(
    this.$assignment.find('.what_if_score').text(),
    '7',
    'what_if_score is set to the .student_entered_score'
  )
})

test('hides the assignment .score_value element', function () {
  this.$showWhatIfScoresButton.click()
  const $scoreValue = $fixtures.find('.assignment_score .score_value').first()
  ok($scoreValue.is(':hidden'), '.score_value is hidden')
})

test('triggers onScoreChange for the assignment', function () {
  sandbox.stub(GradeSummary, 'onScoreChange')
  this.$showWhatIfScoresButton.click()
  equal(
    GradeSummary.onScoreChange.callCount,
    1,
    'called once for each assignment (only one in fixture)'
  )
  const [$assignment, options] = GradeSummary.onScoreChange.getCall(0).args
  equal(
    $assignment.get(0),
    this.$assignment.get(0),
    'first parameter is the assignment jquery object'
  )
  deepEqual(
    options,
    {update: false, refocus: false},
    'second parameter is the assignment jquery object'
  )
})

// eslint-disable-next-line jest/no-identical-title
test('uses I18n to parse the .student_entered_score value', function () {
  sandbox.stub(GradeSummary, 'onScoreChange')
  sandbox.spy(GradeSummary, 'parseScoreText')
  this.$assignment.find('.student_entered_score').text('7')
  this.$showWhatIfScoresButton.click()
  equal(GradeSummary.parseScoreText.callCount, 1, 'GradeSummary.parseScoreText was called once')
  const [value] = GradeSummary.parseScoreText.getCall(0).args
  equal(value, '7', 'GradeSummary.parseScoreText was called with the .student_entered_score')
})

test('includes assignments with What-If scores of "0"', function () {
  this.$assignment.find('.student_entered_score').text('0')
  this.$showWhatIfScoresButton.click()
  equal(
    this.$assignment.find('.what_if_score').text(),
    '0',
    'what_if_score is set to the .student_entered_score'
  )
})

test('ignores assignments without What-If scores', function () {
  sandbox.stub(GradeSummary, 'onScoreChange')
  this.$assignment.find('.student_entered_score').text('')
  this.$showWhatIfScoresButton.click()
  const $scoreValue = $fixtures.find('.assignment_score .score_value').first()
  notOk($scoreValue.is(':hidden'), '.score_value is not hidden')
  equal(GradeSummary.onScoreChange.callCount, 0, 'onScoreChange is not called')
  equal(this.$assignment.find('.what_if_score').text(), '', 'what_if_score is not changed')
})

test('ignores assignments with invalid What-If score text', function () {
  sandbox.stub(GradeSummary, 'onScoreChange')
  this.$assignment.find('.student_entered_score').text('null')
  this.$showWhatIfScoresButton.click()
  const $scoreValue = $fixtures.find('.assignment_score .score_value').first()
  notOk($scoreValue.is(':hidden'), '.score_value is not hidden')
  equal(GradeSummary.onScoreChange.callCount, 0, 'onScoreChange is not called')
  equal(this.$assignment.find('.what_if_score').text(), '', 'what_if_score is not changed')
})

test('hides itself when clicked', function () {
  this.$showWhatIfScoresButton.click()
  ok(this.$showWhatIfScoresButton.is(':hidden'), 'button is hidden')
})

test('sets focus on the "revert all scores" button', function () {
  this.$showWhatIfScoresButton.click()
  equal(document.activeElement, $('#revert-all-to-actual-score').get(0), 'button is active element')
})

test('displays a screenreader message indicating visibility of What-If scores', function () {
  sandbox.stub(GradeSummary, 'onScoreChange')
  sandbox.stub($, 'screenReaderFlashMessageExclusive')
  this.$showWhatIfScoresButton.click()
  equal(
    $.screenReaderFlashMessageExclusive.callCount,
    1,
    'screenReaderFlashMessageExclusive is called once'
  )
  const [message] = $.screenReaderFlashMessageExclusive.getCall(0).args
  equal(message, 'Grades are now showing what-if scores')
})

QUnit.module('Grade Summary "Show All Details" button', {
  setup() {
    fakeENV.setup()
    setPageHtmlFixture()
    ENV.submissions = createSubmissions()
    ENV.assignment_groups = createAssignmentGroups()
    ENV.group_weighting_scheme = 'points'
    GradeSummary.setup()
  },

  teardown() {
    commonTeardown()
  },
})

test('announces "assignment details expanded" when clicked', () => {
  $('#show_all_details_button').click()
  equal($('#aria-announcer').text(), 'assignment details expanded')
})

test('changes text to "Hide All Details" when clicked', () => {
  $('#show_all_details_button').click()
  equal($('#show_all_details_button').text(), 'Hide All Details')
})

test('announces "assignment details collapsed" when clicked and already expanded', () => {
  $('#show_all_details_button').click()
  $('#show_all_details_button').click()
  equal($('#aria-announcer').text(), 'assignment details collapsed')
})

test('changes text to "Show All Details" when clicked twice', () => {
  $('#show_all_details_button').click()
  $('#show_all_details_button').click()
  equal($('#show_all_details_button').text(), 'Show All Details')
})

QUnit.module('GradeSummary.onEditWhatIfScore', {
  setup() {
    fullPageSetup()
    $fixtures.find('.assignment_score .grade').first().append('5')
  },

  onEditWhatIfScore() {
    const $assignmentScore = $fixtures.find('.assignment_score').first()
    GradeSummary.onEditWhatIfScore($assignmentScore, $('#aria-announcer'))
  },

  teardown() {
    commonTeardown()
  },
})

test('stores the original score when editing the the first time', function () {
  const $grade = $fixtures.find('.assignment_score .grade').first()
  const expectedHtml = $grade.html()
  this.onEditWhatIfScore()
  equal($grade.data('originalValue'), expectedHtml)
})

test('does not store the score when the original score is already stored', function () {
  const $grade = $fixtures.find('.assignment_score .grade').first()
  $grade.data('originalValue', '10')
  this.onEditWhatIfScore()
  equal($grade.data('originalValue'), '10')
})

test('attaches a screenreader-only element to the grade element as data', function () {
  this.onEditWhatIfScore()
  const $grade = $fixtures.find('.assignment_score .grade').first()
  ok($grade.data('screenreader_link'), '"screenreader_link" is assigned as data')
  ok(
    $grade.data('screenreader_link').hasClass('screenreader-only'),
    '"screenreader_link" is screenreader-only'
  )
})

test('hides the score value', function () {
  this.onEditWhatIfScore()
  const $scoreValue = $fixtures.find('.assignment_score .score_value').first()
  ok($scoreValue.is(':hidden'), '.score_value is hidden')
})

test('replaces the grade element content with a grade entry field', function () {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('.assignment_score .grade > #grade_entry')
  equal($gradeEntry.length, 1, '#grade_entry is attached to the .grade element')
})

test('sets the value of the grade entry to the existing "What-If" score', function () {
  $fixtures.find('.assignment_score').first().find('.what_if_score').text('15')
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  equal($gradeEntry.val(), '15', 'the previous "What-If" score is 15')
})

test('defaults the value of the grade entry to "0" when no score is present', function () {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  equal($gradeEntry.val(), '0', 'there is no previous "What-If" score')
})

test('uses I18n to parse the existing "What-If" score', function () {
  $fixtures.find('.assignment_score').first().find('.what_if_score').text('1.234,56')
  sandbox.stub(numberHelper, 'parse').withArgs('1.234,56').returns('654321')
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  equal(
    $gradeEntry.val(),
    '654321',
    'the previous "What-If" score might have been internationalized'
  )
})

test('shows the grade entry', function () {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  ok($gradeEntry.is(':visible'), '#grade_entry does not have "visibility: none"')
})

test('sets focus on the grade entry', function () {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  equal($gradeEntry.get(0), document.activeElement, '#grade_entry is the active element')
})

test('selects the grade entry', function () {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').get(0)
  equal($gradeEntry.selectionStart, 0, 'selection starts at beginning of score text')
  equal($gradeEntry.selectionEnd, 1, 'selection ends at end of score text')
})

test('announces message for entering a "What-If" score', function () {
  this.onEditWhatIfScore()
  equal($('#aria-announcer').text(), 'Enter a What-If score.')
})
