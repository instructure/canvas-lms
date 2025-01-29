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
import SpeedgraderHelpers from '../speed_grader_helpers'
import {
  setupIsAnonymous,
  setupAnonymizableId,
  setupAnonymizableUserId,
  setupAnonymizableStudentId,
  setupAnonymizableAuthorId,
} from '../speed_grader.utils'

describe('SpeedGrader', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    container.innerHTML = `
      <a id="assignment_submission_default_url" href="http://www.default.com"></a>
      <a id="assignment_submission_originality_report_url" href="http://www.report.com"></a>
    `
  })

  afterEach(() => {
    container.remove()
  })

  test('setupIsAnonymous is available on main object', () => {
    expect(setupIsAnonymous).toBe(setupIsAnonymous)
  })

  test('setupAnonymizableId is available on main object', () => {
    expect(setupAnonymizableId).toBe(setupAnonymizableId)
  })

  test('setupAnonymizableUserId is available on main object', () => {
    expect(setupAnonymizableUserId).toBe(setupAnonymizableUserId)
  })

  test('setupAnonymizableStudentId is available on main object', () => {
    expect(setupAnonymizableStudentId).toBe(setupAnonymizableStudentId)
  })

  test('setupAnonymizableAuthorId is available on main object', () => {
    expect(setupAnonymizableAuthorId).toBe(setupAnonymizableAuthorId)
  })

  test('populateTurnitin sets correct URL for OriginalityReports', () => {
    const submission = {
      id: '7',
      anonymous_id: 'zxcvb',
      grade: null,
      score: null,
      submitted_at: '2016-11-29T22:29:44Z',
      assignment_id: '52',
      user_id: '2',
      submission_type: 'online_upload',
      workflow_state: 'submitted',
      updated_at: '2016-11-29T22:29:44Z',
      grade_matches_current_submission: true,
      graded_at: null,
      turnitin_data: {
        attachment_103: {
          similarity_score: 0.8,
          state: 'acceptable',
          report_url: 'http://www.thebrickfan.com',
          status: 'scored',
        },
      },
      excused: null,
      versioned_attachments: [
        {
          attachment: {
            id: '103',
            context_id: '2',
            context_type: 'User',
            size: null,
            content_type: 'text/rtf',
            filename: '1480456390_119__Untitled.rtf',
            display_name: 'Untitled-2.rtf',
            workflow_state: 'pending_upload',
            viewed_at: null,
            view_inline_ping_url: '/assignments/52/files/103/inline_view',
            mime_class: 'doc',
            currently_locked: false,
            'crocodoc_available?': null,
            canvadoc_url: null,
            crocodoc_url: null,
            submitted_to_crocodoc: false,
            provisional_crocodoc_url: null,
          },
        },
      ],
      late: false,
      external_tool_url: null,
      has_originality_report: true,
    }
    const reportContainer = document.querySelector('#assignment_submission_originality_report_url')
    const defaultContainer = document.querySelector('#assignment_submission_default_url')
    const container_ = SpeedgraderHelpers.urlContainer(
      submission,
      defaultContainer,
      reportContainer,
    )
    expect(container_).toBe(reportContainer)
  })
})

describe('SpeedgraderHelpers#buildIframe', () => {
  const buildIframe = SpeedgraderHelpers.buildIframe

  test('sets src to given src', () => {
    const expected = '<iframe id="speedgrader_iframe" src="some/url?with=query"></iframe>'
    expect(buildIframe('some/url?with=query')).toBe(expected)
  })

  test('applies options as tag attrs', () => {
    const expected = '<iframe id="speedgrader_iframe" src="path" frameborder="0"></iframe>'
    const options = {frameborder: 0}
    expect(buildIframe('path', options)).toBe(expected)
  })

  test('applies className options as class', () => {
    const expected = '<iframe id="speedgrader_iframe" src="path" class="test"></iframe>'
    const options = {className: 'test'}
    expect(buildIframe('path', options)).toBe(expected)
  })
})

describe('SpeedgraderHelpers#determineGradeToSubmit', () => {
  let student, grade

  beforeEach(() => {
    student = {submission: {score: 89}}
    grade = {
      val() {
        return '25'
      },
    }
  })

  test('returns grade.val when use_existing_score is false', () => {
    expect(SpeedgraderHelpers.determineGradeToSubmit(false, student, grade)).toBe('25')
  })

  test('returns existing submission when use_existing_score is true', () => {
    expect(SpeedgraderHelpers.determineGradeToSubmit(true, student, grade)).toBe('89')
  })
})

