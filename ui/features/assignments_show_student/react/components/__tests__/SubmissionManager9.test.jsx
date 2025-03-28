/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {RUBRIC_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import React from 'react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import StudentViewContext, {StudentViewContextDefaults} from '../Context'
import SubmissionManager from '../SubmissionManager'
import store from '../stores'

// Reset all mocks before each test to ensure isolation
beforeEach(() => {
  jest.resetAllMocks()
  ContextModuleApi.getContextModuleData.mockResolvedValue({})
})

// Remove or comment out jest.useFakeTimers() to prevent interference with async operations
//

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

jest.mock('@canvas/rce/RichContentEditor')

jest.mock('../../apis/ContextModuleApi')

jest.mock('@canvas/do-fetch-api-effect')

function renderInContext(overrides = {}, children) {
  const contextProps = {...StudentViewContextDefaults, ...overrides}

  return render(
    <StudentViewContext.Provider value={contextProps}>{children}</StudentViewContext.Provider>,
  )
}

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

describe('SubmissionManager', () => {
  beforeAll(() => {
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  describe('peer reviews', () => {
    describe('without rubrics', () => {
      it('does not render a submit button', async () => {
        const props = await mockAssignmentAndSubmission()
        props.assignment.env.peerReviewModeEnabled = true
        const {queryByText} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        // Wait for any asynchronous operations to complete
        await waitFor(() => {})

        expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
      })
    })

    describe('with rubrics', () => {
      const originalENV = window.ENV
      let props, mocks

      function generateAssessmentItem(
        criterionId,
        {hasComments = false, hasValue = false, hasValidValue = true},
      ) {
        return {
          commentFocus: true,
          comments: hasComments ? 'foo bar' : '',
          criterion_id: criterionId,
          description: `Criterion ${criterionId}`,
          editComments: true,
          id: 'blank',
          points: {
            text: '',
            valid: hasValidValue,
            value: hasValue ? Math.floor(Math.random() * 10) : undefined,
          },
        }
      }

      function setCurrentUserAsAssessmentOwner() {
        window.ENV = {...originalENV, COURSE_ID: '4', current_user: {id: '2'}}
      }

      function setOtherUserAsAssessmentOwner() {
        window.ENV = {...originalENV, COURSE_ID: '4', current_user: {id: '4'}}
      }

      async function setMocks() {
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
        mocks = [
          {
            request: {query: RUBRIC_QUERY, variables},
            result: fetchRubricResult,
          },
          {
            request: {query: RUBRIC_QUERY, variables},
            result: fetchRubricResult,
          },
        ]
      }

      beforeEach(async () => {
        doFetchApi.mockClear()
        doFetchApi.mockResolvedValue({})
        setCurrentUserAsAssessmentOwner()
        await setMocks()
        await waitFor(() => {})
        const rubricData = mocks[0].result.data
        const assessments = rubricData.submission.rubricAssessmentsConnection.nodes

        store.setState({
          displayedAssessment: assessments[0],
        })

        props = await mockAssignmentAndSubmission()
        props.assignment.rubric = rubricData.assignment.rubric
        props.assignment.rubric.criteria.push({...props.assignment.rubric.criteria[0], id: '2'})
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true
        props.assignment.env.revieweeId = '4'
      })

      afterEach(() => {
        window.ENV = originalENV
        store.setState({
          displayedAssessment: null,
        })
      })

      it('renders a submit button when the assessment has not been submitted', async () => {
        setOtherUserAsAssessmentOwner()
        const {queryByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        expect(queryByText('Submit')).toBeInTheDocument()
      })

      it('does not render a submit button when the assessment has been submitted', async () => {
        const {queryByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        expect(queryByText('Submit')).not.toBeInTheDocument()
      })

      it('renders an enabled submit button when every criterion has a comment', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByTestId} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        expect(getByTestId('submit-peer-review-button')).toBeEnabled()
      })

      it('renders an enabled submit button when every criterion has a valid point', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasValue: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasValue: true}),
            ],
          },
        })

        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true

        const {getByTestId} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        expect(getByTestId('submit-peer-review-button')).toBeEnabled()
      })

      it('renders a disabled submit button when at least one criterion has an invalid points value', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasValue: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {
                hasValue: true,
                hasValidValue: false,
              }),
            ],
          },
        })

        const {getByTestId} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        expect(getByTestId('submit-peer-review-button')).toBeDisabled()
      })

      it('sends a http request with anonymous peer reviews disabled to the rubrics assessments endpoint when the user clicks on Submit button', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByTestId} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        fireEvent.click(getByTestId('submit-peer-review-button'))

        const rubricAssociationId = mocks[0].result.data.assignment.rubricAssociation._id
        expect(doFetchApi).toHaveBeenCalledWith(
          expect.objectContaining({
            method: 'POST',
            path: `/courses/${window.ENV.COURSE_ID}/rubric_associations/${rubricAssociationId}/assessments`,
            body: expect.stringContaining('user_id%5D=4'),
          }),
        )
      })

      it('sends a http request with anonymous peer reviews enabled to the rubrics assessments endpoint when the user clicks on Submit button', async () => {
        delete props.assignment.env.revieweeId
        props.assignment.env.anonymousAssetId = 'ad0f'

        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByTestId} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        fireEvent.click(getByTestId('submit-peer-review-button'))

        const rubricAssociationId = mocks[0].result.data.assignment.rubricAssociation._id
        expect(doFetchApi).toHaveBeenCalledWith(
          expect.objectContaining({
            method: 'POST',
            path: `/courses/${window.ENV.COURSE_ID}/rubric_associations/${rubricAssociationId}/assessments`,
            body: expect.stringContaining('anonymous_id%5D=ad0f'),
          }),
        )
      })

      it('creates a success alert when the http request was sent successfully', async () => {
        setOtherUserAsAssessmentOwner()
        const setOnSuccess = jest.fn()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByTestId} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        fireEvent.click(getByTestId('submit-peer-review-button'))

        await waitFor(() => {
          expect(setOnSuccess).toHaveBeenCalledWith('Rubric was successfully submitted')
        })
      })

      it('renders peer review modal for remaining rubric assessments', async () => {
        setOtherUserAsAssessmentOwner()
        const reviewerSubmission = {
          id: 'test-id',
          _id: 'test-id',
          assignedAssessments: [
            {
              assetId: props.submission._id,
              workflowState: 'assigned',
              assetSubmissionType: 'online-text',
            },
            {
              assetId: 'some other user id',
              workflowState: 'assigned',
              assetSubmissionType: 'online-text',
            },
          ],
        }
        props.reviewerSubmission = reviewerSubmission
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true

        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByTestId} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        await waitFor(() => {
          expect(getByTestId('submit-peer-review-button')).toBeInTheDocument()
        })

        fireEvent.click(getByTestId('submit-peer-review-button'))

        await waitFor(() => {
          expect(getByTestId('peer-review-prompt-modal')).toBeInTheDocument()
        })
      })

      it.skip('renders peer review modal for completing all rubric assessments', async () => {
        setOtherUserAsAssessmentOwner()
        const reviewerSubmission = {
          id: 'test-id',
          _id: 'test-id',
          assignedAssessments: [
            {
              assetId: '1',
              anonymousId: null,
              workflowState: 'assigned',
              anonymousUser: false,
            },
            {
              assetId: '2',
              anonymousId: null,
              workflowState: 'assigned',
              anonymousUser: false,
            },
          ],
        }

        // Set up peer review mode
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true
        props.reviewerSubmission = reviewerSubmission

        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByTestId} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
            <MockedProvider mocks={mocks} addTypename={false}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>,
        )

        // Wait for Apollo cache to settle
        await waitFor(() => {})

        // Wait for the submit button to be enabled
        const submitButton = await waitFor(() => getByTestId('submit-peer-review-button'))
        expect(submitButton).toBeEnabled()

        // Click the submit button
        fireEvent.click(submitButton)

        // Verify modal appears using screen since it's rendered at the root level
        await waitFor(() => {
          const modal = screen.getByTestId('peer-review-prompt-modal')
          expect(modal).toBeInTheDocument()
        })
      })

      it('calls the onSuccessfulPeerReview function to re-render page when a peer review with rubric is successful', async () => {
        setOtherUserAsAssessmentOwner()
        props.onSuccessfulPeerReview = jest.fn()
        const reviewerSubmission = {
          id: 'test-id',
          _id: 'test-id',
          assignedAssessments: [
            {
              assetId: props.submission._id,
              workflowState: 'assigned',
              assetSubmissionType: 'online-text',
            },
          ],
        }
        props.reviewerSubmission = reviewerSubmission
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true

        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByTestId} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        await waitFor(() => {
          expect(getByTestId('submit-peer-review-button')).toBeInTheDocument()
        })

        fireEvent.click(getByTestId('submit-peer-review-button'))

        await waitFor(() => {
          expect(props.onSuccessfulPeerReview).toHaveBeenCalled()
        })
      })

      it('creates an error alert when the http request fails', async () => {
        setOtherUserAsAssessmentOwner()
        doFetchApi.mockImplementation(() => Promise.reject(new Error('Network error')))
        const setOnFailure = jest.fn()

        // Set up peer review mode
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true

        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByTestId} = render(
          <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess: jest.fn()}}>
            <MockedProvider mocks={mocks} addTypename={false}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>,
        )

        // Wait for Apollo cache to settle
        await waitFor(() => {})

        // Wait for the submit button to be enabled
        const submitButton = await waitFor(() => getByTestId('submit-peer-review-button'))
        expect(submitButton).toBeEnabled()

        // Click the submit button
        fireEvent.click(submitButton)

        // Verify error alert is shown
        await waitFor(() => {
          expect(setOnFailure).toHaveBeenCalledWith('Error submitting rubric')
        })
      })
    })
  })
})
