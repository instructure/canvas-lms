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

QUnit.module('GradeSummary - Revert Score', hooks => {
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

  hooks.beforeEach(() => {
    fullPageSetup()
    $assignment = $fixtures.find('#grades_summary .student_assignment').first()
    simulateWhatIfUse($assignment)
  })

  hooks.afterEach(() => {
    commonTeardown()
  })

  test('sets the .what_if_score text to the .original_score text', () => {
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.what_if_score').text(), '5')
  })

  test('sets the submission workflow_state back to original value', () => {
    equal(ENV.submissions[0].workflow_state, 'graded')
    GradeSummary.onScoreRevert($assignment)
    equal(ENV.submissions[0].workflow_state, 'pending_review')
  })

  test('sets the .assignment_score title to the "Click to test" message', () => {
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.assignment_score').attr('title'), 'Click to test a different score')
  })

  test('sets the .score_teaser text to the "Click to test" message when the assignment is not muted', () => {
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.score_teaser').text(), 'Click to test a different score')
  })

  test('sets the .score_teaser text to the "Instructor has not posted" message when the assignment is muted', () => {
    $assignment.data('muted', true)
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.score_teaser').text(), 'Instructor has not posted this grade')
  })

  test('removes the .revert_score_link element', () => {
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.revert_score_link').length, 0)
  })

  test('sets the .score_value text to the .original_score text', () => {
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.score_value').text(), '5')
  })

  test('sets the .score value text to "-" when the submission was ungraded', () => {
    $assignment.find('.original_points').text('')
    $assignment.find('.original_score').text('')
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.score_value').text(), '-')
  })

  test('sets the .grade html to the "icon-off" indicator when the assignment is muted', () => {
    $assignment.data('muted', true)
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.grade .icon-off').length, 1)
  })

  test('sets the .grade html to the "icon-quiz" indicator when the assignment is a quiz waiting to be graded', () => {
    $assignment.data('pending_quiz', true)
    GradeSummary.onScoreRevert($assignment)
    equal($assignment.find('.grade .icon-quiz').length, 1)
  })

  test('removes the "changed" class from the .grade element', () => {
    GradeSummary.onScoreRevert($assignment)
    notOk($assignment.find('.assignment_score .grade').hasClass('changed'))
  })

  test('sets the .grade text to .original_score when the assignment is not muted', () => {
    GradeSummary.onScoreRevert($assignment)
    const $grade = $assignment.find('.grade')
    $grade.children().remove() // remove all content except score text
    equal($grade.text(), '5')
  })

  test('updates the score for the assignment', () => {
    sandbox.stub(GradeSummary, 'updateScoreForAssignment')
    GradeSummary.onScoreRevert($assignment)
    equal(GradeSummary.updateScoreForAssignment.callCount, 1)
    const [assignmentId, score] = GradeSummary.updateScoreForAssignment.getCall(0).args
    equal(assignmentId, '201', 'first argument is the assignment id 201')
    strictEqual(score, 10, 'second argument is the numerical score 10')
  })

  test('updates the score for the assignment with null when the .original_points is blank', () => {
    $assignment.find('.original_points').text('')
    sandbox.stub(GradeSummary, 'updateScoreForAssignment')
    GradeSummary.onScoreRevert($assignment)
    const score = GradeSummary.updateScoreForAssignment.getCall(0).args[1]
    strictEqual(score, null)
  })

  test('updates the student grades after updating the assignment score', () => {
    sandbox.stub(GradeSummary, 'updateScoreForAssignment')
    sandbox.stub(GradeSummary, 'updateStudentGrades').callsFake(() => {
      equal(
        GradeSummary.updateScoreForAssignment.callCount,
        1,
        'updateScoreForAssignment is performed first'
      )
    })
    GradeSummary.onScoreRevert($assignment)
    equal(GradeSummary.updateStudentGrades.callCount, 1, 'updateStudentGrades is called once')
  })

  test('attaches a "Click to test" .screenreader-only element to the grade element', () => {
    const $grade = $fixtures.find('.assignment_score .grade').first()
    GradeSummary.onScoreRevert($assignment)
    equal($grade.find('.screenreader-only').length, 1)
    equal($grade.find('.screenreader-only').text(), 'Click to test a different score')
  })

  test('sets the title attribute', () => {
    const $unpostedAssignment = $fixtures.find('#grades_summary .student_assignment').eq(1)
    simulateWhatIfUse($unpostedAssignment)
    GradeSummary.onScoreRevert($unpostedAssignment)
    equal(
      $unpostedAssignment.find('.assignment_score').attr('title'),
      'Instructor has not posted this grade'
    )
  })

  test('sets the unposted icon to icon-off when submission is unposted', () => {
    const $unpostedAssignment = $fixtures.find('#grades_summary .student_assignment').eq(1)
    simulateWhatIfUse($unpostedAssignment)
    GradeSummary.onScoreRevert($unpostedAssignment)
    strictEqual($unpostedAssignment.find('i.icon-off').length, 1)
  })
})

