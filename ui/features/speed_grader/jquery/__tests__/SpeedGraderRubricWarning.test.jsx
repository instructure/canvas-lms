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

import fakeENV from '@canvas/test-utils/fakeENV'
import $ from 'jquery'
import SpeedGrader from '../speed_grader'

describe('SpeedGrader Rubric Warning', () => {
  let fixtures

  const requiredDOMFixtures = `
    <div id="hide-assignment-grades-tray"></div>
    <div id="post-assignment-grades-tray"></div>
    <div id="speed_grader_assessment_audit_tray_mount_point"></div>
    <span id="speed_grader_post_grades_menu_mount_point"></span>
    <span id="speed_grader_settings_mount_point"></span>
    <div id="speed_grader_rubric_assessment_tray_wrapper"><div>
    <div id="speed_grader_assessment_audit_button_mount_point"></div>
    <div id="speed_grader_submission_comments_download_mount_point"></div>
    <div id="speed_grader_hidden_submission_pill_mount_point"></div>
    <div id="grades-loading-spinner"></div>
    <div id="grading"></div>
    <div id="settings_form">
      <select id="eg_sort_by" name="eg_sort_by">
        <option value="alphabetically"></option>
        <option value="submitted_at"></option>
        <option value="submission_status"></option>
        <option value="randomize"></option>
      </select>
      <input id="hide_student_names" type="checkbox" name="hide_student_names">
      <input id="enable_speedgrader_grade_by_question" type="checkbox" name="enable_speedgrader_grade_by_question">
      <button type="submit" class="submit_button"></button>
    </div>
  `

  const setupFixtures = (domStrings = '') => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = `${requiredDOMFixtures}${domStrings}`
    return fixtures
  }

  const teardownFixtures = () => {
    fixtures?.remove()
  }

  beforeEach(() => {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      RUBRIC_ASSESSMENT: {},
      rubric: {
        criteria: [
          {
            points: 5,
            id: '123',
            criterion_use_range: false,
            ratings: [
              {points: 5, criterion_id: '123', id: '1'},
              {points: 0, criterion_id: '123', id: '2'},
            ],
            long_description: '',
          },
        ],
        points_possible: 5,
        title: 'Homework 1',
        free_form_criterion_comments: false,
      },
      nonScoringRubrics: true,
    })

    setupFixtures(`
      <div id="rubric_full">
        <div id="rubric_holder">
          <div class="rubric assessing"></div>
          <button class='save_rubric_button'></button>
        </div>
      </div>
    `)

    window.jsonData = {
      rubric_association: {},
    }
  })

  afterEach(() => {
    teardownFixtures()
    fakeENV.teardown()
    delete window.jsonData
  })

  describe('hasUnsubmittedRubric', () => {
    it('returns false when rubric has no unsaved changes', () => {
      const $container = $('#rubric_full').find('.rubric')

      // Initial assessment
      const assessment = {
        data: [{criterion_id: '123', points: 4}],
      }
      $('#rubric_full').hide()
      window.rubricAssessment.populateNewRubric($container, assessment)
      const originalRubric = SpeedGrader.EG.getOriginalRubricInfo()

      // Same assessment
      const unchangedAssessment = {
        data: [{criterion_id: '123', points: 4}],
      }
      window.rubricAssessment.populateNewRubric($container, unchangedAssessment)
      $('#rubric_full').show()

      expect(SpeedGrader.EG.hasUnsubmittedRubric(originalRubric)).toBe(false)
    })
  })
})
