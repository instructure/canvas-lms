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

import _ from 'lodash'
import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import fakeENV from '@canvas/test-utils/fakeENV'
import numberHelper from '@canvas/i18n/numberHelper'
import GradeSummary from '../index'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('gradingGradeSummary')

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
          <span class="grade">50%</span>
          (
            <span id="final_letter_grade_text" class="letter_grade">–</span>
          )
          <span class="score_teaser">10.00 / 20.00</span>
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
                <span class="score_value">10</span>
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
      </table>
      <input type="text" id="grade_entry" style="display: none;" />
      <a id="revert_score_template" class="revert_score_link" style="display: none;">Revert Score</a>
      <a href="/assignments/{{ assignment_id }}" class="update_submission_url">&nbsp;</a>
      <div id="GradeSummarySelectMenuGroup"></div>
    </div>
  `
}

describe('GradeSummary.onScoreChange', () => {
  let $assignment
  let onScoreChange

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
    const $gradeEntry = $('#grade_entry')
    $gradeEntry.appendTo($assignment.find('.grade'))

    onScoreChange = (score, options = {}) => {
      $gradeEntry.val(score)
      GradeSummary.onScoreChange($assignment, {update: false, refocus: false, ...options})
    }

    jest.spyOn($, 'ajaxJSON')
    jest.spyOn(GradeSummary, 'updateScoreForAssignment')
  })

  afterEach(() => {
    fakeENV.teardown()
    $fixtures.innerHTML = ''
    jest.restoreAllMocks()
  })

  it('updates .what_if_score with the parsed value from #grade_entry', () => {
    onScoreChange('5')
    expect($assignment.find('.what_if_score').text()).toBe('5')
  })

  it('includes pending_review to for total grade when changing what-if score', () => {
    ENV.submissions = [
      {assignment_id: '201', score: 0, workflow_state: 'pending_review'},
      {assignment_id: '203', score: 10, workflow_state: 'graded'},
    ]

    // Page load should not include pending_review
    // Score should be 50% (10/20) for graded assignment 203
    const $grade = $('.final_grade .grade').first()
    expect($grade.text()).toBe('50%')

    onScoreChange('20')
    expect($assignment.find('.what_if_score').text()).toBe('20')

    // Total grade should include pending_review
    // Score should be 75% (10/20 & 20/20) for both assignments
    expect($grade.text()).toBe('75%')
  })

  it('uses I18n to parse the #grade_entry score', () => {
    jest.spyOn(numberHelper, 'parse').mockReturnValue('654321')
    onScoreChange('1.234,56')
    expect($assignment.find('.what_if_score').text()).toBe('654321')
  })

  it('uses the previous .what_if_score value when #grade_entry is blank', () => {
    $assignment.find('.what_if_score').text('9.0')
    onScoreChange('')
    expect($assignment.find('.what_if_score').text()).toBe('9')
  })

  it('uses I18n to parse the previous .what_if_score value', () => {
    jest.spyOn(numberHelper, 'parse').mockReturnValue('654321')
    $assignment.find('.what_if_score').text('9.0')
    onScoreChange('')
    expect($assignment.find('.what_if_score').text()).toBe('654321')
  })

  it('removes the .dont_update class from the .student_assignment element when present', () => {
    $assignment.addClass('dont_update')
    onScoreChange('5')
    expect($assignment.hasClass('dont_update')).toBe(false)
  })

  it('saves the "What-If" grade using the api', () => {
    onScoreChange('5', {update: true})
    expect($.ajaxJSON).toHaveBeenCalledTimes(1)
    const [url, method, params] = $.ajaxJSON.mock.calls[0]
    expect(url).toBe('/assignments/201')
    expect(method).toBe('PUT')
    expect(params['submission[student_entered_score]']).toBe(5)
  })

  it('updates the .student_entered_score element upon success api update', () => {
    $.ajaxJSON.mockImplementation((_url, _method, args, onSuccess) => {
      onSuccess({submission: {student_entered_score: args['submission[student_entered_score]']}})
    })
    onScoreChange('5', {update: true})
    expect($assignment.find('.student_entered_score').text()).toBe('5')
  })

  it('does not save the "What-If" grade when .dont_update class is present', () => {
    $assignment.addClass('dont_update')
    onScoreChange('5', {update: true})
    expect($.ajaxJSON).not.toHaveBeenCalled()
  })

  it('does not save the "What-If" grade when the "update" option is false', () => {
    onScoreChange('5', {update: false})
    expect($.ajaxJSON).not.toHaveBeenCalled()
  })

  it('hides the #grade_entry input', () => {
    onScoreChange('5')
    expect($('#grade_entry').is(':hidden')).toBe(true)
  })

  it('moves the #grade_entry to the body', () => {
    onScoreChange('5')
    expect($('#grade_entry').parent().is('body')).toBe(true)
  })

  it('sets the .assignment_score title to ""', () => {
    onScoreChange('5')
    expect($assignment.find('.assignment_score').attr('title')).toBe('')
  })

  it('sets the .assignment_score teaser text', () => {
    onScoreChange('5')
    expect($assignment.find('.score_teaser').text()).toBe('This is a What-If score')
  })

  it('copies the "revert score" link into the .score_holder element', () => {
    onScoreChange('5')
    const $revertLink = $assignment.find('.score_holder .revert_score_link')
    expect($revertLink).toHaveLength(1)
    expect($revertLink.text()).toBe('Revert Score')
  })

  it('adds the "changed" class to the .grade element', () => {
    onScoreChange('5')
    expect($assignment.find('.grade').hasClass('changed')).toBe(true)
  })

  it('sets the .grade element content to the updated score', () => {
    onScoreChange('5')
    const gradeText = $assignment.find('.grade').text()
    expect(gradeText).toContain('5')
  })

  it('sets the .grade element content to the previous score when the updated score is falsy', () => {
    $assignment.find('.grade').data('originalValue', '10.0')
    onScoreChange('')
    const gradeText = $assignment.find('.grade').text()
    expect(gradeText).toContain('10')
  })

  it('updates the score for the given assignment', () => {
    onScoreChange('5')
    expect(GradeSummary.updateScoreForAssignment).toHaveBeenCalledTimes(1)
    const [assignmentId, score] = GradeSummary.updateScoreForAssignment.mock.calls[0]
    expect(assignmentId).toBe('201')
    expect(score).toBe(5)
  })
})