QUnit.module('GradeSummary.updateScoreForAssignment', {
  setup() {
    fakeENV.setup()
    ENV.submissions = createSubmissions()
  },

  teardown() {
    fakeENV.teardown()
  },
})

test('updates the score for an existing submission', () => {
  GradeSummary.updateScoreForAssignment('203', 20)
  equal(ENV.submissions[1].score, 20, 'the second submission is for assignment 203')
})

test('ignores submissions not having the given assignment id', () => {
  GradeSummary.updateScoreForAssignment('203', 20)
  equal(ENV.submissions[0].score, 10, 'the first submission is for assignment 201')
})

test('adds a submission with the score when no submission matches the given assignment id', () => {
  GradeSummary.updateScoreForAssignment('203', 30)
  equal(ENV.submissions.length, 2, 'submission count has changed from 1 to 2')
  deepEqual(_.map(ENV.submissions, 'assignment_id'), ['201', '203'])
  deepEqual(_.map(ENV.submissions, 'score'), [10, 30])
})

QUnit.module('GradeSummary.finalGradePointsPossibleText', {
  setup() {
    fakeENV.setup()
  },

  teardown() {
    fakeENV.teardown()
  },
})

test('returns an empty string if assignment groups are weighted', () => {
  const text = GradeSummary.finalGradePointsPossibleText('percent', '50.00 / 100.00')
  strictEqual(text, '')
})

test('returns the score with points possible if assignment groups are not weighted', () => {
  const text = GradeSummary.finalGradePointsPossibleText('equal', '50.00 / 100.00')
  strictEqual(text, '50.00 / 100.00')
})

test('returns an empty string if grading periods are weighted and "All Grading Periods" is selected', () => {
  ENV.grading_period_set = {
    id: '1501',
    grading_periods: [
      {id: '701', weight: 50},
      {id: '702', weight: 50},
    ],
    weighted: true,
  }
  ENV.current_grading_period_id = '0'
  const text = GradeSummary.finalGradePointsPossibleText('equal', '50.00 / 100.00')
  strictEqual(text, '')
})

test('returns the score with points possible if grading periods are weighted and a period is selected', () => {
  ENV.grading_period_set = {
    id: '1501',
    grading_periods: [
      {id: '701', weight: 50},
      {id: '702', weight: 50},
    ],
    weighted: true,
  }
  ENV.current_grading_period_id = '701'
  const text = GradeSummary.finalGradePointsPossibleText('equal', '50.00 / 100.00')
  strictEqual(text, '50.00 / 100.00')
})

test('returns the score with points possible if grading periods are not weighted', () => {
  ENV.grading_period_set = {
    id: '1501',
    grading_periods: [
      {id: '701', weight: 50},
      {id: '702', weight: 50},
    ],
    weighted: false,
  }

  const text = GradeSummary.finalGradePointsPossibleText('equal', '50.00 / 100.00')
  strictEqual(text, '50.00 / 100.00')
})
