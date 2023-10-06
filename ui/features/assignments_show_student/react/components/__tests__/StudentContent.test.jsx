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

import {fireEvent, render, waitFor, within} from '@testing-library/react'
import {
  mockAssignmentAndSubmission,
  mockSubmission,
  mockQuery,
} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import {initializeReaderButton} from '../../../../../shared/immersive-reader/ImmersiveReader'
import React from 'react'
import StudentViewContext from '../Context'
import StudentContent from '../StudentContent'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import {AssignmentMocks} from '@canvas/assignments/graphql/student/Assignment'
import ContextModuleApi from '../../apis/ContextModuleApi'
import {RUBRIC_QUERY, SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

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
    Course: {
      account: {
        outcomeProficiency: {
          proficiencyRatingsConnection: {
            nodes: [{}],
          },
        },
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
      </MockedProvider>
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
      </MockedProvider>
    )
    expect(getByTestId('assignment-student-header')).toBeInTheDocument()
  })

  it('renders the assignment details and student content if the assignment is unlocked', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByText, queryByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
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
      </MockedProvider>
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
      </MockedProvider>
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
      </MockedProvider>
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
      </StudentViewContext.Provider>
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
      </StudentViewContext.Provider>
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
      </StudentViewContext.Provider>
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
      </MockedProvider>
    )
    expect(queryByTestId('attemptSelect')).toBeInTheDocument()
  })

  it('does not render the attempt select if there is no submission', async () => {
    const props = await mockAssignmentAndSubmission({Submission: null})
    props.allSubmissions = [{id: '1', _id: '1'}]
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('does not render the attempt select if allSubmissions is not provided', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('does not render the attempt select if the assignment has non-digital submissions', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {nonDigitalSubmission: true},
      Submission: {...SubmissionMocks.submitted},
    })
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('does not render the attempt select if peerReviewModeEnabled is set to true', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    props.assignment.env.peerReviewModeEnabled = true
    props.assignment.env.peerReviewAvailable = true
    props.allSubmissions = [props.submission]
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
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('renders the attempt select if peerReviewModeEnabled is set to false', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    props.assignment.env.peerReviewModeEnabled = false
    props.allSubmissions = [props.submission]
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(queryByTestId('attemptSelect')).toBeInTheDocument()
  })

  describe('when the assignment does not expect digital submissions', () => {
    let props

    beforeEach(async () => {
      oldEnv = window.ENV
      window.ENV = {...window.ENV}

      props = await mockAssignmentAndSubmission({
        Assignment: {
          ...AssignmentMocks.onPaper,
          name: 'this is my assignment',
        },
        Submission: {},
      })
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders the assignment details', async () => {
      const {getAllByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getAllByText(/this is my assignment/)).not.toHaveLength(0)
    })

    it('does not render the interface for submitting to the assignment', async () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('assignment-2-student-content-tabs')).not.toBeInTheDocument()
    })

    it('renders LTI Launch Iframe when LTI_TOOL is true', async () => {
      window.ENV.LTI_TOOL = 'true'

      const {getByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      const lti_external_tool = getByTestId('lti-external-tool')
      expect(lti_external_tool).toBeInTheDocument()
    })

    it('does not renders LTI Launch Iframe when LTI_TOOL is false', async () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('lti-external-tool')).not.toBeInTheDocument()
    })

    it('renders a "Mark as Done" button if the assignment is part of a module with a mark-as-done requirement', async () => {
      window.ENV.CONTEXT_MODULE_ITEM = {
        done: false,
        id: '123',
        module_id: '456',
      }

      const {getByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByRole('button', {name: 'Mark as done'})).toBeInTheDocument()
    })

    it('does not render a "Mark as Done" button if the assignment lacks mark-as-done requirements', async () => {
      const {queryByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByRole('button', {name: 'Mark as done'})).not.toBeInTheDocument()
    })

    it('renders the rubric if the assignment has one', async () => {
      window.ENV.ASSIGNMENT_ID = '1'
      window.ENV.COURSE_ID = '1'
      window.ENV.current_user = {id: '2'}
      props.assignment.rubric = {}

      const variables = {
        assignmentLid: '1',
        courseID: '1',
        submissionAttempt: 0,
        submissionID: '1',
      }
      const overrides = {
        Account: {outcomeProficiency: {proficiencyRatingsConnection: null}},
        Assignment: {rubric: {}},
        Course: {id: '1'},
        Node: {__typename: 'Assignment'},
        Rubric: {
          criteria: [],
          title: 'Some On-paper Rubric',
        },
      }
      const result = await mockQuery(RUBRIC_QUERY, overrides, variables)
      const mocks = [
        {
          request: {
            query: RUBRIC_QUERY,
            variables,
          },
          result,
        },
      ]

      const {findByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )

      expect(await findByText('View Rubric')).toBeInTheDocument()
    })

    describe('module links', () => {
      beforeEach(() => {
        window.ENV.ASSIGNMENT_ID = '1'
        window.ENV.COURSE_ID = '1'

        ContextModuleApi.getContextModuleData.mockClear()
      })

      it('renders next and previous module links if they exist for the assignment', async () => {
        ContextModuleApi.getContextModuleData.mockResolvedValue({
          next: {url: '/next', tooltipText: {string: 'Next'}},
          previous: {url: '/previous', tooltipText: {string: 'Previous'}},
        })

        const {getByTestId} = render(
          <MockedProvider>
            <StudentContent {...props} />
          </MockedProvider>
        )
        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())

        const footer = getByTestId('student-footer')
        expect(within(footer).getByRole('link', {name: /Previous/})).toBeInTheDocument()
        expect(within(footer).getByRole('link', {name: /Next/})).toBeInTheDocument()
      })

      it('does not render module links if no next/previous modules exist for the assignment', async () => {
        ContextModuleApi.getContextModuleData.mockResolvedValue({})

        const {queryByRole} = render(
          <MockedProvider>
            <StudentContent {...props} />
          </MockedProvider>
        )
        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())

        expect(queryByRole('link', {name: /Previous/})).not.toBeInTheDocument()
        expect(queryByRole('link', {name: /Next/})).not.toBeInTheDocument()
      })
    })
  })

  describe('when the comments tray is opened', () => {
    const makeMocks = async () => {
      const variables = {submissionAttempt: 0, submissionId: '1'}
      const overrides = {
        Node: {__typename: 'Submission'},
        SubmissionCommentConnection: {nodes: []},
      }
      const result = await mockQuery(SUBMISSION_COMMENT_QUERY, overrides, variables)
      const mocks = [
        {
          request: {
            query: SUBMISSION_COMMENT_QUERY,
            variables,
          },
          result,
        },
      ]
      return mocks
    }

    // https://instructure.atlassian.net/browse/USERS-385

    it.skip('renders Comments', async () => {
      // To be unskipped in EVAL-1679
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )
      fireEvent.click(getByText('Add Comment'))
      await waitFor(() => expect(getByText('Send Comment')).toBeInTheDocument())
    })

    it('renders spinner while lazy loading comments', async () => {
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getAllByTitle, getByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )
      fireEvent.click(getByText('Add Comment'))
      expect(getAllByTitle('Loading')[0]).toBeInTheDocument()
    })
  })

  describe('concluded enrollment notice', () => {
    const concludedMatch = /your enrollment in this course has been concluded/

    beforeEach(() => {
      oldEnv = window.ENV
      window.ENV = {...window.ENV}
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders when the current enrollment is concluded', async () => {
      window.ENV.enrollment_state = 'completed'

      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      expect(getByText(concludedMatch)).toBeInTheDocument()
    })

    it('does not render when the current enrollment is not concluded', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      expect(queryByText(concludedMatch)).not.toBeInTheDocument()
    })
  })

  describe('Unpublished module', () => {
    it('renders UnpublishedModule', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.belongsToUnpublishedModule = true
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        getByText('This assignment is part of an unpublished module and is not available yet.')
      ).toBeInTheDocument()
    })
  })

  describe('Unavailable peer review', () => {
    it('is rendered when peerReviewModeEnabled is true and peerReviewAvailable is false', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true
      props.assignment.env.peerReviewAvailable = false
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
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        getByText('There are no submissions available to review just yet.')
      ).toBeInTheDocument()
      expect(getByText('Please check back soon.')).toBeInTheDocument()
    })

    it('is not rendered when peerReviewModeEnabled is true and peerReviewAvailable is true', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = false
      props.assignment.env.peerReviewAvailable = true
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        queryByText('There are no submissions available to review just yet.')
      ).not.toBeInTheDocument()
      expect(queryByText('Please check back soon.')).not.toBeInTheDocument()
    })

    it('is not rendered when peerReviewModeEnabled is false', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = false
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        queryByText('There are no submissions available to review just yet.')
      ).not.toBeInTheDocument()
      expect(queryByText('Please check back soon.')).not.toBeInTheDocument()
    })
  })

  describe('Immersive Reader', () => {
    let element
    let props

    beforeEach(async () => {
      props = await mockAssignmentAndSubmission({
        Assignment: {
          description: 'description',
          name: 'name',
        },
      })
    })

    afterEach(() => {
      element?.remove()
      initializeReaderButton.mockClear()
    })

    it('sets up Immersive Reader if it finds the mount point', async () => {
      element = document.createElement('div')
      element.id = 'immersive_reader_mount_point'
      document.documentElement.append(element)

      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      await waitFor(() => {
        expect(initializeReaderButton).toHaveBeenCalledWith(element, {
          content: expect.anything(Function),
          title: 'name',
        })

        expect(initializeReaderButton.mock.calls[0][1].content()).toEqual('description')
      })
    })

    it('sets up Immersive Reader if it finds the mobile mount point', async () => {
      element = document.createElement('div')
      element.id = 'immersive_reader_mobile_mount_point'
      document.documentElement.append(element)

      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      await waitFor(() => {
        expect(initializeReaderButton).toHaveBeenCalledWith(element, {
          content: expect.anything(Function),
          title: 'name',
        })

        expect(initializeReaderButton.mock.calls[0][1].content()).toEqual('description')
      })
    })

    it('does not set up Immersive Reader if neither mount point is present', async () => {
      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      await new Promise(resolve => setTimeout(resolve, 0))
      expect(initializeReaderButton).not.toHaveBeenCalled()
    })
  })

  describe('Add Comment/View Feedback button', () => {
    it('renders as "Add Comment" by default', async () => {
      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('Add Comment')).toBeInTheDocument()
    })

    it('shows the unread comments badge if there are unread comments', async () => {
      const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 1}})
      const {getByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByTestId('unread_comments_badge')).toBeInTheDocument()
    })

    it('does not show the unread comments badge if there are no unread comments', async () => {
      const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 0}})
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('unread_comments_badge')).not.toBeInTheDocument()
    })

    it('renders as "Add Comment" by default for nonDigitalSubmission', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {nonDigitalSubmission: true},
        Submission: {...SubmissionMocks.submitted},
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('Add Comment')).toBeInTheDocument()
    })

    it('renders as "View Feedback" for observers', async () => {
      const props = await mockAssignmentAndSubmission()

      const {getByText} = render(
        <StudentViewContext.Provider
          value={{
            allowChangesToSubmission: false,
            isObserver: true,
            latestSubmission: props.submission,
          }}
        >
          <MockedProvider>
            <StudentContent {...props} />
          </MockedProvider>
        </StudentViewContext.Provider>
      )
      expect(getByText('View Feedback')).toBeInTheDocument()
    })

    it('renders as "View Feedback" if feedback exists', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {feedbackForCurrentAttempt: true},
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('View Feedback')).toBeInTheDocument()
    })

    it('renders as "View Feedback" if feedback exists for nonDigitalSubmission', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {nonDigitalSubmission: true},
        Submission: {feedbackForCurrentAttempt: true},
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('View Feedback')).toBeInTheDocument()
    })

    it('renders as "Add Comment" and disabled if unsubmitted attempt>1', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.unsubmitted,
          attempt: 2,
        },
      })
      props.assignment.env.peerReviewModeEnabled = false
      props.assignment.env.peerReviewAvailable = false
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('Add Comment').closest('button')).toBeDisabled()
    })

    it('renders additional info button if unsubmitted attempt>1', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.unsubmitted,
          attempt: 2,
        },
      })
      props.assignment.env.peerReviewModeEnabled = false
      props.assignment.env.peerReviewAvailable = false
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      const screenText = getByText(
        /After the first attempt, you cannot leave comments until you submit the assignment./
      )
      expect(screenText).toBeInTheDocument()
    })

    it('does not render additional info button if unsubmitted attempt==1', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.unsubmitted,
          attempt: 1,
        },
      })
      const {queryByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        queryByRole('button', {
          name: /After the first attempt, you cannot leave comments until you submit the assignment./,
        })
      ).not.toBeInTheDocument()
    })

    it('does not render additional info button if submitted attempt>1', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.submitted,
          attempt: 2,
        },
      })
      const {queryByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        queryByRole('button', {
          name: /After the first attempt, you cannot leave comments until you submit the assignment./,
        })
      ).not.toBeInTheDocument()
    })

    it('does not show the unread comments badge if peerReviewModeEnabled is set to true', async () => {
      const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 1}})
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
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('unread_comments_badge')).not.toBeInTheDocument()
    })

    it('shows the unread comments badge if peerReviewModeEnabled is set to false', async () => {
      const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 1}})
      props.assignment.env.peerReviewModeEnabled = false
      const {getByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByTestId('unread_comments_badge')).toBeInTheDocument()
    })
  })
  describe('submission workflow tracker', () => {
    it('is rendered when a submission exists and the assignment is available', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('submission-workflow-tracker')).toBeInTheDocument()
    })

    it('is not rendered when no submission object is present', async () => {
      const props = await mockAssignmentAndSubmission({Submission: null})
      props.allSubmissions = [{id: '1', _id: '1'}]
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })

    it('is not rendered when there is no current user', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.currentUser = null
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })

    it('is not rendered when the assignment has not been unlocked yet', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.modulePrereq = 'simulate not null'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })

    it('is not rendered when the assignment has uncompleted prerequisites', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.unlockDate = 'soon'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })

    it('is rendered if peerReviewModeEnabled is set to false', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = false
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('submission-workflow-tracker')).toBeInTheDocument()
    })

    it('is not rendered if peerReviewModeEnabled is set to true', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true
      props.assignment.env.peerReviewAvailable = true
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
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })
  })

  describe('originality report', () => {
    it('is rendered when a submission exists with turnitinData attached and the assignment is available with a text entry submission', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_text_entry'},
      })

      props.submission.originalityData = {
        submission_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      props.assignment.env.originalityReportsForA2Enabled = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).toBeInTheDocument()
    })

    it('is not rendered when the originality reports for a2 FF is not enabled', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_text_entry'},
      })
      props.submission.originalityData = {
        submission_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      props.assignment.env.originalityReportsForA2Enabled = false
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when the originality report is not visibile to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_text_entry'},
      })
      props.submission.originalityData = {
        submission_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      const today = new Date()
      const tomorrow = new Date(today)
      tomorrow.setDate(tomorrow.getDate() + 1)
      props.assignment.dueAt = tomorrow.toString()
      props.assignment.originalityReportVisibility = 'after_due_date'
      props.assignment.env.originalityReportsForA2Enabled = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is rendered when the originality report is visibile to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_text_entry'},
      })
      props.submission.originalityData = {
        submission_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      const today = new Date()
      const yesterday = new Date(today)
      yesterday.setDate(yesterday.getDate() - 1)
      props.assignment.dueAt = yesterday.toString()
      props.assignment.originalityReportVisibility = 'after_due_date'
      props.assignment.env.originalityReportsForA2Enabled = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).toBeInTheDocument()
    })

    it('is rendered when a submission exists with turnitinData attached and the assignment is available with a online upload submission with only one attachment', async () => {
      const file = {
        _id: '1',
        displayName: 'file_1.png',
        id: '1',
        mimeClass: 'image',
        submissionPreviewUrl: '/preview_url',
        thumbnailUrl: '/thumbnail_url',
        url: '/url',
      }
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_upload', attachments: [file]},
      })
      props.submission.originalityData = {
        attachment_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      props.assignment.env.originalityReportsForA2Enabled = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).toBeInTheDocument()
    })

    it('is not rendered when a submission exists with turnitinData attached and the assignment is available with a online upload submission with more than one attachment', async () => {
      const files = [
        {
          _id: '1',
          displayName: 'file_1.png',
          id: '1',
          mimeClass: 'image',
          submissionPreviewUrl: '/preview_url',
          thumbnailUrl: '/thumbnail_url',
          url: '/url',
        },
        {
          _id: '1',
          displayName: 'file_1.png',
          id: '1',
          mimeClass: 'image',
          submissionPreviewUrl: '/preview_url',
          thumbnailUrl: '/thumbnail_url',
          url: '/url',
        },
      ]
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_upload', attachments: files},
      })
      props.submission.turnitinData = [
        {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
        {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      ]
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when no submission object is present', async () => {
      const props = await mockAssignmentAndSubmission({Submission: null})
      props.allSubmissions = [{id: '1', _id: '1'}]
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when there is no current user', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.currentUser = null
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when the assignment has not been unlocked yet', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.modulePrereq = 'simulate not null'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when the assignment has uncompleted prerequisites', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.unlockDate = 'soon'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when the submission has no turnitinData', async () => {
      const props = await mockAssignmentAndSubmission()
      props.submission.turnitinData = null
      props.assignment.env.unlockDate = 'soon'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })
  })

  describe('render AnonymousLabel with ungraded submission', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.submission = {
        ...props.submission,
        hideGradeFromStudent: false,
        grade: null,
      }
    })

    it('not renders the anonymous label', () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('assignment-student-anonymous-label')).not.toBeInTheDocument()
    })
  })

  describe('render AnonymousLabel hiding grade from student submission', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.submission = {
        ...props.submission,
        hideGradeFromStudent: true,
        grade: 10,
      }
    })

    it('not renders the anonymous label', () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('assignment-student-anonymous-label')).not.toBeInTheDocument()
    })
  })

  describe('renderAnonymousLabel with graded submission', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.submission = {
        ...props.submission,
        hideGradeFromStudent: false,
        grade: 10,
      }
    })

    it('renders a label graded anonymously', () => {
      props.submission.gradedAnonymously = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('assignment-student-anonymus-label')).toHaveTextContent(
        'Anonymous Grading:yes'
      )
    })

    it('renders a label graded visibly', () => {
      props.submission.gradedAnonymously = false
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('assignment-student-anonymus-label')).toHaveTextContent(
        'Anonymous Grading:no'
      )
    })
  })
})
