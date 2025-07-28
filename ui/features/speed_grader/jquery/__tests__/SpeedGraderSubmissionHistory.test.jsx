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

import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import SpeedGrader from '../speed_grader'
import '@canvas/jquery/jquery.ajaxJSON'

describe('SpeedGrader Submission History', () => {
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
    <div id="submission_details">
      <div id="speed_grader_submission_status_container">
        <div class="submission-custom-grade-status-pill-1">Custom Status</div>
      </div>
      <select id="multiple_submissions"></select>
    </div>
  `

  let fixtures

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = requiredDOMFixtures

    fakeENV.setup({
      assignment_id: '27',
      course_id: '3',
      help_url: '',
      show_help_menu_item: false,
      RUBRIC_ASSESSMENT: {},
      assignment: {
        assignment_id: '27',
        course_id: '3',
      },
      custom_grade_statuses: [
        {
          id: '1',
          name: 'Custom Status',
        },
      ],
    })

    window.jsonData = {
      studentsWithSubmissions: [],
      context: {
        active_course_sections: [],
        enrollments: [],
        students: [],
      },
    }

    SpeedGrader.setup()

    // Initialize currentStudent with submission history
    SpeedGrader.EG.currentStudent = {
      id: 4,
      submission: {
        score: 7,
        grade: 70,
        custom_grade_status_id: '1',
        custom_grade_status: {
          id: '1',
          name: 'Custom Status',
        },
        submission_history: [
          {
            submission_type: 'online_text_entry',
            submitted_at: '2019-01-01T00:00:00Z',
            custom_grade_status_id: '1',
            custom_grade_status: {
              id: '1',
              name: 'Custom Status',
            },
          },
          {
            submission_type: 'online_text_entry',
            submitted_at: '2019-01-02T00:00:00Z',
            custom_grade_status_id: '1',
            custom_grade_status: {
              id: '1',
              name: 'Custom Status',
            },
          },
        ],
      },
    }
  })

  afterEach(() => {
    SpeedGrader.teardown()
    fixtures.remove()
    fakeENV.teardown()
    delete window.jsonData
  })

  it('handles non-nested submission history', () => {
    SpeedGrader.EG.refreshSubmissionsToView()
    const submissionDropdown = document.getElementById('multiple_submissions')
    expect(submissionDropdown.innerHTML).not.toContain('Jan 1, 2010')
  })

  it('displays proxy submitter when present (multiple submissions)', () => {
    const history_ = SpeedGrader.EG.currentStudent.submission.submission_history.map(h => ({
      ...h,
      proxy_submitter: 'George Washington',
    }))
    SpeedGrader.EG.currentStudent.submission.submission_history = history_
    SpeedGrader.EG.refreshSubmissionsToView()
    const submissionDropdown = document.getElementById('multiple_submissions')
    expect(submissionDropdown.innerHTML).toContain('(George Washington)')
  })

  it('displays proxy submitter when present (single submission)', () => {
    const firstHistory = SpeedGrader.EG.currentStudent.submission.submission_history[0]
    firstHistory.proxy_submitter = 'Mike Tyson'
    SpeedGrader.EG.currentStudent.submission.submission_history = [firstHistory]
    SpeedGrader.EG.refreshSubmissionsToView()
    const submissionDropdown = document.getElementById('multiple_submissions')
    expect(submissionDropdown.innerHTML).toContain('by Mike Tyson')
  })

  it('sets submission history container to empty when history is blank', () => {
    SpeedGrader.EG.refreshSubmissionsToView()
    SpeedGrader.EG.currentStudent.submission.submission_history = []
    SpeedGrader.EG.refreshSubmissionsToView()
    const submissionDropdown = document.getElementById('multiple_submissions')
    expect(submissionDropdown.innerHTML).toBe('')
  })

  it('shows custom status pill when no submissions', () => {
    SpeedGrader.EG.currentStudent.submission.custom_grade_status_id = '1'
    SpeedGrader.EG.currentStudent.submission.attempt = null
    SpeedGrader.EG.currentStudent.submission.submission_history = [
      {
        custom_grade_status_id: '1',
        attempt: null,
      },
    ]
    SpeedGrader.EG.refreshSubmissionsToView()
    const submissionPill = document.querySelector('.submission-custom-grade-status-pill-1')
    expect(submissionPill).toBeTruthy()
    expect(submissionPill.innerText).toBe('Custom Status')
  })

  it('does not tag first non-late submission as late in dropdown', () => {
    SpeedGrader.EG.currentStudent.submission.late = true
    SpeedGrader.EG.currentStudent.submission.submission_history[1].late = true
    SpeedGrader.EG.refreshSubmissionsToView()
    const submissionDropdown = document.getElementById('multiple_submissions')
    const firstSubmission = submissionDropdown.getElementsByTagName('option')[0]
    expect(firstSubmission.innerHTML).not.toContain('LATE')
  })

  it('does not tag first non-missing submission as missing in dropdown', () => {
    SpeedGrader.EG.currentStudent.submission.missing = true
    SpeedGrader.EG.currentStudent.submission.submission_history[1].missing = true
    SpeedGrader.EG.refreshSubmissionsToView()
    const submissionDropdown = document.getElementById('multiple_submissions')
    const firstSubmission = submissionDropdown.getElementsByTagName('option')[0]
    expect(firstSubmission.innerHTML).not.toContain('MISSING')
  })

  it('tags submission with custom status in dropdown', () => {
    SpeedGrader.EG.currentStudent.submission.custom_grade_status = {
      id: '1',
      name: 'Custom Status',
    }
    SpeedGrader.EG.currentStudent.submission.custom_grade_status_id = '1'
    SpeedGrader.EG.currentStudent.submission.submission_history[0].custom_grade_status = {
      id: '1',
      name: 'Custom Status',
    }
    SpeedGrader.EG.currentStudent.submission.submission_history[0].custom_grade_status_id = '1'
    SpeedGrader.EG.currentStudent.submission.submission_history[1].custom_grade_status = {
      id: '1',
      name: 'Custom Status',
    }
    SpeedGrader.EG.currentStudent.submission.submission_history[1].custom_grade_status_id = '1'
    SpeedGrader.EG.refreshSubmissionsToView()
    const submissionDropdown = document.getElementById('multiple_submissions')
    const firstSubmission = submissionDropdown.getElementsByTagName('option')[0]
    expect(firstSubmission.innerHTML).toContain('CUSTOM STATUS')
  })
})
