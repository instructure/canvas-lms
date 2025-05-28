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
import {MockedProvider} from '@apollo/client/testing'
import {render} from '@testing-library/react'
import {
  mockAssignmentAndSubmission,
  mockQuery,
  mockSubmission,
} from '@canvas/assignments/graphql/studentMocks'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import {RUBRIC_QUERY} from '@canvas/assignments/graphql/student/Queries'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import StudentViewContext from '../Context'
import StudentContent from '../StudentContent'
import ContextModuleApi from '../../apis/ContextModuleApi'

injectGlobalAlertContainers()

jest.mock('../AttemptSelect')

jest.mock('../../apis/ContextModuleApi')

jest.mock('../../../../../shared/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: jest.fn(),
  }
})

function gradedOverrides() {
  return {
    Submission: {
      rubricAssessmentsConnection: {
        nodes: [
          {
            _id: 1,
            score: 5,
            assessor: {_id: 1, name: 'assessor1', enrollments: []},
          },
          {
            _id: 2,
            score: 10,
            assessor: null,
          },
          {
            _id: 3,
            score: 8,
            assessor: {_id: 2, name: 'assessor2', enrollments: [{type: 'TaEnrollment'}]},
          },
        ],
      },
    },
  }
}

describe('Assignment Student Content View', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {...window.ENV}
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  it('renders the student header if the assignment is unlocked', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    expect(getByTestId('assignments-2-student-view')).toBeInTheDocument()
  })

  it('renders the student header if the assignment is locked', async () => {
    const props = await mockAssignmentAndSubmission({
      LockInfo: {isLocked: true},
    })

    const variables = {
      courseID: '1',
      assignmentLid: '1',
      submissionID: '1',
      submissionAttempt: 0,
    }
    const overrides = gradedOverrides()
    const allOverrides = [
      {
        Node: {__typename: 'Assignment'},
        Assignment: {rubric: {}, rubricAssociation: {}},
        Rubric: {
          criteria: [{}],
        },
        ...overrides,
      },
    ]
    const fetchRubricResult = await mockQuery(RUBRIC_QUERY, allOverrides, variables)
    const mocks = [
      {
        request: {query: RUBRIC_QUERY, variables},
        result: fetchRubricResult,
      },
    ]

    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    expect(getByTestId('assignment-student-header')).toBeInTheDocument()
  })

  it('renders the assignment details and student content if the assignment is unlocked', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByText, queryByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    expect(getByText('Details')).toBeInTheDocument()
    expect(queryByText('Availability Dates')).not.toBeInTheDocument()
  })

  it('renders a submission sticker when the flag is enabled and the student has a sticker', async () => {
    window.ENV.stickers_enabled = true
    const props = await mockAssignmentAndSubmission({Submission: {sticker: 'apple'}})
    const {getByRole} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )

    const sticker = getByRole('img', {name: 'A sticker with a picture of an apple.'})
    expect(sticker).toBeInTheDocument()
  })

  it('does not render a submission sticker when the flag is enabled but there is not a sticker', async () => {
    window.ENV.stickers_enabled = true
    const props = await mockAssignmentAndSubmission()
    const {queryByRole} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )

    const sticker = queryByRole('img', {name: 'A sticker with a picture of an apple.'})
    expect(sticker).not.toBeInTheDocument()
  })

  it('does not render a submission sticker when the flag is disabled', async () => {
    window.ENV.stickers_enabled = false
    const props = await mockAssignmentAndSubmission({Submission: {sticker: 'apple'}})
    const {queryByRole} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    const sticker = queryByRole('button', {name: 'A sticker with a picture of an apple.'})
    expect(sticker).not.toBeInTheDocument()
  })

  it('shows N/A for a late submission if the grade is hidden from the student', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {
        gradingType: 'points',
        pointsPossible: 10,
      },
      Submission: {
        ...SubmissionMocks.submitted,
        attempt: 1,
        gradeHidden: true,
        submissionStatus: 'late',
      },
    })
    const {container} = render(
      <StudentViewContext.Provider
        value={{lastSubmittedSubmission: props.submission, latestSubmission: props.submission}}
      >
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )
    expect(container).toHaveTextContent(/Attempt 1 Score:\s*N\/A/)
  })

  it('renders the grade for the currently selected attempt', async () => {
    const lastSubmittedSubmission = await mockSubmission({
      Submission: {
        ...SubmissionMocks.graded,
        grade: '147',
        enteredGrade: '147',
      },
    })

    const props = await mockAssignmentAndSubmission({
      Assignment: {pointsPossible: 150},
      Submission: {
        ...SubmissionMocks.graded,
        attempt: 7,
        grade: '131',
        enteredGrade: '131',
        gradingStatus: 'graded',
      },
    })

    const {container} = render(
      <StudentViewContext.Provider
        value={{lastSubmittedSubmission, latestSubmission: props.submission}}
      >
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )

    expect(container).toHaveTextContent(/Attempt 7 Score:\s*131\/150/)
  })

  it('renders "N/A" for the currently selected attempt if it has no grade', async () => {
    const lastSubmittedSubmission = await mockSubmission({
      Submission: {
        ...SubmissionMocks.graded,
        grade: '147',
        enteredGrade: '147',
      },
    })

    const props = await mockAssignmentAndSubmission({
      Assignment: {pointsPossible: 150},
      Submission: {
        ...SubmissionMocks.submitted,
        attempt: 7,
        grade: '131',
        enteredGrade: '131',
        gradingStatus: 'needs_grading',
      },
    })

    const {container} = render(
      <StudentViewContext.Provider
        value={{lastSubmittedSubmission, latestSubmission: props.submission}}
      >
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )

    expect(container).toHaveTextContent(/Attempt 7 Score:\s*N\/A/)
  })

  it('renders "Offline Score" when the student is graded before submitting', async () => {
    const lastSubmittedSubmission = await mockSubmission({
      Submission: {
        ...SubmissionMocks.graded,
        grade: '147',
        enteredGrade: '147',
        attempt: 0,
      },
    })

    const props = await mockAssignmentAndSubmission({
      Assignment: {pointsPossible: 150},
      Submission: {
        ...SubmissionMocks.graded,
        attempt: 0,
        grade: '131',
        enteredGrade: '131',
      },
    })

    const {container} = render(
      <StudentViewContext.Provider
        value={{lastSubmittedSubmission, latestSubmission: props.submission}}
      >
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )

    expect(container).toHaveTextContent(/Offline Score:\s*131\/150/)
  })

  it('renders the attempt select', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    props.allSubmissions = [props.submission]
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    expect(queryByTestId('attemptSelect')).toBeInTheDocument()
  })

  it('does not render the attempt select if there is no submission', async () => {
    const props = await mockAssignmentAndSubmission({Query: {submission: null}})
    props.allSubmissions = [{id: '1', _id: '1'}]
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })
})
