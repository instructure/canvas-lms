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
import React from 'react'
import {render} from 'react-testing-library'

import {mockAssignment, legacyMockSubmission} from '../../test-utils'
import StepContainer from '../StepContainer'

const unavailableSteps = ['Unavailable', 'Upload', 'Submit', 'Not Graded Yet']
const availableSteps = ['Available', 'Upload', 'Submit', 'Not Graded Yet']
const uploadedSteps = ['Available', 'Uploaded', 'Submit', 'Not Graded Yet']
const submittedSteps = ['Available', 'Uploaded', 'Submitted', 'Not Graded Yet']
const gradedSteps = ['Available', 'Uploaded', 'Submitted', 'Graded']

/**
 * @param stepContainer the step container to verify; the step
 *                      container should include all the steps
 *                      characteristic to it
 * @param stepArray     an array of the steps, represented as
 *                      strings, that are characteristic to the
 *                      step container
 * @param getStep       the function that retrieves the steps
 *                      from the step container
 */
function verifySteps(stepContainer, stepArray, getStep) {
  stepArray.forEach(step => {
    expect(stepContainer).toContainElement(getStep(step))
  })
}

it('will render collapsed label if steps is collapsed', () => {
  const assignment = mockAssignment()
  const submission = legacyMockSubmission()
  assignment.lockInfo.isLocked = false
  submission.state = 'submitted'
  const {getByText, getByTestId} = render(
    <StepContainer assignment={assignment} submission={submission} isCollapsed />
  )

  expect(getByTestId('collapsed-step-container')).toContainElement(getByText('Submitted'))
})

it('will not render collapsed label if steps is not collapsed', () => {
  const assignment = mockAssignment()
  const submission = legacyMockSubmission()
  assignment.lockInfo.isLocked = false
  const label = 'TEST'
  submission.state = 'submitted'
  const {getByText, queryByTestId} = render(
    <StepContainer
      assignment={assignment}
      isCollapsed={false}
      submission={submission}
      collapsedLabel={label}
    />
  )

  expect(queryByTestId('collapsed-step-container')).not.toBeInTheDocument()
  expect(getByText('Uploaded')).toBeInTheDocument()
})

describe('the assignment is unavailable', () => {
  it('will render the unavailable state tracker with all the appropriate steps', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = true
    const {getByTestId, getByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )
    verifySteps(getByTestId('unavailable-step-container'), unavailableSteps, getByText)
  })

  it('will render the unavailable state tracker if assignment is locked', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = true
    const {getByTestId} = render(<StepContainer assignment={assignment} submission={submission} />)

    expect(getByTestId('unavailable-step-container')).toBeInTheDocument()
  })
})

describe('the assignment is available', () => {
  it('will render the available state tracker with all the appropriate steps', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'unsubmitted'
    const {getByTestId, getByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    verifySteps(getByTestId('available-step-container'), availableSteps, getByText)
  })

  it('will render the availaible state tracker if assignment is not locked, not uploaded, and not submitted', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'unsubmitted'
    const {getByTestId} = render(<StepContainer assignment={assignment} submission={submission} />)

    expect(getByTestId('available-step-container')).toBeInTheDocument()
  })
})

describe('the assignment is uploaded', () => {
  it('will render the uploaded state tracker with all appropriate steps', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.submissionDraft = {_id: '3'}
    submission.state = 'unsubmitted'
    const {getByTestId, getByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    verifySteps(getByTestId('uploaded-step-container'), uploadedSteps, getByText)
  })

  it('will render the uploaded state tracker if an assignment is not submitted', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.submissionDraft = {_id: '3'}
    submission.state = 'unsubmitted'
    const {getByTestId} = render(<StepContainer assignment={assignment} submission={submission} />)

    expect(getByTestId('uploaded-step-container')).toBeInTheDocument()
  })
})

describe('the assignment is submitted', () => {
  it('will render the submitted state tracker with all appropriate steps', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId, getByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    verifySteps(getByTestId('submitted-step-container'), submittedSteps, getByText)
  })

  it('will render the submitted state tracker if an assignment is not graded', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId} = render(<StepContainer assignment={assignment} submission={submission} />)

    expect(getByTestId('submitted-step-container')).toBeInTheDocument()
  })

  it('will render the New Attempt step if more attempts are allowed', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId} = render(<StepContainer assignment={assignment} submission={submission} />)

    expect(getByTestId('submitted-step-container')).toBeInTheDocument()
  })

  it('will not render the New Attempt step if more attempts are not allowed', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.allowedAttempts = 1
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId, queryByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    expect(getByTestId('submitted-step-container')).not.toContainElement(queryByText('New Attempt'))
  })

  it('will render the Previous step', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId, getByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    expect(getByTestId('submitted-step-container')).toContainElement(getByText('Previous'))
  })

  it('will render the Next step', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'submitted'
    const {getByTestId, getByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    expect(getByTestId('submitted-step-container')).toContainElement(getByText('Next'))
  })
})

describe('the assignment is graded', () => {
  it('will render the graded state tracker with all appropriate steps', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'graded'
    const {getByTestId, getByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    verifySteps(getByTestId('graded-step-container'), gradedSteps, getByText)
  })

  it('will render the New Attempt button if more attempts are allowed', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'graded'
    const {getByTestId, getByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    expect(getByTestId('graded-step-container')).toContainElement(getByText('New Attempt'))
  })

  it('will not render the New Attempt step if more attempts are not allowed', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.allowedAttempts = 1
    assignment.lockInfo.isLocked = false
    submission.state = 'graded'
    const {getByTestId, queryByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    expect(getByTestId('graded-step-container')).not.toContainElement(queryByText('New Attempt'))
  })

  it('will render the Previous step', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'graded'
    const {getByTestId, queryByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    expect(getByTestId('graded-step-container')).toContainElement(queryByText('Previous'))
  })

  it('will render the Next step', () => {
    const assignment = mockAssignment()
    const submission = legacyMockSubmission()
    assignment.lockInfo.isLocked = false
    submission.state = 'graded'
    const {getByTestId, queryByText} = render(
      <StepContainer assignment={assignment} submission={submission} />
    )

    expect(getByTestId('graded-step-container')).toContainElement(queryByText('Next'))
  })
})
