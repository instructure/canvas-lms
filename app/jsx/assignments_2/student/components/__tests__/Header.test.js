/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Header from '../Header'
import {legacyMockSubmission, mockAssignment} from '../../test-utils'
import React from 'react'
import {render} from 'react-testing-library'

// TODO: is scroll threshold is always 150 in every case, why are we passing
//       that down as a prop instead of just having it be a constant in the
//       component or a default prop value?

it('renders normally', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )

  expect(getByTestId('assignment-student-header-normal')).toBeInTheDocument()
})

it('dispatches scroll event properly when less than threshold', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-normal')).toBeInTheDocument()
})

it('dispatches scroll event properly when greater than threshold', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 500
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-sticky')).toBeInTheDocument()
})

it('displays element filler when scroll offset is in correct place', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-normal')).toBeInTheDocument()

  window.pageYOffset = 200
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('header-element-filler')).toBeInTheDocument()
  expect(getByTestId('assignment-student-header-sticky')).toBeInTheDocument()
})

it('will not render LatePolicyStatusDisplay if the submission is not late', () => {
  const submission = legacyMockSubmission()
  submission.latePolicyStatus = null
  submission.submissionStatus = null
  const {queryByTestId} = render(
    <Header scrollThreshold={150} assignment={mockAssignment()} submission={submission} />
  )

  expect(queryByTestId('late-policy-container')).not.toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the submission status is late', () => {
  const submission = legacyMockSubmission()
  submission.latePolicyStatus = null
  const {getByTestId} = render(
    <Header scrollThreshold={150} assignment={mockAssignment()} submission={submission} />
  )

  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the latePolicyStatus is late status is late', () => {
  const submission = legacyMockSubmission()
  submission.submissionStatus = null
  const {getByTestId} = render(
    <Header scrollThreshold={150} assignment={mockAssignment()} submission={submission} />
  )

  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render the unavailable state tracker if an assignment is not available', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )

  expect(getByTestId('unavailable-step-container')).toBeInTheDocument()
})

it('will render the available state tracker if an assignment is available but not uploaded and not submitted', () => {
  const assignment = mockAssignment()
  const submission = legacyMockSubmission()
  assignment.lockInfo.isLocked = false
  submission.state = 'unsubmitted'
  const {getByTestId} = render(
    <Header scrollThreshold={150} assignment={assignment} submission={submission} />
  )

  expect(getByTestId('available-step-container')).toBeInTheDocument()
})

describe('the assignment is submitted', () => {
  it('will render the submitted state tracker if an assignment is submitted but not graded', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId} = render(
      <Header scrollThreshold={150} assignment={assignment} submission={submission} />
    )

    expect(getByTestId('submitted-step-container')).toBeInTheDocument()
  })

  it('will render the New Attempt button if more attempts are allowed', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId, getByText} = render(
      <Header scrollThreshold={150} assignment={assignment} submission={submission} />
    )

    expect(getByTestId('submitted-step-container')).toContainElement(getByText('New Attempt'))
  })

  it('will not render the New Attempt button if more attempts are not allowed', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.allowedAttempts = 1
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId, queryByText} = render(
      <Header scrollThreshold={150} assignment={assignment} submission={submission} />
    )

    expect(getByTestId('submitted-step-container')).not.toContainElement(queryByText('New Attempt'))
  })
})

it('will render the uploaded state tracker if an assignment is uploaded but not submitted', () => {
  const assignment = mockAssignment()
  const submission = legacyMockSubmission()
  assignment.lockInfo.isLocked = false
  submission.submissionDraft = {_id: '3'}
  submission.state = 'unsubmitted'
  const {getByTestId} = render(
    <Header scrollThreshold={150} assignment={assignment} submission={submission} />
  )

  expect(getByTestId('uploaded-step-container')).toBeInTheDocument()
})

it('will render the submitted state tracker if an assignment is submitted but not graded', () => {
  const assignment = mockAssignment()
  const submission = legacyMockSubmission()
  assignment.lockInfo.isLocked = false
  submission.state = 'submitted'
  const {getByTestId} = render(
    <Header scrollThreshold={150} assignment={assignment} submission={submission} />
  )

  expect(getByTestId('submitted-step-container')).toBeInTheDocument()
})

describe('the assignment is graded', () => {
  it('will render the graded state tracker if an assignment is graded', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'graded'
    const {getByTestId} = render(
      <Header scrollThreshold={150} assignment={assignment} submission={submission} />
    )

    expect(getByTestId('graded-step-container')).toBeInTheDocument()
  })

  it('will render the New Attempt button if more attempts are allowed', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'graded'
    const {getByTestId, getByText} = render(
      <Header scrollThreshold={150} assignment={assignment} submission={submission} />
    )

    expect(getByTestId('graded-step-container')).toContainElement(getByText('New Attempt'))
  })

  it('will not render the New Attempt button if more attempts are not allowed', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.allowedAttempts = 1
    assignment.lockInfo.isLocked = false
    submission.state = 'graded'
    const {getByTestId, queryByText} = render(
      <Header scrollThreshold={150} assignment={assignment} submission={submission} />
    )

    expect(getByTestId('graded-step-container')).not.toContainElement(queryByText('New Attempt'))
  })
})
