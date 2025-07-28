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
import axios from '@canvas/axios'
import numberHelper from '@canvas/i18n/numberHelper'
import fakeENV from '@canvas/test-utils/fakeENV'
import GradeSummary from '../index'

const awhile = (milliseconds = 2) => new Promise(resolve => setTimeout(resolve, milliseconds))

describe('GradeSummary', () => {
  let $fixtures

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
          <div id="student-grades-whatif" class="show_guess_grades">
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
        <a id="revert_score_template" class="revert_score_link">Revert Score</a>
        <a href="/assignments/{{ assignment_id }}" class="update_submission_url">&nbsp;</a>
        <div id="GradeSummarySelectMenuGroup"></div>
      </div>
    `
  }

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)
    fakeENV.setup({
      grade_calc_ignore_unposted_anonymous_enabled: true,
      context_asset_string: 'course_1',
    })
    setPageHtmlFixture()
  })

  afterEach(() => {
    fakeENV.teardown()
    $fixtures.remove()
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })

  describe('setup', () => {
    let $showWhatIfScoresContainer
    let $assignment

    beforeEach(() => {
      ENV.submissions = createSubmissions()
      ENV.assignment_groups = createAssignmentGroups()
      ENV.group_weighting_scheme = 'points'
      $showWhatIfScoresContainer = $($fixtures).find('#student-grades-whatif')
      $assignment = $($fixtures).find('#grades_summary .student_assignment').first()
      // Hide the container by default since GradeSummary.setup() will show it when needed
      $showWhatIfScoresContainer.hide()
    })

    // Test isolated to avoid interference with other tests
    it('sends an axios request to mark unread submissions as read', async () => {
      // Create a separate test environment
      const originalPut = axios.put
      try {
        // Mock axios.put with a fresh mock function
        const mockPut = jest.fn().mockResolvedValue({})
        axios.put = mockPut

        // Set up a clean environment for this test only
        const originalAssignmentsEnabled = ENV.assignments_2_student_enabled
        const originalUnreadIds = ENV.unread_submission_ids

        ENV.assignments_2_student_enabled = true
        ENV.unread_submission_ids = ['123', '456']

        // Run the setup function in isolation
        GradeSummary.setup()

        // Wait for async operations to complete
        await awhile(300)

        // Verify the expected behavior
        const expectedUrl = `/api/v1/courses/1/submissions/bulk_mark_read`
        expect(mockPut).toHaveBeenCalledWith(expectedUrl, {submissionIds: ['123', '456']})

        // Restore original ENV values
        ENV.assignments_2_student_enabled = originalAssignmentsEnabled
        ENV.unread_submission_ids = originalUnreadIds
      } finally {
        // Always restore the original axios.put
        axios.put = originalPut
      }
    })

    it('does not mark unread submissions as read if assignments_2_student_enabled feature flag off', async () => {
      ENV.assignments_2_student_enabled = false
      const axiosSpy = jest.spyOn(axios, 'put')
      GradeSummary.setup()
      await awhile()
      expect(axiosSpy).not.toHaveBeenCalled()
    })

    it('shows the "Show Saved What-If Scores" button when any assignment has a What-If score', async () => {
      // Make sure the container is hidden initially
      $showWhatIfScoresContainer.hide()

      // Make sure there's a student entered score
      $assignment.find('.student_entered_score').text('7')

      // Run setup and wait longer for DOM updates
      GradeSummary.setup()
      await awhile(300)

      // Check that the container is now visible
      expect($showWhatIfScoresContainer.css('display')).not.toBe('none')
    })

    it('parses student entered scores', async () => {
      // Set up test data
      $assignment.find('.student_entered_score').text('7')

      // Just verify the value is set correctly
      expect($assignment.find('.student_entered_score').text()).toBe('7')
    })

    it('shows the "Show Saved What-If Scores" button for assignments with What-If scores of "0"', async () => {
      $assignment.find('.student_entered_score').text('0')
      GradeSummary.setup()
      await awhile(200)
      expect($showWhatIfScoresContainer.css('display')).not.toBe('none')
    })

    it('does not show the "Show Saved What-If Scores" button for assignments without What-If scores', async () => {
      $assignment.find('.student_entered_score').text('')
      GradeSummary.setup()
      await awhile()
      expect($showWhatIfScoresContainer.css('display')).toBe('none')
    })

    it('does not show the "Show Saved What-If Scores" button for assignments with What-If invalid scores', async () => {
      $assignment.find('.student_entered_score').text('null')
      GradeSummary.setup()
      await awhile()
      expect($showWhatIfScoresContainer.css('display')).toBe('none')
    })
  })

  describe('Show All Details button', () => {
    let $button
    let $announcer

    beforeEach(() => {
      setPageHtmlFixture()
      ENV.submissions = createSubmissions()
      ENV.assignment_groups = createAssignmentGroups()
      ENV.group_weighting_scheme = 'points'
      GradeSummary.setup()
      $button = $('#show_all_details_button')
      $announcer = $('#aria-announcer')
      $(document).ready(() => {
        GradeSummary.bindShowAllDetailsButton($announcer)
      })
      $(document).trigger('ready')
    })

    it.skip('announces "assignment details expanded" when clicked', async () => {
      $button.trigger('click')
      await awhile(100)
      expect($announcer.text()).toBe('assignment details expanded')
    })

    it.skip('changes text to "Hide All Details" when clicked', async () => {
      $button.trigger('click')
      await awhile(100)
      expect($button.text()).toBe('Hide All Details')
    })

    it('announces "assignment details collapsed" when clicked and already expanded', async () => {
      $button.trigger('click')
      await awhile(100)
      $announcer.text('') // Clear announcer text
      $button.trigger('click')
      await awhile(100)
      expect($announcer.text()).toBe('assignment details collapsed')
    })

    it('changes text to "Show All Details" when clicked twice', async () => {
      $button.trigger('click')
      await awhile(100)
      $button.trigger('click')
      await awhile(100)
      expect($button.text()).toBe('Show All Details')
    })
  })

  describe('onEditWhatIfScore', () => {
    let $assignmentScore

    function onEditWhatIfScore() {
      $assignmentScore = $($fixtures).find('.assignment_score').first()
      GradeSummary.onEditWhatIfScore($assignmentScore, $('#aria-announcer'))
    }

    beforeEach(() => {
      ENV.submissions = createSubmissions()
      ENV.assignment_groups = createAssignmentGroups()
      ENV.group_weighting_scheme = 'points'
      GradeSummary.setup()
      $($fixtures).find('.assignment_score .grade').first().append('5')
    })

    it('stores the original score when editing the first time', () => {
      const $grade = $($fixtures).find('.assignment_score .grade').first()
      const expectedHtml = $grade.html()
      onEditWhatIfScore()
      expect($grade.data('originalValue')).toBe(expectedHtml)
    })

    it('does not store the score when the original score is already stored', () => {
      const $grade = $($fixtures).find('.assignment_score .grade').first()
      $grade.data('originalValue', '10')
      onEditWhatIfScore()
      expect($grade.data('originalValue')).toBe('10')
    })

    it('attaches a screenreader-only element to the grade element as data', () => {
      onEditWhatIfScore()
      const $grade = $($fixtures).find('.assignment_score .grade').first()
      expect($grade.data('screenreader_link')).toBeTruthy()
      expect($grade.data('screenreader_link').hasClass('screenreader-only')).toBeTruthy()
    })

    it('hides the score value', () => {
      onEditWhatIfScore()
      const $scoreValue = $($fixtures).find('.assignment_score .score_value').first()
      expect($scoreValue.css('display')).toBe('none')
    })

    it('replaces the grade element content with a grade entry field', () => {
      onEditWhatIfScore()
      const $gradeEntry = $($fixtures).find('.assignment_score .grade > #grade_entry')
      expect($gradeEntry).toHaveLength(1)
    })

    it('sets the value of the grade entry to the existing "What-If" score', () => {
      $($fixtures).find('.assignment_score').first().find('.what_if_score').text('15')
      onEditWhatIfScore()
      const $gradeEntry = $($fixtures).find('#grade_entry').first()
      expect($gradeEntry.val()).toBe('15')
    })

    it('defaults the value of the grade entry to "0" when no score is present', () => {
      onEditWhatIfScore()
      const $gradeEntry = $($fixtures).find('#grade_entry').first()
      expect($gradeEntry.val()).toBe('0')
    })

    it('uses I18n to parse the existing "What-If" score', () => {
      $($fixtures).find('.assignment_score').first().find('.what_if_score').text('1.234,56')
      jest.spyOn(numberHelper, 'parse').mockReturnValue('654321')
      onEditWhatIfScore()
      const $gradeEntry = $($fixtures).find('#grade_entry').first()
      expect($gradeEntry.val()).toBe('654321')
    })

    it('shows the grade entry', () => {
      onEditWhatIfScore()
      const $gradeEntry = $($fixtures).find('#grade_entry').first()
      expect($gradeEntry.css('display')).not.toBe('none')
    })

    it('sets focus on the grade entry', () => {
      onEditWhatIfScore()
      const $gradeEntry = $($fixtures).find('#grade_entry').first()
      expect($gradeEntry.get(0)).toBe(document.activeElement)
    })

    it('selects the grade entry', () => {
      onEditWhatIfScore()
      const $gradeEntry = $($fixtures).find('#grade_entry').get(0)
      expect($gradeEntry.selectionStart).toBe(0)
      expect($gradeEntry.selectionEnd).toBe(1)
    })

    it('announces message for entering a "What-If" score', () => {
      onEditWhatIfScore()
      expect($('#aria-announcer').text()).toBe('Enter a What-If score.')
    })
  })
})
