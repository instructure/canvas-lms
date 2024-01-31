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
import {AssignmentMocks} from '@canvas/assignments/graphql/student/Assignment'

jest.mock('../AttemptSelect')
jest.mock('../CommentsTray', () => () => '')

// EVAL-3711 Remove ICE Feature Flag

beforeEach(() => {
  window.ENV.FEATURES ||= {}
  window.ENV.FEATURES.instui_nav = true
})

afterEach(() => {
  // @ts-expect-error
  window.ENV = {}
})

it('renders normally', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('assignment-student-header')).toBeInTheDocument()
})

it('renders a "late" status pill if the last graded submission is late', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10,
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      submissionStatus: 'late',
    },
  })
  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByText('Late')).toBeInTheDocument()
})

it('renders a custom status pill if the last graded submission has a custom status', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10,
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      customGradeStatus: 'Carrot',
    },
  })
  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByText('Carrot')).toBeInTheDocument()
})

it('prioritizes rendering custom status pills over other pills', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10,
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      customGradeStatus: 'Carrot',
      submissionStatus: 'late',
      gradingStatus: 'excused',
    },
  })
  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByText('Carrot')).toBeInTheDocument()
})

it('renders the singular word Point when the assignment is set to one possible point', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 1,
    },
  })
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('grade-display')).toHaveTextContent('1 Point Possible')
})

it('renders the plural word Points when the assignment is set to multiple points ', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 100,
    },
  })
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('grade-display')).toHaveTextContent('100 Points Possible')
})

it('shows the grade for a late submission if it is not hidden from the student', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10,
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      gradeHidden: false,
      submissionStatus: 'late',
    },
  })
  const {getByTestId} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByTestId('grade-display')).toHaveTextContent('6/10 Points')
})

it('shows the number of points deducted in the tooltip when the current grade is focused', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10,
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      submissionStatus: 'late',
    },
  })

  const {getByText, getByTestId} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  const pointsDisplay = getByTestId('grade-display')
  fireEvent.focus(pointsDisplay)
  expect(getByText('Late Penalty')).toBeInTheDocument()
  expect(getByText('-4')).toBeInTheDocument()
})

it('does not show the late policy tooltip when restrict_quantitative_data is truthy', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10,
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      submissionStatus: 'late',
    },
  })

  window.ENV.restrict_quantitative_data = true

  const {queryByText, getByTestId} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  const gradeDisplay = getByTestId('grade-display')
  fireEvent.focus(gradeDisplay)
  expect(queryByText('Late Penalty')).not.toBeInTheDocument()
  expect(queryByText('-4')).not.toBeInTheDocument()
})

it('renders a "missing" status pill if the last graded submission is missing', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      submissionStatus: 'missing',
    },
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
    Submission: SubmissionMocks.graded,
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
      enteredGrade: '147',
    },
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      grade: '131',
      enteredGrade: '131',
    },
  })

  const {getByTestId} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByTestId('grade-display')).toHaveTextContent('147/150 Points')
})

it('will not render the grade if the last submitted submission is excused', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.excused,
      grade: '147',
      enteredGrade: '147',
    },
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      grade: '131',
      enteredGrade: '131',
    },
  })

  const {getByTestId} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(getByTestId('grade-display').textContent).toEqual('Excused')
})