describe('SpeedgraderHelpers#iframePreviewVersion', () => {
  const previewVersion = SpeedgraderHelpers.iframePreviewVersion

  test('returns empty string if submission is null', () => {
    expect(previewVersion(null)).toBe('')
  })

  test('returns empty string if submission contains no currentSelectedIndex', () => {
    expect(previewVersion({})).toBe('')
  })

  test('returns currentSelectedIndex if version is null', () => {
    const submission = {
      currentSelectedIndex: 0,
      submission_history: [{submission: {version: null}}, {submission: {version: 2}}],
    }
    expect(previewVersion(submission)).toBe('&version=0')
  })

  test('returns currentSelectedIndex if version is the same', () => {
    const submission = {
      currentSelectedIndex: 0,
      submission_history: [{submission: {version: 0}}, {submission: {version: 1}}],
    }
    expect(previewVersion(submission)).toBe('&version=0')
  })

  test('returns version if its different', () => {
    const submission = {
      currentSelectedIndex: 0,
      submission_history: [{submission: {version: 1}}, {submission: {version: 2}}],
    }
    expect(previewVersion(submission)).toBe('&version=1')
  })

  test('returns correct version for a given index', () => {
    const submission = {
      currentSelectedIndex: 1,
      submission_history: [{submission: {version: 1}}, {submission: {version: 2}}],
    }
    expect(previewVersion(submission)).toBe('&version=2')
  })

  test("returns '' if a currentSelectedIndex is not a number", () => {
    const submission = {
      currentSelectedIndex: 'one',
      submission_history: [{submission: {version: 1}}, {submission: {version: 2}}],
    }
    expect(previewVersion(submission)).toBe('')
  })

  test('returns currentSelectedIndex if version is not a number', () => {
    const submission = {
      currentSelectedIndex: 1,
      submission_history: [{submission: {version: 'one'}}, {submission: {version: 'two'}}],
    }
    expect(previewVersion(submission)).toBe('&version=1')
  })
})

describe('SpeedgraderHelpers#setRightBarDisabled', () => {
  let testArea

  beforeEach(() => {
    testArea = document.createElement('div')
    testArea.id = 'test_area'
    document.body.appendChild(testArea)
    testArea.innerHTML = `
      <input type="text" id="grading-box-extended" data-testid="grading-box">
      <textarea id="speed_grader_comment_textarea" data-testid="comment-textarea"></textarea>
      <button id="add_attachment" data-testid="add-attachment"></button>
      <button id="media_comment_button" data-testid="media-comment"></button>
      <button id="comment_submit_button" data-testid="submit-comment"></button>
    `
  })

  afterEach(() => {
    testArea.remove()
  })

  test('it properly disables the elements we care about in the right bar', () => {
    SpeedgraderHelpers.setRightBarDisabled(true)
    const elements = testArea.querySelectorAll('[data-testid]')
    elements.forEach(element => {
      expect(element).toHaveClass('ui-state-disabled')
      expect(element).toHaveAttribute('aria-disabled', 'true')
      expect(element).toHaveAttribute('readonly', 'readonly')
      expect(element).toBeDisabled()
    })
  })

  test('it properly enables the elements we care about in the right bar', () => {
    SpeedgraderHelpers.setRightBarDisabled(false)
    const elements = testArea.querySelectorAll('[data-testid]')
    elements.forEach(element => {
      expect(element).not.toHaveClass('ui-state-disabled')
      expect(element).not.toHaveAttribute('aria-disabled')
      expect(element).not.toHaveAttribute('readonly')
      expect(element).not.toBeDisabled()
    })
  })
})

describe('SpeedgraderHelpers#classNameBasedOnStudent', () => {
  let student

  beforeEach(() => {
    student = {
      submission_state: null,
      submission: {submitted_at: '2016-10-13 12:22:39'},
    }
  })

  test('returns graded for graded', () => {
    student.submission_state = 'graded'
    const state = SpeedgraderHelpers.classNameBasedOnStudent(student)
    expect(state).toEqual({
      raw: 'graded',
      formatted: 'graded',
    })
  })

  test("returns 'not graded' for not_graded", () => {
    student.submission_state = 'not_graded'
    const state = SpeedgraderHelpers.classNameBasedOnStudent(student)
    expect(state).toEqual({
      raw: 'not_graded',
      formatted: 'not graded',
    })
  })

  test('returns graded for not_gradeable', () => {
    student.submission_state = 'not_gradeable'
    const state = SpeedgraderHelpers.classNameBasedOnStudent(student)
    expect(state).toEqual({
      raw: 'not_gradeable',
      formatted: 'graded',
    })
  })

  test("returns 'not submitted' for not_submitted", () => {
    student.submission_state = 'not_submitted'
    const state = SpeedgraderHelpers.classNameBasedOnStudent(student)
    expect(state).toEqual({
      raw: 'not_submitted',
      formatted: 'not submitted',
    })
  })

  test('returns resubmitted data for graded_then_resubmitted', () => {
    student.submission_state = 'resubmitted'
    const state = SpeedgraderHelpers.classNameBasedOnStudent(student)
    expect(state).toEqual({
      raw: 'resubmitted',
      formatted: 'graded, then resubmitted (Oct 13, 2016 at 12:22pm)',
    })
  })
})

