/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {
  friendlyTypeName,
  isSubmitted,
  totalAllowedAttempts,
  activeTypeMeetsCriteria,
  getPointsValue,
  multipleTypesDrafted,
} from '../SubmissionHelpers'
import {Submission} from '../../../assignments_show_student'

describe('totalAllowedAttempts', () => {
  it('returns null if allowedAttempts on the assignment is null', () => {
    const assignment = {allowedAttempts: null}
    expect(totalAllowedAttempts(assignment)).toBeNull()
  })

  it('returns the allowed attempts on the assignment if no submission is provided', () => {
    const assignment = {allowedAttempts: 7}
    expect(totalAllowedAttempts(assignment)).toBe(7)
  })

  it('returns the allowed attempts on the assignment if extraAttempts on submission is null', () => {
    const assignment = {allowedAttempts: 7}
    const submission = {extraAttempts: null}
    expect(totalAllowedAttempts(assignment, submission)).toBe(7)
  })

  it('returns the sum of allowedAttempts and extraAttempts if both are present and non-null', () => {
    const assignment = {allowedAttempts: 7}
    const submission = {extraAttempts: 5}
    expect(totalAllowedAttempts(assignment, submission)).toBe(12)
  })
})

describe('friendlyTypeName', () => {
  it('returns the value Annotation for the submission type student_annotation', () => {
    expect(friendlyTypeName('student_annotation')).toBe('Annotation')
  })
})

describe('isSubmitted', () => {
  it('returns true when the submission has a state of "submitted"', () => {
    const submission = {state: 'submitted', attempt: 1}
    expect(isSubmitted(submission)).toBe(true)
  })

  it('returns true when the submission has been graded after the student submitted', () => {
    const submission = {state: 'graded', attempt: 1}
    expect(isSubmitted(submission)).toBe(true)
  })

  it('returns false when the submission has been graded before the student submitted', () => {
    const submission = {state: 'graded', attempt: 0}
    expect(isSubmitted(submission)).toBe(false)
  })

  it('returns false when the submission state is neither "submitted" nor "graded"', () => {
    const submission = {state: 'unsubmitted', attempt: 1}
    expect(isSubmitted(submission)).toBe(false)
  })
})

describe('activeTypeMeetsCriteria', () => {
  const submissionMock = {
    submissionDraft: {
      meetsMediaRecordingCriteria: true,
      meetsTextEntryCriteria: false,
      meetsUploadCriteria: true,
      meetsUrlCriteria: false,
      meetsStudentAnnotationCriteria: true,
      meetsBasicLtiLaunchCriteria: false,
    },
  }

  test('returns correct value for media_recording', () => {
    expect(activeTypeMeetsCriteria('media_recording', submissionMock)).toBe(true)
  })

  test('returns correct value for online_text_entry', () => {
    expect(activeTypeMeetsCriteria('online_text_entry', submissionMock)).toBe(false)
  })

  test('returns correct value for online_upload', () => {
    expect(activeTypeMeetsCriteria('online_upload', submissionMock)).toBe(true)
  })

  test('returns correct value for online_url', () => {
    expect(activeTypeMeetsCriteria('online_url', submissionMock)).toBe(false)
  })

  test('returns correct value for student_annotation', () => {
    expect(activeTypeMeetsCriteria('student_annotation', submissionMock)).toBe(true)
  })

  test('returns correct value for basic_lti_launch', () => {
    expect(activeTypeMeetsCriteria('basic_lti_launch', submissionMock)).toBe(false)
  })

  test('returns undefined if submissionDraft is missing', () => {
    expect(activeTypeMeetsCriteria('media_recording')).toBeUndefined()
  })
})

describe('getPointsValue', () => {
  it('returns the number if points is a number', () => {
    expect(getPointsValue(10)).toBe(10)
  })
  it('returns the value property if points is an object with a value property', () => {
    expect(getPointsValue({value: 15, text: '15', valid: true})).toBe(15)
  })
  it('returns undefined if points is null', () => {
    expect(getPointsValue(null)).toBeUndefined()
  })
  it('returns undefined if points is undefined', () => {
    expect(getPointsValue()).toBeUndefined()
  })
})

describe('multipleTypesDrafted', () => {
  const createSubmission = (criteria: Record<string, boolean | undefined> = {}) =>
    ({
      submissionDraft: {
        meetsBasicLtiLaunchCriteria: false,
        meetsTextEntryCriteria: false,
        meetsUploadCriteria: false,
        meetsUrlCriteria: false,
        meetsMediaRecordingCriteria: false,
        meetsStudentAnnotationCriteria: false,
        ...criteria,
      },
    }) as Submission

  it('returns false for invalid inputs', () => {
    expect(multipleTypesDrafted(undefined as any)).toBe(false)
    expect(multipleTypesDrafted({} as any)).toBe(false)
    expect(multipleTypesDrafted({submissionDraft: {}} as any)).toBe(false)
  })

  it('returns false when no criteria are met', () => {
    expect(multipleTypesDrafted(createSubmission())).toBe(false)
  })

  it('returns false when only one criteria is met', () => {
    expect(multipleTypesDrafted(createSubmission({meetsTextEntryCriteria: true}))).toBe(false)
    expect(multipleTypesDrafted(createSubmission({meetsUploadCriteria: true}))).toBe(false)
  })

  it('returns true when multiple criteria are met', () => {
    expect(
      multipleTypesDrafted(
        createSubmission({
          meetsStudentAnnotationCriteria: true,
          meetsMediaRecordingCriteria: true,
        }),
      ),
    ).toBe(true)

    expect(
      multipleTypesDrafted(
        createSubmission({
          meetsBasicLtiLaunchCriteria: true,
          meetsTextEntryCriteria: true,
          meetsMediaRecordingCriteria: true,
        }),
      ),
    ).toBe(true)
  })

  it('returns false with undefined values', () => {
    expect(
      multipleTypesDrafted(
        createSubmission({
          meetsBasicLtiLaunchCriteria: undefined,
          meetsTextEntryCriteria: undefined,
        }),
      ),
    ).toBe(false)
  })

  it('returns true with a mix of true and undefined values', () => {
    expect(
      multipleTypesDrafted(
        createSubmission({
          meetsBasicLtiLaunchCriteria: true,
          meetsUploadCriteria: true,
          meetsTextEntryCriteria: undefined,
        }),
      ),
    ).toBe(true)
  })
})
