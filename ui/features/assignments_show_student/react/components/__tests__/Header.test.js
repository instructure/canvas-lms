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
import {mockAssignmentAndSubmission, mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import {render} from '@testing-library/react'
import StudentViewContext from '../Context'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

jest.mock('../AttemptSelect')

it('renders normally', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('assignment-student-header-normal')).toBeInTheDocument()
})

it('renders a "View Feedback" button', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByText} = render(<Header {...props} />)
  expect(getByText('View Feedback')).toBeInTheDocument()
})

it('does not render a "View Feedback" button when no submission is present', async () => {
  const props = await mockAssignmentAndSubmission({Submission: null})
  props.allSubmissions = [{id: 1}]
  const {queryByText} = render(<Header {...props} />)
  expect(queryByText('View Feedback')).not.toBeInTheDocument()
})

it('will not render LatePolicyStatusDisplay if the submission is not late', async () => {
  const props = await mockAssignmentAndSubmission()
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('late-policy-container')).not.toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the submission status is late', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      submissionStatus: 'late'
    }
  })
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the latePolicyStatus is late', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      latePolicyStatus: 'late'
    }
  })
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render the latest grade instead of the displayed submissions grade', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      grade: '147',
      enteredGrade: '147'
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      grade: '131',
      enteredGrade: '131'
    }
  })

  const {queryByText, queryAllByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(queryAllByText('147/150 Points')[0]).toBeInTheDocument()
  expect(queryByText('131/150 Points')).not.toBeInTheDocument()
})

it('will not render the grade if the last submitted submission is excused', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.excused,
      grade: '147',
      enteredGrade: '147'
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      grade: '131',
      enteredGrade: '131'
    }
  })

  const {getByTestId} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(getByTestId('grade-display').textContent).toEqual('Excused!')
})

describe('submission workflow tracker', () => {
  it('is rendered when a submission exists and the assignment is available', async () => {
    const props = await mockAssignmentAndSubmission()
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).toBeInTheDocument()
  })

  it('is not rendered when no submission object is present', async () => {
    const props = await mockAssignmentAndSubmission({Submission: null})
    props.allSubmissions = [{id: 1}]
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })

  it('is not rendered when there is no current user', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.currentUser = null
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })

  it('is not rendered when the assignment has not been unlocked yet', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.modulePrereq = 'simulate not null'
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })

  it('is not rendered when the assignment has uncompleted prerequisites', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.unlockDate = 'soon'
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })
})

it('renders the attempt select', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {...SubmissionMocks.submitted}
  })
  props.allSubmissions = [props.submission]
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).toBeInTheDocument()
})

it('does not render the attempt select if there is no submission', async () => {
  const props = await mockAssignmentAndSubmission({Submission: null})
  props.allSubmissions = [{id: 1}]
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
})

it('does not render the attempt select if allSubmissions is not provided', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {...SubmissionMocks.submitted}
  })
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
})

it('does not render the attempt select if the assignment has non-digital submissions', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {nonDigitalSubmission: true},
    Submission: {...SubmissionMocks.submitted}
  })
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
})