describe('SpeedgraderHelpers#submissionState', () => {
  let student

  beforeEach(() => {
    student = {submission: {grade_matches_current_submission: true}}
  })

  test('returns graded if grade matches current submission', () => {
    student.submission.grade_matches_current_submission = true
    student.submission.grade = 10
    expect(SpeedgraderHelpers.submissionState(student, 'teacher')).toBe('graded')
  })

  test("returns resubmitted if grade doesn't match current submission", () => {
    student.submission.grade = 10
    student.submission.grade_matches_current_submission = false
    expect(SpeedgraderHelpers.submissionState(student, 'teacher')).toBe('resubmitted')
  })

  test('returns not submitted if submission.workflow_state is unsubmitted', () => {
    student.submission.workflow_state = 'unsubmitted'
    expect(SpeedgraderHelpers.submissionState(student, 'teacher')).toBe('not_submitted')
  })

  test("returns not_gradeable if provisional_grader and student doesn't need provision grade", () => {
    student.submission.workflow_state = 'submitted'
    student.submission.submitted_at = '2016-10-13 12:22:39'
    student.submission.provisional_grade_id = null
    student.needs_provisional_grade = false
    expect(SpeedgraderHelpers.submissionState(student, 'provisional_grader')).toBe('not_gradeable')
  })

  test("returns not_gradeable if moderator and student doesn't need provision grade", () => {
    student.submission.workflow_state = 'submitted'
    student.submission.submitted_at = '2016-10-13 12:22:39'
    student.submission.provisional_grade_id = null
    student.needs_provisional_grade = false
    expect(SpeedgraderHelpers.submissionState(student, 'moderator')).toBe('not_gradeable')
  })

  test('returns not_graded if submitted but no grade', () => {
    student.submission.workflow_state = 'submitted'
    student.submission.submitted_at = '2016-10-13 12:22:39'
    expect(SpeedgraderHelpers.submissionState(student, 'teacher')).toBe('not_graded')
  })

  test('returns not_graded if pending_review', () => {
    student.submission.workflow_state = 'pending_review'
    student.submission.submitted_at = '2016-10-13 12:22:39'
    student.submission.grade = 123
    expect(SpeedgraderHelpers.submissionState(student, 'teacher')).toBe('not_graded')
  })

  test('returns graded if final_provisional_grade.grade exists', () => {
    student.submission.submitted_at = '2016-10-13 12:22:39'
    student.submission.final_provisional_grade = {grade: 123}
    expect(SpeedgraderHelpers.submissionState(student, 'teacher')).toBe('graded')
  })

  test('returns graded if submission excused', () => {
    student.submission.submitted_at = '2016-10-13 12:22:39'
    student.submission.excused = true
    expect(SpeedgraderHelpers.submissionState(student, 'teacher')).toBe('graded')
  })
})

describe('SpeedgraderHelpers#plagiarismResubmitHandler', () => {
  let resubmitButton
  let mockReloadPage
  let mockAjaxJSON

  beforeEach(() => {
    resubmitButton = document.createElement('button')
    resubmitButton.id = 'resubmit-button'
    resubmitButton.textContent = 'Click Here'
    document.body.appendChild(resubmitButton)
    mockReloadPage = jest.spyOn(SpeedgraderHelpers, 'reloadPage').mockImplementation(() => {})
    mockAjaxJSON = jest.fn()
    $.ajaxJSON = mockAjaxJSON
  })

  afterEach(() => {
    resubmitButton.remove()
    mockReloadPage.mockRestore()
    delete $.ajaxJSON
  })

  test("prevents the button's default action and starts resubmission", () => {
    const preventDefault = jest.fn()
    const event = {
      preventDefault,
      target: resubmitButton,
    }
    SpeedgraderHelpers.plagiarismResubmitHandler(event, 'http://www.test.com')
    expect(preventDefault).toHaveBeenCalled()
    expect(resubmitButton).toBeDisabled()
    expect(resubmitButton.textContent).toBe('Resubmitting...')
    expect(mockAjaxJSON).toHaveBeenCalledWith(
      'http://www.test.com',
      'POST',
      {},
      expect.any(Function),
    )
  })

  test('reloads the page after successful resubmission', () => {
    const event = {
      preventDefault: jest.fn(),
      target: resubmitButton,
    }
    SpeedgraderHelpers.plagiarismResubmitHandler(event, 'http://www.test.com')
    const callback = mockAjaxJSON.mock.calls[0][3]
    callback()
    expect(mockReloadPage).toHaveBeenCalled()
  })
})

describe('SpeedGraderHelpers.resourceLinkLookupUuidParam', () => {
  test('returns an empty string when submission resource_link_lookup_uuid does not exists', () => {
    const submission = {}
    expect(SpeedgraderHelpers.resourceLinkLookupUuidParam(submission)).toBe('')
  })

  test('returns resource_link_lookup_uuid param when submission resource_link_lookup_uuid exists', () => {
    const submission = {resource_link_lookup_uuid: 'test-uuid'}
    expect(SpeedgraderHelpers.resourceLinkLookupUuidParam(submission)).toBe(
      '&resource_link_lookup_uuid=test-uuid',
    )
  })
})
