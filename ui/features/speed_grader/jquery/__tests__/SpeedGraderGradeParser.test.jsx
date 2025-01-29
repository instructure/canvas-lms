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
import SpeedGrader from '../speed_grader'

describe('SpeedGrader Grade Parser', () => {
  beforeEach(() => {
    // Set up DOM elements
    document.body.innerHTML = `
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

    // Set up ENV
    fakeENV.setup({
      assignment_id: '27',
      course_id: '3',
      help_url: '',
      show_help_menu_item: false,
      RUBRIC_ASSESSMENT: {},
      force_anonymous_grading: false,
    })

    // Initialize SpeedGrader
    SpeedGrader.setup()
  })

  afterEach(() => {
    document.body.innerHTML = ''
    fakeENV.teardown()
  })

  describe('shouldParseGrade', () => {
    it('returns true when grading type is percent', () => {
      ENV.grading_type = 'percent'
      const result = SpeedGrader.EG.shouldParseGrade()
      expect(result).toBe(true)
    })

    it('returns true when grading type is points', () => {
      ENV.grading_type = 'points'
      const result = SpeedGrader.EG.shouldParseGrade()
      expect(result).toBe(true)
    })

    it('returns false when grading type is neither percent nor points', () => {
      ENV.grading_type = 'foo'
      const result = SpeedGrader.EG.shouldParseGrade()
      expect(result).toBe(false)
    })
  })
})