describe('Peer reviews counter', () => {
  it('is displayed when peerReviewModeEnabled is set to true', async () => {
    window.ENV.FEATURES.instui_nav = false
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.peerReviewModeEnabled = true
    props.reviewerSubmission = {
      ...props.submission,
      assignedAssessments: [
        {
          assetId: '1',
          anonymousUser: null,
          anonymousId: 'xaU9cd',
          workflowState: 'assigned',
          assetSubmissionType: 'online_text_entry',
        },
      ],
    }
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('current-counter')).toBeInTheDocument()
    expect(queryByTestId('total-counter')).toBeInTheDocument()
  })

  it('is not displayed when peerReviewModeEnabled is set to false', async () => {
    window.ENV.FEATURES.instui_nav = false
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.peerReviewModeEnabled = false
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('current-counter')).not.toBeInTheDocument()
    expect(queryByTestId('total-counter')).not.toBeInTheDocument()
  })

  describe('with anonymous peer reviews enabled', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true
      props.reviewerSubmission = {
        ...props.submission,
        assignedAssessments: [
          {
            assetId: '1',
            anonymousId: 'xaU9cd',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
          {
            assetId: '2',
            anonymousId: 'maT9fd',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
          {
            assetId: '3',
            anonymousId: 'vaN9fd',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      }
    })

    it('sets 1 as "current-counter" when anonymousId matches the first assigned assessment"', async () => {
      window.ENV.FEATURES.instui_nav = false
      props.assignment.env.anonymousAssetId =
        props.reviewerSubmission.assignedAssessments[0].anonymousId
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('current-counter')).toHaveTextContent('1')
    })

    it('sets assigned assessments count as "current-counter" when anonymousId matches the last assigned assessment"', async () => {
      window.ENV.FEATURES.instui_nav = false
      props.assignment.env.anonymousAssetId =
        props.reviewerSubmission.assignedAssessments[2].anonymousId
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('current-counter')).toHaveTextContent('3')
    })

    it('sets 0 as "current-counter when there are no matches for the anonymousId"', async () => {
      window.ENV.FEATURES.instui_nav = false
      props.assignment.env.anonymousAssetId = '0baCxm'
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('current-counter')).toHaveTextContent('0')
    })
  })

  describe('with anonymous peer reviews disabled', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true
      props.reviewerSubmission = {
        ...props.submission,
        assignedAssessments: [
          {
            assetId: '1',
            anonymizedUser: {_id: '1', displayName: 'Jim'},
            anonymousId: null,
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
          {
            assetId: '2',
            anonymizedUser: {_id: '2', displayName: 'Bob'},
            anonymousId: null,
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
          {
            assetId: '3',
            anonymizedUser: {_id: '3', displayName: 'Tim'},
            anonymousId: null,
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      }
    })

    it('sets 1 as "current-counter" when reviewerId matches the first assigned assessment"', async () => {
      window.ENV.FEATURES.instui_nav = false
      props.assignment.env.revieweeId =
        props.reviewerSubmission.assignedAssessments[0].anonymizedUser._id
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('current-counter')).toHaveTextContent('1')
    })

    it('sets assigned assessments count as "current-counter" when reviewerId matches the last assigned assessment"', async () => {
      window.ENV.FEATURES.instui_nav = false
      props.assignment.env.revieweeId =
        props.reviewerSubmission.assignedAssessments[2].anonymizedUser._id
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('current-counter')).toHaveTextContent('3')
    })

    it('sets 0 as "current-counter when there are no matches for the reviewerId"', async () => {
      window.ENV.FEATURES.instui_nav = false
      props.assignment.env.revieweeId = '4'
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('current-counter')).toHaveTextContent('0')
    })
  })

  it('uses the assigned assessments array length as "total counter"', async () => {
    window.ENV.FEATURES.instui_nav = false
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.peerReviewModeEnabled = true
    props.reviewerSubmission = {
      ...props.submission,
      assignedAssessments: [
        {
          assetId: '1',
          anonymousId: 'xaU9cd',
          workflowState: 'assigned',
          assetSubmissionType: 'online_text_entry',
        },
        {
          assetId: '2',
          anonymousId: 'maT9fd',
          workflowState: 'assigned',
          assetSubmissionType: 'online_text_entry',
        },
      ],
    }
    const {queryByTestId} = render(<Header {...props} />)
    const assessmentsCount = props.reviewerSubmission.assignedAssessments.length
    expect(queryByTestId('total-counter')).toHaveTextContent(assessmentsCount.toString())
  })

  describe('required peer reviews link in assignment header with peer review mode disabled', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      props.allSubmissions = [props.submission]
      props.assignment.env.peerReviewModeEnabled = false
      props.submission.assignedAssessments = [
        {
          assetId: '1',
          anonymizedUser: {_id: '1', displayName: 'Jim'},
          anonymousId: null,
          workflowState: 'assigned',
          assetSubmissionType: null,
        },
      ]
    })

    it('renders the required peer review link with peer reviews assigned', () => {
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('assignment-student-header')).toHaveTextContent('Required Peer Reviews')
    })

    it('does not render the required peer review link with the number of peer reviews assigned when no peer reviews are assigned', () => {
      props.submission.assignedAssessments = []
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('header-peer-review-link')).toBeNull()
    })
  })

  describe('required peer reviews link in assignment header with peer review mode enabled', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true
    })

    it('renders the required peer review link with peer reviews assigned when both the reviewer and reviewee have submitted to the assignment', () => {
      props.reviewerSubmission = {
        ...props.submission,
        assignedAssessments: [
          {
            assetId: '1',
            anonymousUser: null,
            anonymousId: 'xaU9cd',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      }
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('assignment-student-header')).toHaveTextContent('Required Peer Reviews')
    })

    it('renders the required peer review link with peer reviews assigned when no reviews are ready or reviewer has not submitted to the assignment', () => {
      props.reviewerSubmission = null
      props.peerReviewLinkData = {
        ...props.submission,
        assignedAssessments: [
          {
            assetId: '1',
            anonymousUser: null,
            anonymousId: 'xaU9cd',
            workflowState: 'assigned',
            assetSubmissionType: null,
          },
        ],
      }
      const {queryByTestId} = render(<Header {...props} />)
      expect(queryByTestId('assignment-student-header')).toHaveTextContent('Required Peer Reviews')
    })
  })

  describe('number of attempts', () => {
    it('renders the number of attempts with one attempt', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1},
      })

      const {getByText} = render(<Header {...props} />)
      expect(getByText('1 Attempt')).toBeInTheDocument()
    })

    it('renders the number of attempts with unlimited attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: null},
      })
      const {getByText} = render(<Header {...props} />)
      expect(getByText('Unlimited Attempts')).toBeInTheDocument()
    })

    it('renders the number of attempts with multiple attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3},
      })
      const {getByText} = render(<Header {...props} />)
      expect(getByText('3 Attempts')).toBeInTheDocument()
    })

    it('does not render the number of attempts if the assignment does not involve digital submissions', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {...AssignmentMocks.onPaper},
      })

      const {queryByText} = render(<Header {...props} />)
      expect(queryByText('3 Attempts')).not.toBeInTheDocument()
    })

    it('does not render the number of attempts if peer review mode is enabled', async () => {
      window.ENV.current_user = {id: '2'}
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3},
      })
      props.assignment.env.peerReviewModeEnabled = true
      props.assignment.env.peerReviewAvailable = true
      props.reviewerSubmission = {
        ...props.submission,
        assignedAssessments: [
          {
            anonymousUser: null,
            anonymousId: 'xaU9cd',
            workflowState: 'assigned',
          },
        ],
      }
      const {queryByText} = render(<Header {...props} />)
      expect(queryByText('3 Attempts')).not.toBeInTheDocument()
    })

    it('takes into account extra attempts awarded to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3},
        Submission: {attempt: 1, extraAttempts: 1},
      })
      const {getByText} = render(
        <StudentViewContext.Provider value={{latestSubmission: {extraAttempts: 2}}}>
          <Header {...props} />
        </StudentViewContext.Provider>
      )
      expect(getByText('5 Attempts')).toBeInTheDocument()
    })

    it('treats a null value for extraAttempts as zero', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3},
        Submission: {extraAttempts: null},
      })
      const {getByText} = render(<Header {...props} />)
      expect(getByText('3 Attempts')).toBeInTheDocument()
    })
  })

  describe('availability dates', () => {
    it('renders AvailabilityDates', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          unlockAt: '2016-07-11T18:00:00-01:00',
          lockAt: '2016-11-11T18:00:00-01:00',
        },
      })
      const {getAllByText} = render(<Header {...props} />)
      // Reason why this is showing up twice is once for screenreader content and again for regular content
      expect(getAllByText('Available: Jul 11, 2016 7:00pm until Nov 11, 2016 7:00pm')).toHaveLength(
        2
      )
    })
  })
})
