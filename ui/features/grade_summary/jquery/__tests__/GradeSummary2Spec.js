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
import {useScope as createI18nScope} from '@canvas/i18n'
import fakeENV from '@canvas/test-utils/fakeENV'
import GradeSummary from '../index'

const I18n = createI18nScope('gradingGradeSummary')

const $fixtures = $('#fixtures')

let exampleGrades

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

function createExampleGrades() {
  return {
    assignmentGroups: {},
    current: {
      score: 0,
      possible: 0,
    },
    final: {
      score: 0,
      possible: 20,
    },
  }
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

function commonSetup() {
  fakeENV.setup({grade_calc_ignore_unposted_anonymous_enabled: true})
  $fixtures.html('')
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

QUnit.module('GradeSummary.getOriginalScore', {
  setup() {
    fullPageSetup()
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
  },

  teardown() {
    commonTeardown()
  },
})

test('parses the text of the .original_points element', function () {
  const score = GradeSummary.getOriginalScore(this.$assignment)
  strictEqual(score.numericalValue, 10)
  strictEqual(score.formattedValue, '10')
})

test('sets "numericalValue" to a default of null', function () {
  this.$assignment.find('.original_points').text('invalid')
  const score = GradeSummary.getOriginalScore(this.$assignment)
  strictEqual(score.numericalValue, null)
})

test('sets "formattedValue" to formatted grade', function () {
  this.$assignment.find('.original_score').text('C+ (78.5)')
  const score = GradeSummary.getOriginalScore(this.$assignment)
  equal(score.formattedValue, 'C+ (78.5)')
})

QUnit.module('GradeSummary.calculateTotals', suiteHooks => {
  suiteHooks.beforeEach(() => {
    commonSetup()
    ENV.assignment_groups = createAssignmentGroups()
    sandbox.stub($, 'screenReaderFlashMessageExclusive')
    setPageHtmlFixture()
  })

  suiteHooks.afterEach(() => {
    commonTeardown()
  })

  test('displays a screenreader-only alert when grades have been changed', () => {
    $fixtures.find('.assignment_score .grade').addClass('changed')
    GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
    equal($.screenReaderFlashMessageExclusive.callCount, 1)
    const messageText = $.screenReaderFlashMessageExclusive.getCall(0).args[0]
    ok(messageText.includes('the new total is now'), 'flash message mentions new total')
  })

  test('does not display a screenreader-only alert when grades have not been changed', () => {
    GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
    equal($.screenReaderFlashMessageExclusive.callCount, 0)
  })

  test('localizes displayed grade', () => {
    sandbox.stub(I18n.constructor.prototype, 'n').returns('1,234')
    GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
    const $teaser = $fixtures.find('.student_assignment.final_grade .score_teaser')
    ok($teaser.text().includes('1,234'), 'includes internationalized score')
  })

  QUnit.module('final grade override', contextHooks => {
    contextHooks.beforeEach(() => {
      exampleGrades = createExampleGrades()
      exampleGrades.current = {score: 23, possible: 100}
      const gradingSchemeDataRows = [
        {name: 'A', value: 0.9},
        {name: 'B', value: 0.8},
        {name: 'C', value: 0.7},
        {name: 'D', value: 0.6},
        {name: 'F', value: 0},
      ]
      ENV.course_active_grading_scheme = {data: gradingSchemeDataRows}
      ENV.grading_scheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['F', 0],
      ]
    })

    test('sets the letter grade to the effective grade', () => {
      ENV.effective_final_score = 72
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_grade .letter_grade')
      strictEqual($grade.text(), 'C')
    })

    test('sets the percent grade to the calculated percent grade, if overrides not present', () => {
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_grade .grade').first()
      strictEqual($grade.text(), '23%')
    })

    test('sets the letter grade to the calculated letter grade, if overrides not present', () => {
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_grade .letter_grade')
      strictEqual($grade.text(), 'F')
    })

    test('changed What-If scores take precedence over the effective grade', () => {
      ENV.effective_final_score = 72
      exampleGrades.current = {score: 3, possible: 10}
      const changedGrade = '<span class="grade changed">3</span>'
      $fixtures.find('.score_holder .tooltip').html(changedGrade)
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_grade .grade').first()
      strictEqual($grade.text(), '30%')
    })

    test('override score of 0 results in a 0%', () => {
      ENV.effective_final_score = 0
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_grade .grade').first()
      strictEqual($grade.text(), '0%')
    })

    test('override score of 0 results in an F letter grade', () => {
      ENV.effective_final_score = 0
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_grade .letter_grade').first()
      strictEqual($grade.text(), 'F')
    })

    // At present, ENV.grading_scheme is always present, but that may change
    // some day if there's no longer a need to always send it back (in other
    // parts of Canvas, it's only present when a grading scheme is enabled),
    // so this is a defensive test.
    test('when a grading scheme is not present, but an override is, the raw override score is shown', () => {
      delete ENV.grading_scheme
      ENV.effective_final_score = 72
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_grade .grade').first()
      strictEqual($grade.text(), '72%')
    })

    // This test is necessary because GradeSummary determines if a grading
    // scheme is present via the presence of this span.
    test('when the .letter_grade span is not present, the raw override score is shown', () => {
      $('.final_grade .letter_grade').remove()
      ENV.effective_final_score = 72
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_grade .grade').first()
      strictEqual($grade.text(), '72%')
    })

    test('when there is a custom status in the ENV, renders a status pill span class', () => {
      ENV.final_override_custom_grade_status_id = '42'
      ENV.effective_final_score = 84
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $status = $fixtures.find('.final_grade .status').first().children().first()
      ok($status.length)
      ok($status.hasClass('submission-custom-grade-status-pill-42'), 'has class for custom status')
    })

    test('when the custom status has allow_final_grade_value equal to false it will display the grade as "-"', () => {
      ENV.final_override_custom_grade_status_id = '42'
      ENV.effective_final_score = 84
      ENV.custom_grade_statuses = [
        {id: '42', title: 'Custom Status', allow_final_grade_value: false},
      ]
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $status = $fixtures.find('.final_grade .status').first().children().first()
      ok($status.length)
      const $grade = $fixtures.find('.final_grade .grade').first()
      strictEqual($grade.text(), '-')
    })
  })

  QUnit.module('points based grading scheme', contextHooks => {
    contextHooks.beforeEach(() => {
      exampleGrades = createExampleGrades()
      exampleGrades.current = {score: 89.98, possible: 100}
      exampleGrades.final = {score: 89.98, possible: 100}
      const gradingSchemeDataRows = [
        {name: 'A', value: 0.9},
        {name: 'B', value: 0.8},
        {name: 'C', value: 0.7},
        {name: 'D', value: 0.6},
        {name: 'F', value: 0},
      ]
      ENV.course_active_grading_scheme = {data: gradingSchemeDataRows}
      ENV.course_active_grading_scheme.points_based = true
      ENV.course_active_grading_scheme.scaling_factor = 10
      ENV.grading_scheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['F', 0],
      ]
    })

    test('when points based grading scheme is in use the letter score is based off the scaled final score', () => {
      GradeSummary.calculateTotals(exampleGrades, 'current', null)
      const $letterGrade = $fixtures.find('.final_grade .letter_grade')
      strictEqual($letterGrade.text(), 'A')
    })
  })
})
