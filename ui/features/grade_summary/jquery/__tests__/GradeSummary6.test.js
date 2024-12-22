/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import _ from 'lodash'
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import fakeENV from '@canvas/test-utils/fakeENV'
import GradeSummary from '../index'

const $fixtures =
  document.getElementById('fixtures') ||
  (() => {
    const fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)
    return fixturesDiv
  })()

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
  $fixtures.innerHTML = `
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
      </table>
      <input type="text" id="grade_entry" style="display: none;" />
      <a id="revert_score_template" class="revert_score_link" style="display: none;">Revert Score</a>
      <a href="/assignments/{{ assignment_id }}" class="update_submission_url">&nbsp;</a>
      <div id="GradeSummarySelectMenuGroup"></div>
    </div>
  `
}

describe('GradeSummary - Revert Score', () => {
  let $assignment

  function simulateWhatIfUse($assignmentToEdit) {
    const $assignmentScore = $assignmentToEdit.find('.assignment_score')
    const $grade = $assignmentToEdit.find('.grade')
    // reproduce the What-If setup from .onEditWhatIfScore
    const $screenreaderLinkClone = $assignmentScore.find('.screenreader-only').clone(true)
    $assignmentScore.find('.grade').data('screenreader_link', $screenreaderLinkClone)
    // reproduce the What-If setup from .onScoreChange
    const $scoreTeaser = $assignmentScore.find('.score_teaser')
    $assignmentScore.attr('title', '')
    $scoreTeaser.text('This is a What-If score')
    const $revertScore = $('#revert_score_template').clone(true).attr('id', '').show()
    $assignmentScore.find('.score_holder').append($revertScore)
    $grade.addClass('changed')
    $assignment.find('.original_score').text('5')
    ENV.submissions[0].workflow_state = 'graded'
  }

  beforeEach(() => {
    // Mock jQuery plugins
    $.fn.showIf = function () {
      return this
    }
    $.screenReaderFlashMessageExclusive = jest.fn()
    $.ajaxJSON = jest.fn()
    $.ajaxJSON.unhandledXHRs = []
    $.ajaxJSON.storeRequest = jest.fn()

    fakeENV.setup({
      submissions: createSubmissions(),
      assignment_groups: createAssignmentGroups(),
      group_weighting_scheme: 'points',
      course_active_grading_scheme: {points_based: false},
      current_user: {id: '1'},
      current_user_roles: ['student'],
      student_id: '1',
      context_asset_string: 'course_1',
      GRADE_CALC_IGNORE_UNPOSTED_ANONYMOUS: false,
      GRADEBOOK_OPTIONS: {has_grading_periods: false},
    })

    setPageHtmlFixture()
    GradeSummary.setup()

    $assignment = $('.student_assignment.editable').first()
    simulateWhatIfUse($assignment)
  })

  afterEach(() => {
    fakeENV.teardown()
    $fixtures.innerHTML = ''
    jest.restoreAllMocks()
  })

  it('sets the .what_if_score text to the .original_score text', () => {
    GradeSummary.onScoreRevert($assignment)
    expect($assignment.find('.what_if_score').text()).toBe('5')
  })

  it('sets the submission workflow_state back to original value', () => {
    expect(ENV.submissions[0].workflow_state).toBe('graded')
    GradeSummary.onScoreRevert($assignment)
    expect(ENV.submissions[0].workflow_state).toBe('pending_review')
  })

  it('removes the .changed class from the .grade element', () => {
    GradeSummary.onScoreRevert($assignment)
    expect($assignment.find('.grade').hasClass('changed')).toBe(false)
  })

  it('removes the "revert score" link', () => {
    GradeSummary.onScoreRevert($assignment)
    expect($assignment.find('.revert_score_link')).toHaveLength(0)
  })

  it('restores the .assignment_score title', () => {
    GradeSummary.onScoreRevert($assignment)
    expect($assignment.find('.assignment_score').attr('title')).toBe(
      'Click to test a different score',
    )
  })

  it('restores the .score_teaser text', () => {
    GradeSummary.onScoreRevert($assignment)
    expect($assignment.find('.score_teaser').text()).toBe('Click to test a different score')
  })

  it('restores the screenreader text', () => {
    GradeSummary.onScoreRevert($assignment)
    expect($assignment.find('.screenreader-only').text()).toBe('Click to test a different score')
  })

  it('sets the title attribute for muted assignments', () => {
    const $unpostedAssignment = $('.student_assignment.editable[data-muted="true"]').first()
    simulateWhatIfUse($unpostedAssignment)
    GradeSummary.onScoreRevert($unpostedAssignment)
    expect($unpostedAssignment.find('.assignment_score').attr('title')).toBe(
      'Instructor has not posted this grade',
    )
  })

  it('sets the tooltip text for muted assignments', () => {
    const $unpostedAssignment = $('.student_assignment.editable[data-muted="true"]').first()
    simulateWhatIfUse($unpostedAssignment)
    GradeSummary.onScoreRevert($unpostedAssignment)
    expect($unpostedAssignment.find('.score_teaser').text()).toBe(
      'Instructor has not posted this grade',
    )
  })
})

describe('GradeSummary - Update Score', () => {
  beforeEach(() => {
    fakeENV.setup({
      submissions: createSubmissions(),
      assignment_groups: createAssignmentGroups(),
      group_weighting_scheme: 'points',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('updates the score for an existing submission', () => {
    GradeSummary.updateScoreForAssignment('203', 20)
    expect(ENV.submissions[1].score).toBe(20)
  })

  it('creates a new submission when one does not exist', () => {
    GradeSummary.updateScoreForAssignment('202', 15)
    expect(ENV.submissions).toHaveLength(2)
    expect(ENV.submissions[1].assignment_id).toBe('202')
    expect(ENV.submissions[1].score).toBe(15)
  })
})

describe('GradeSummary - Final Grade Points Possible Text', () => {
  beforeEach(() => {
    fakeENV.setup({
      group_weighting_scheme: 'percent',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('returns an empty string if assignment groups are weighted', () => {
    const text = GradeSummary.finalGradePointsPossibleText('percent', '50.00 / 100.00')
    expect(text).toBe('')
  })

  it('returns the points possible text if assignment groups are not weighted', () => {
    ENV.group_weighting_scheme = null
    const text = GradeSummary.finalGradePointsPossibleText('percent', '50.00 / 100.00')
    expect(text).toBe('')
  })
})
