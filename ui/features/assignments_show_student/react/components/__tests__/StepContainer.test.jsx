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
import {render} from '@testing-library/react'

import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import StepContainer from '../StepContainer'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

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

it('will render collapsed label if steps is collapsed', async () => {
  const props = await mockAssignmentAndSubmission({Submission: SubmissionMocks.submitted})
  const {getAllByText, getByTestId} = render(<StepContainer {...props} isCollapsed={true} />)
  expect(getByTestId('collapsed-step-container')).toContainElement(getAllByText('Submitted')[0])
})

it('will not render collapsed label if steps is not collapsed', async () => {
  const props = await mockAssignmentAndSubmission({Submission: SubmissionMocks.submitted})
  const {getByText, queryByTestId} = render(
    <StepContainer {...props} isCollapsed={false} collapsedLabel="TEST" />
  )
  expect(queryByTestId('collapsed-step-container')).not.toBeInTheDocument()
  expect(getByText('Uploaded')).toBeInTheDocument()
})

describe('the assignment is unavailable', () => {
  it('renders the pizza tracker with the first state as unavailable for unsubmitted and undrafted assignments', async () => {
    const props = await mockAssignmentAndSubmission({LockInfo: {isLocked: true}})
    const {getByText, getByTestId} = render(<StepContainer {...props} />)
    verifySteps(getByTestId('available-step-container'), unavailableSteps, getByText)
  })

  it('renders the pizza tracker with the current step icon as locked for drafted assignments', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        submissionDraft: {
          meetsAssignmentCriteria: true,
        },
      },
      LockInfo: {isLocked: true},
    })
    const {container, getByText, getByTestId} = render(<StepContainer {...props} />)
    verifySteps(
      getByTestId('uploaded-step-container'),
      ['Uploaded', 'Submit', 'Not Graded Yet'],
      getByText
    )
    expect(container.querySelector('svg[name="IconLock"]')).toBeInTheDocument()
  })

  it('will render the unavailable state tracker with all the appropriate steps', async () => {
    const {getByText, getByTestId} = render(<StepContainer />)
    verifySteps(getByTestId('unavailable-step-container'), unavailableSteps, getByText)
  })
})

describe('the assignment is available', () => {
  it('will render the available state tracker with all the appropriate steps', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId, getByText} = render(<StepContainer {...props} />)
    verifySteps(getByTestId('available-step-container'), availableSteps, getByText)
  })

  it('will render the availaible state tracker if assignment is not locked, uploaded, or submitted', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(<StepContainer {...props} />)
    expect(getByTestId('available-step-container')).toBeInTheDocument()
  })

  it('will render the availaible state tracker if there are no attachments', async () => {
    const props = await mockAssignmentAndSubmission({SubmissionDraft: {attachments: []}})
    const {getByTestId} = render(<StepContainer {...props} />)
    expect(getByTestId('available-step-container')).toBeInTheDocument()
  })

  it('will render the availaible state tracker if there is an empty submission draft', async () => {
    const props = await mockAssignmentAndSubmission({SubmissionDraft: null})
    const {getByTestId} = render(<StepContainer {...props} />)
    expect(getByTestId('available-step-container')).toBeInTheDocument()
  })
})

describe('the assignment is uploaded', () => {
  it('will render the uploaded state tracker with all appropriate steps', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })
    const {getByTestId, getByText} = render(<StepContainer {...props} />)
    verifySteps(getByTestId('uploaded-step-container'), uploadedSteps, getByText)
  })

  it('will render the uploaded state tracker if an assignment is not submitted', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })
    const {getByTestId} = render(<StepContainer {...props} />)
    expect(getByTestId('uploaded-step-container')).toBeInTheDocument()
  })
})

describe('the assignment is submitted', () => {
  it('will render the submitted state tracker with all appropriate steps', async () => {
    const props = await mockAssignmentAndSubmission({Submission: SubmissionMocks.submitted})
    const {getByTestId, getByText} = render(<StepContainer {...props} />)
    verifySteps(getByTestId('submitted-step-container'), submittedSteps, getByText)
  })

  it('will render the submitted state tracker if an assignment is not graded', async () => {
    const props = await mockAssignmentAndSubmission({Submission: SubmissionMocks.submitted})
    const {getByTestId} = render(<StepContainer {...props} />)
    expect(getByTestId('submitted-step-container')).toBeInTheDocument()
  })
})

describe('the assignment is graded', () => {
  it('will render the graded state tracker with all appropriate steps', async () => {
    const props = await mockAssignmentAndSubmission({Submission: SubmissionMocks.graded})
    const {getByTestId, getByText} = render(<StepContainer {...props} />)
    verifySteps(getByTestId('graded-step-container'), gradedSteps, getByText)
  })
})
