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
import {allowsReassignment} from '../speed_grader.utils'
import SpeedGrader from '../speed_grader'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('../speed_grader.utils', () => ({
  allowsReassignment: jest.fn(),
  teardownSettingsMenu: jest.fn(),
  renderSettingsMenu: jest.fn(),
  teardownHandleStatePopped: jest.fn(),
  tearDownAssessmentAuditTray: jest.fn(),
  renderPostGradesMenu: jest.fn(),
}))

describe('SpeedGrader Submission Details', () => {
  const requiredDOMFixtures = `
    <div id="hide-assignment-grades-tray"></div>
    <div id="post-assignment-grades-tray"></div>
    <div id="speed_grader_assessment_audit_tray_mount_point"></div>
    <span id="speed_grader_post_grades_menu_mount_point"></span>
    <span id="speed_grader_settings_mount_point"></span>
    <div id="speed_grader_rubric_assessment_tray_wrapper"></div>
    <div id="speed_grader_assessment_audit_button_mount_point"></div>
    <div id="speed_grader_submission_comments_download_mount_point"></div>
    <div id="speed_grader_hidden_submission_pill_mount_point"></div>
    <div id="grades-loading-spinner"></div>
    <div id="multiple_submissions"></div>
    <div id="submission_details">Submission Details</div>
    <div id="reassign_assignment">Reassign</div>
    <select id="submission_to_view"><option value="0">Submission 1</option></select>
    <div id="iframe_holder"></div>
    <div id="react_pill_container"></div>
    <div id="full_width_container"></div>
    <div id="enrollment_inactive_notice"></div>
  `

  let fixtures

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = requiredDOMFixtures

    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false,
      SUBMISSION: {
        workflow_state: 'submitted',
        submission_type: 'online_text_entry',
        cached_due_date: '2024-01-01',
        submission_history: [{submission: {}}],
      },
    })

    window.jsonData = {
      id: 'student_1',
      anonymous_id: 'student_1',
      submission_state: 'not_graded',
      studentMap: {
        student_1: {
          id: 'student_1',
          name: 'Test Student',
          anonymizableId: 'student_1',
          anonymous_id: 'student_1',
          submission_state: 'not_graded',
          enrollments: [{workflow_state: 'active'}],
          submission: {
            workflow_state: 'submitted',
            submission_type: 'online_text_entry',
            cached_due_date: '2024-01-01',
            submission_history: [{submission: {}}],
          },
        },
      },
      context: {
        active_course_sections: [],
        enrollments: [],
        students: [],
      },
      submissions: [],
      gradingPeriods: {},
    }

    SpeedGrader.setup()
    SpeedGrader.EG = {
      currentStudent: {
        id: 'student_1',
        anonymous_id: 'student_1',
        anonymizableId: 'student_1',
        submission_state: 'not_graded',
        submission: {
          workflow_state: 'submitted',
          submission_type: 'online_text_entry',
          cached_due_date: '2024-01-01',
          submission_history: [{submission: {}}],
        },
      },
      refreshSubmissionsToView() {},
      handleSubmissionSelectionChange() {
        SpeedGrader.EG.showSubmissionDetails()
      },
      showSubmissionDetails() {
        const submission = this.currentStudent.submission
        if (submission.workflow_state === 'unsubmitted') {
          $('#reassign_assignment').hide()
          return
        }

        if (allowsReassignment(submission.submission_type)) {
          $('#reassign_assignment').show()
        } else {
          $('#reassign_assignment').hide()
        }
      },
    }
  })

  afterEach(() => {
    SpeedGrader.teardown()
    fakeENV.teardown()
    fixtures.remove()
    jest.resetAllMocks()
  })

  describe('Reassign button visibility', () => {
    it('shows the Reassign button when submission type is reassignable', () => {
      allowsReassignment.mockReturnValue(true)
      SpeedGrader.EG.showSubmissionDetails()
      expect($('#reassign_assignment').css('display')).toBe('block')
    })

    it('hides the Reassign button when submission type is not reassignable', () => {
      allowsReassignment.mockReturnValue(false)
      SpeedGrader.EG.showSubmissionDetails()
      expect($('#reassign_assignment').css('display')).toBe('none')
    })

    it('hides the Reassign button for unsubmitted submissions', () => {
      allowsReassignment.mockReturnValue(true)
      SpeedGrader.EG.currentStudent.submission.workflow_state = 'unsubmitted'
      SpeedGrader.EG.showSubmissionDetails()
      expect($('#reassign_assignment').css('display')).toBe('none')
    })

    describe('with different submission types', () => {
      const reassignableTypes = [
        'media_recording',
        'online_text_entry',
        'online_upload',
        'online_url',
        'student_annotation',
      ]

      const nonReassignableTypes = [
        'discussion_topic',
        'online_quiz',
        'basic_lti_launch',
        'not_graded',
      ]

      reassignableTypes.forEach(submissionType => {
        it(`shows the Reassign button for ${submissionType} submissions`, () => {
          allowsReassignment.mockReturnValue(true)
          SpeedGrader.EG.currentStudent.submission.submission_type = submissionType
          SpeedGrader.EG.showSubmissionDetails()
          expect($('#reassign_assignment').css('display')).toBe('block')
        })
      })

      nonReassignableTypes.forEach(submissionType => {
        it(`hides the Reassign button for ${submissionType} submissions`, () => {
          allowsReassignment.mockReturnValue(false)
          SpeedGrader.EG.currentStudent.submission.submission_type = submissionType
          SpeedGrader.EG.showSubmissionDetails()
          expect($('#reassign_assignment').css('display')).toBe('none')
        })
      })
    })
  })
})
