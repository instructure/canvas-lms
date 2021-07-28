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
import {fireEvent, render} from '@testing-library/react'
import StudentViewContext from '../Context'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

jest.mock('../AttemptSelect')

it('renders normally', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('assignment-student-header')).toBeInTheDocument()
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

it('renders a "late" status pill if the last graded submission is late', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      submissionStatus: 'late'
    }
  })
  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByText('Late')).toBeInTheDocument()
})

it('shows the number of points deducted in the tooltip when the current grade is focused', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      submissionStatus: 'late'
    }
  })

  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  const pointsDisplay = getByText('6/10 Points')
  fireEvent.focus(pointsDisplay)
  expect(getByText('Late Penalty')).toBeInTheDocument()
  expect(getByText('-4')).toBeInTheDocument()
})

it('renders a "missing" status pill if the last graded submission is missing', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      submissionStatus: 'missing'
    }
  })
  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByText('Missing')).toBeInTheDocument()
})

it('does not render a status pill if the last graded submission is not late or missing', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: SubmissionMocks.graded
  })
  const {queryByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(queryByText('Late')).not.toBeInTheDocument()
  expect(queryByText('Missing')).not.toBeInTheDocument()
})

it('shows the most recently received grade as the "canonical" score', async () => {
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

  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(getByText('147/150 Points')).toBeInTheDocument()
})

it('renders the grade for the currently selected attempt', async () => {
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
      attempt: 7,
      grade: '131',
      enteredGrade: '131'
    }
  })

  const {container} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(container).toHaveTextContent(/Attempt 7 Score:\s*131\/150/)
})

it('renders "N/A" for the currently selected attempt if it has no grade', async () => {
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
      ...SubmissionMocks.submitted,
      attempt: 7
    }
  })

  const {container} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(container).toHaveTextContent(/Attempt 7 Score:\s*N\/A/)
})

it('renders "Offline Score" when the student is graded before submitting', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      grade: '147',
      enteredGrade: '147',
      attempt: 0
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 0,
      grade: '131',
      enteredGrade: '131'
    }
  })

  const {container} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(container).toHaveTextContent(/Offline Score:\s*131\/150/)
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

  expect(getByTestId('grade-display').textContent).toEqual('Excused')
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
