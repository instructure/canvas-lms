/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {friendlyTypeName, isSubmitted, totalAllowedAttempts} from '../SubmissionHelpers'

describe('totalAllowedAttempts', () => {
  it('returns null if allowedAttempts on the assignment is null', () => {
    const assignment = {allowedAttempts: null}
    expect(totalAllowedAttempts({assignment})).toBeNull()
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
