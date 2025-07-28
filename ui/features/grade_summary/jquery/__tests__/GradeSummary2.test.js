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
import 'jquery-migrate'
import {useScope as createI18nScope} from '@canvas/i18n'
import fakeENV from '@canvas/test-utils/fakeENV'
import GradeSummary from '../index'

const I18n = createI18nScope('gradingGradeSummary')

describe('GradeSummary', () => {
  let $fixtures

  const createAssignmentGroups = () => [
    {
      id: '301',
      assignments: [
        {id: '201', muted: false, points_possible: 20},
        {id: '202', muted: true, points_possible: 20},
      ],
    },
    {id: '302', assignments: [{id: '203', muted: true, points_possible: 20}]},
  ]

  const createSubmissions = () => [{assignment_id: '201', score: 10}]

  const createExampleGrades = () => ({
    assignmentGroups: {},
    current: {
      score: 23,
      possible: 100,
    },
    final: {
      score: 89.98,
      possible: 100,
    },
  })

  const setPageHtmlFixture = () => {
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
            <span class="status"></span>
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
        </table>
      </div>
    `
  }

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)
    fakeENV.setup({grade_calc_ignore_unposted_anonymous_enabled: true})
  })

  afterEach(() => {
    fakeENV.teardown()
    $fixtures.remove()
    jest.clearAllMocks()
  })

  describe('getOriginalScore', () => {
    let $assignment

    beforeEach(() => {
      setPageHtmlFixture()
      ENV.submissions = createSubmissions()
      ENV.assignment_groups = createAssignmentGroups()
      ENV.group_weighting_scheme = 'points'
      GradeSummary.setup()
      $assignment = $($fixtures).find('#grades_summary .student_assignment').first()
    })

    it('parses the text of the .original_points element', () => {
      const score = GradeSummary.getOriginalScore($assignment)
      expect(score.numericalValue).toBe(10)
      expect(score.formattedValue).toBe('10')
    })

    it('sets "numericalValue" to a default of null', () => {
      $assignment.find('.original_points').text('invalid')
      const score = GradeSummary.getOriginalScore($assignment)
      expect(score.numericalValue).toBeNull()
    })

    it('sets "formattedValue" to formatted grade', () => {
      $assignment.find('.original_score').text('C+ (78.5)')
      const score = GradeSummary.getOriginalScore($assignment)
      expect(score.formattedValue).toBe('C+ (78.5)')
    })
  })

  describe('calculateTotals', () => {
    const screenReaderFlashMock = jest.fn()

    beforeEach(() => {
      ENV.assignment_groups = createAssignmentGroups()
      $.screenReaderFlashMessageExclusive = screenReaderFlashMock
      setPageHtmlFixture()
      ENV.grading_scheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['F', 0],
      ]
    })

    it('displays a screenreader-only alert when grades have been changed', () => {
      $($fixtures).find('.assignment_score .grade').addClass('changed')
      GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
      expect(screenReaderFlashMock).toHaveBeenCalledTimes(1)
      const messageText = screenReaderFlashMock.mock.calls[0][0]
      expect(messageText).toContain('the new total is now')
    })

    // suppressed assignments are meant to be hidden from the gradebook, but still counted towards the final grade
    it('displays the correct grade when there are suppressed assignments', () => {
      ENV = {
        ...ENV,
        SETTINGS: {suppress_assignments: true},
      }
      ENV.assignment_groups = createAssignmentGroups()
      ENV.assignment_groups[0].assignments[0].suppress_assignment = true
      GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
      const $grade = $($fixtures).find('.final_grade .grade')
      expect($grade.text()).toBe('23%')
    })

    it('does not display a screenreader-only alert when grades have not been changed', () => {
      GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
      expect(screenReaderFlashMock).not.toHaveBeenCalled()
    })

    it('localizes displayed grade', () => {
      jest.spyOn(I18n.constructor.prototype, 'n').mockReturnValue('1,234')
      GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
      const $teaser = $($fixtures).find('.student_assignment.final_grade .score_teaser')
      expect($teaser.text()).toContain('1,234')
    })

    describe('final grade override', () => {
      beforeEach(() => {
        const grades = createExampleGrades()
        grades.current = {score: 23, possible: 100}
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

      it('sets the letter grade to the effective grade', () => {
        ENV.effective_final_score = 72
        GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
        const $grade = $($fixtures).find('.final_grade .letter_grade')
        expect($grade.text()).toBe('C')
      })

      it('sets the percent grade to the calculated percent grade, if overrides not present', () => {
        const grades = createExampleGrades()
        GradeSummary.calculateTotals(grades, 'current', 'percent')
        const $grade = $($fixtures).find('.final_grade .grade').first()
        expect($grade.text()).toBe('23%')
      })

      it('sets the letter grade to the calculated letter grade, if overrides not present', () => {
        const grades = createExampleGrades()
        GradeSummary.calculateTotals(grades, 'current', 'percent')
        const $grade = $($fixtures).find('.final_grade .letter_grade')
        expect($grade.text()).toBe('F')
      })

      it('changed What-If scores take precedence over the effective grade', () => {
        ENV.effective_final_score = 72
        const grades = createExampleGrades()
        grades.current = {score: 3, possible: 10}
        const changedGrade = '<span class="grade changed">3</span>'
        $($fixtures).find('.score_holder .tooltip').html(changedGrade)
        GradeSummary.calculateTotals(grades, 'current', 'percent')
        const $grade = $($fixtures).find('.final_grade .grade').first()
        expect($grade.text()).toBe('30%')
      })

      it('override score of 0 results in a 0%', () => {
        ENV.effective_final_score = 0
        GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
        const $grade = $($fixtures).find('.final_grade .grade').first()
        expect($grade.text()).toBe('0%')
      })

      it('override score of 0 results in an F letter grade', () => {
        ENV.effective_final_score = 0
        GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
        const $grade = $($fixtures).find('.final_grade .letter_grade').first()
        expect($grade.text()).toBe('F')
      })

      it('when a grading scheme is not present, but an override is, the raw override score is shown', () => {
        delete ENV.grading_scheme
        ENV.effective_final_score = 72
        GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
        const $grade = $($fixtures).find('.final_grade .grade').first()
        expect($grade.text()).toBe('72%')
      })

      it('when the .letter_grade span is not present, the raw override score is shown', () => {
        $('.final_grade .letter_grade').remove()
        ENV.effective_final_score = 72
        GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
        const $grade = $($fixtures).find('.final_grade .grade').first()
        expect($grade.text()).toBe('72%')
      })

      it('when there is a custom status in the ENV, renders a status pill span class', () => {
        ENV.final_override_custom_grade_status_id = '42'
        ENV.effective_final_score = 84
        GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
        const $status = $($fixtures).find('.final_grade .status')
        $status.html('<span class="submission-custom-grade-status-pill-42"></span>')
        expect($status.children().first().length).toBeTruthy()
        expect(
          $status.children().first().hasClass('submission-custom-grade-status-pill-42'),
        ).toBeTruthy()
      })

      it('when the custom status has allow_final_grade_value equal to false it will display the grade as "-"', () => {
        ENV.final_override_custom_grade_status_id = '42'
        ENV.effective_final_score = 84
        ENV.custom_grade_statuses = [
          {id: '42', title: 'Custom Status', allow_final_grade_value: false},
        ]
        GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
        const $status = $($fixtures).find('.final_grade .status')
        $status.html('<span class="submission-custom-grade-status-pill-42"></span>')
        expect($status.children().first().length).toBeTruthy()
        const $grade = $($fixtures).find('.final_grade .grade').first()
        expect($grade.text()).toBe('-')
      })
    })

    describe('points based grading scheme', () => {
      beforeEach(() => {
        const grades = createExampleGrades()
        grades.current = {score: 89.98, possible: 100}
        grades.final = {score: 89.98, possible: 100}
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

      it('when points based grading scheme is in use the letter score is based off the scaled final score', () => {
        GradeSummary.calculateTotals(createExampleGrades(), 'current', null)
        const $letterGrade = $($fixtures).find('.final_grade .letter_grade')
        $letterGrade.text('A')
        expect($letterGrade.text()).toBe('A')
      })
    })
  })
})
