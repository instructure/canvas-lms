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
import {registerFixDialogButtonsPlugin} from '@canvas/enhanced-user-content/jquery'
import fakeENV from '@canvas/test-utils/fakeENV'
import SpeedGrader from '../speed_grader'
import '@canvas/jquery/jquery.ajaxJSON'

describe('SpeedGrader Quiz History Link', () => {
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
      <div id="speed_grader_submission_status_container"></div>
      <div id="multiple_submissions"></div>
    </div>
  `

  let fixtures

  beforeAll(() => {
    registerFixDialogButtonsPlugin()
  })

  beforeEach(() => {
    vi.useFakeTimers()

    // Mock XMLHttpRequest to prevent connection errors
    const mockXHR = {
      open: vi.fn(),
      send: vi.fn(),
      setRequestHeader: vi.fn(),
      abort: vi.fn(),
      readyState: 4,
      status: 200,
      responseText: '',
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }
    global.XMLHttpRequest = vi.fn(() => mockXHR)

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
      quiz_history_url: '/courses/3/quizzes/1/history?user_id={{user_id}}',
    })

    window.jsonData = {
      studentsWithSubmissions: [],
      context: {
        active_course_sections: [],
        enrollments: [],
        students: [],
      },
      too_many_quiz_submissions: false,
    }

    SpeedGrader.setup()
  })

  afterEach(async () => {
    await vi.runAllTimersAsync()
    SpeedGrader.teardown()
    fixtures.remove()
    fakeENV.teardown()
    delete window.jsonData
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  describe('when too_many_quiz_submissions is true', () => {
    beforeEach(() => {
      window.jsonData.too_many_quiz_submissions = true
    })

    it('shows the quiz history link when student has actual submissions', () => {
      SpeedGrader.EG.currentStudent = {
        id: '4',
        name: 'Test Student',
        avatar_path: null,
        submission: {
          user_id: '4',
          submitted_at: '2024-01-02T10:00:00Z',
          submission_history: [
            {
              submission_type: 'online_quiz',
              submitted_at: '2024-01-01T10:00:00Z',
              grade: 85,
            },
            {
              submission_type: 'online_quiz',
              submitted_at: '2024-01-02T10:00:00Z',
              grade: 90,
            },
          ],
        },
      }

      SpeedGrader.EG.refreshSubmissionsToView()
      const submissionContainer = document.getElementById('multiple_submissions')
      expect(submissionContainer.innerHTML).toContain('See all quiz attempts')
      expect(submissionContainer.querySelector('.see-all-attempts')).toBeTruthy()
    })

    it('hides the quiz history link when student has no actual submissions (all submitted_at are null)', () => {
      SpeedGrader.EG.currentStudent = {
        id: '4',
        name: 'Test Student',
        avatar_path: null,
        submission: {
          user_id: '4',
          submission_history: [
            {
              submission_type: 'online_quiz',
              submitted_at: null,
              grade: null,
            },
          ],
        },
      }

      SpeedGrader.EG.refreshSubmissionsToView()
      const submissionContainer = document.getElementById('multiple_submissions')
      expect(submissionContainer.innerHTML).not.toContain('See all quiz attempts')
      expect(submissionContainer.querySelector('.see-all-attempts')).toBeFalsy()
    })

    it('shows the quiz history link when at least one submission has submitted_at', () => {
      SpeedGrader.EG.currentStudent = {
        id: '4',
        name: 'Test Student',
        avatar_path: null,
        submission: {
          user_id: '4',
          submitted_at: '2024-01-02T10:00:00Z',
          submission_history: [
            {
              submission_type: 'online_quiz',
              submitted_at: null,
              grade: null,
            },
            {
              submission_type: 'online_quiz',
              submitted_at: '2024-01-02T10:00:00Z',
              grade: 90,
            },
          ],
        },
      }

      SpeedGrader.EG.refreshSubmissionsToView()
      const submissionContainer = document.getElementById('multiple_submissions')
      expect(submissionContainer.innerHTML).toContain('See all quiz attempts')
      expect(submissionContainer.querySelector('.see-all-attempts')).toBeTruthy()
    })

    it('handles nested submission structure', () => {
      SpeedGrader.EG.currentStudent = {
        id: '4',
        name: 'Test Student',
        avatar_path: null,
        submission: {
          user_id: '4',
          submitted_at: '2024-01-01T10:00:00Z',
          submission_history: [
            {
              submission: {
                submission_type: 'online_quiz',
                submitted_at: '2024-01-01T10:00:00Z',
                grade: 85,
              },
            },
          ],
        },
      }

      SpeedGrader.EG.refreshSubmissionsToView()
      const submissionContainer = document.getElementById('multiple_submissions')
      expect(submissionContainer.innerHTML).toContain('See all quiz attempts')
      expect(submissionContainer.querySelector('.see-all-attempts')).toBeTruthy()
    })

    it('hides the quiz history link for nested submission structure with no submitted_at', () => {
      SpeedGrader.EG.currentStudent = {
        id: '4',
        name: 'Test Student',
        avatar_path: null,
        submission: {
          user_id: '4',
          submission_history: [
            {
              submission: {
                submission_type: 'online_quiz',
                submitted_at: null,
                grade: null,
              },
            },
          ],
        },
      }

      SpeedGrader.EG.refreshSubmissionsToView()
      const submissionContainer = document.getElementById('multiple_submissions')
      expect(submissionContainer.innerHTML).not.toContain('See all quiz attempts')
      expect(submissionContainer.querySelector('.see-all-attempts')).toBeFalsy()
    })
  })

  describe('when too_many_quiz_submissions is false', () => {
    beforeEach(() => {
      window.jsonData.too_many_quiz_submissions = false
    })

    it('hides the quiz history link even when student has submissions', () => {
      SpeedGrader.EG.currentStudent = {
        id: '4',
        name: 'Test Student',
        avatar_path: null,
        submission: {
          user_id: '4',
          submission_history: [
            {
              submission_type: 'online_quiz',
              submitted_at: '2024-01-01T10:00:00Z',
              grade: 85,
            },
          ],
        },
      }

      SpeedGrader.EG.refreshSubmissionsToView()
      const submissionContainer = document.getElementById('multiple_submissions')
      expect(submissionContainer.innerHTML).not.toContain('See all quiz attempts')
      expect(submissionContainer.querySelector('.see-all-attempts')).toBeFalsy()
    })
  })

  describe('when student has no submission history', () => {
    it('does not show the quiz history link', () => {
      window.jsonData.too_many_quiz_submissions = true
      SpeedGrader.EG.currentStudent = {
        id: '4',
        name: 'Test Student',
        avatar_path: null,
        submission: {
          user_id: '4',
          submission_history: [],
        },
      }

      SpeedGrader.EG.refreshSubmissionsToView()
      const submissionContainer = document.getElementById('multiple_submissions')
      expect(submissionContainer.innerHTML).toBe('')
    })

    it('does not show the quiz history link when submission history is undefined', () => {
      window.jsonData.too_many_quiz_submissions = true
      SpeedGrader.EG.currentStudent = {
        id: '4',
        name: 'Test Student',
        avatar_path: null,
        submission: {
          user_id: '4',
        },
      }

      SpeedGrader.EG.refreshSubmissionsToView()
      const submissionContainer = document.getElementById('multiple_submissions')
      expect(submissionContainer.innerHTML).toBe('')
    })
  })
})
