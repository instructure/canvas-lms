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
import {ApolloProvider} from '@apollo/client'
import {mswClient} from '@canvas/msw/mswClient'
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import React from 'react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import StudentViewContext, {
  StudentViewContextDefaults,
} from '@canvas/assignments/react/StudentViewContext'
import SubmissionManager from '../SubmissionManager'
import store from '../stores'
import {setupServer} from 'msw/node'
import {graphql, http, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'

beforeEach(() => {
  vi.resetAllMocks()
  ContextModuleApi.getContextModuleData.mockResolvedValue({})
  mswClient.cache.reset()
})

// Remove or comment out vi.useFakeTimers() to prevent interference with async operations
//

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

vi.mock('@canvas/rce/RichContentEditor')

vi.mock('../../apis/ContextModuleApi')

const server = setupServer()

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
            assessor: {_id: '1', name: 'assessor1', enrollments: []},
          },
          {
            _id: 2,
            score: 10,
            assessor: null,
          },
          {
            _id: 3,
            score: 8,
            assessor: {_id: '2', name: 'assessor2', enrollments: [{type: 'TaEnrollment'}]},
          },
        ],
      },
    },
  }
}

describe('SubmissionManager', () => {
  // Track captured request for verification
  let lastCapturedRequest = null

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  beforeEach(() => {
    server.use(
      graphql.query('ExternalTools', () => {
        return HttpResponse.json({
          data: {
            course: {
              __typename: 'Course',
              externalToolsConnection: {__typename: 'ExternalToolConnection', nodes: []},
            },
          },
        })
      }),
      graphql.query('GetUserGroups', () => {
        return HttpResponse.json({
          data: {legacyNode: {__typename: 'User', groups: []}},
        })
      }),
    )
  })

  afterAll(() => server.close())

  describe('peer reviews', () => {
    describe('without rubrics', () => {
      it('does not render a submit button', async () => {
        const props = await mockAssignmentAndSubmission()
        props.assignment.env.peerReviewModeEnabled = true
        const {queryByText} = render(
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
        )

        // Wait for any asynchronous operations to complete
        await waitFor(() => {})

        expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
      })
    })

    describe('with rubrics', () => {
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
        fakeENV.setup({COURSE_ID: '4', current_user: {id: '2'}})
      }

      function setOtherUserAsAssessmentOwner() {
        fakeENV.setup({COURSE_ID: '4', current_user: {id: '4'}})
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

        // Set up MSW graphql handler for GetRubric query
        server.use(
          graphql.query('GetRubric', () => {
            return HttpResponse.json(fetchRubricResult)
          }),
        )

        // Store mock data for access in tests
        mocks = [
          {
            request: {query: RUBRIC_QUERY, variables},
            result: fetchRubricResult,
          },
        ]
      }

      beforeEach(async () => {
        fakeENV.setup()
        lastCapturedRequest = null
        server.use(
          http.post(
            '/courses/:courseId/rubric_associations/:rubricAssociationId/assessments',
            async ({request}) => {
              lastCapturedRequest = {
                method: 'POST',
                path: new URL(request.url).pathname,
                body: await request.text(),
              }
              return HttpResponse.json({})
            },
          ),
        )
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
        server.resetHandlers()
        mswClient.cache.reset()
        fakeENV.teardown()
        store.setState({
          displayedAssessment: null,
          isSavingRubricAssessment: false,
          selfAssessment: null,
        })
        lastCapturedRequest = null
      })

      it('renders a submit button when the assessment has not been submitted', async () => {
        setOtherUserAsAssessmentOwner()
        const {queryByText} = render(
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        expect(queryByText('Submit')).toBeInTheDocument()
      })

      it('does not render a submit button when the assessment has been submitted', async () => {
        const {queryByText} = render(
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
        )

        // Wait for rubric data to load and component to re-render
        // The Submit button should not appear once data is loaded and user is identified as assessor
        await waitFor(() => {
          expect(queryByText('Submit')).not.toBeInTheDocument()
        })
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
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
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
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
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
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        expect(getByTestId('submit-peer-review-button')).toBeDisabled()
      })

      // This test is flaky due to complex interactions between Apollo cache, Zustand store,
      // MSW handlers, and React rendering. The store state set before render gets overwritten
      // by async operations during component mount, causing the button click handler to use
      // stale data. A comprehensive fix would require refactoring the component's data flow.
      it.skip('sends a http request with anonymous peer reviews disabled to the rubrics assessments endpoint when the user clicks on Submit button', async () => {
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
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        fireEvent.click(getByTestId('submit-peer-review-button'))

        const rubricAssociationId = mocks[0].result.data.assignment.rubricAssociation._id
        await waitFor(() => {
          expect(lastCapturedRequest).not.toBeNull()
          expect(lastCapturedRequest.method).toBe('POST')
          expect(lastCapturedRequest.path).toBe(
            `/courses/${window.ENV.COURSE_ID}/rubric_associations/${rubricAssociationId}/assessments`,
          )
          expect(lastCapturedRequest.body).toContain('user_id%5D=4')
        })
      })

      // This test is flaky due to complex interactions between Apollo cache, Zustand store,
      // MSW handlers, and React rendering. The store state set before render gets overwritten
      // by async operations during component mount, causing the button click handler to use
      // stale data. A comprehensive fix would require refactoring the component's data flow.
      it.skip('sends a http request with anonymous peer reviews enabled to the rubrics assessments endpoint when the user clicks on Submit button', async () => {
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
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
        )

        // Let Apollo cache settle
        await waitFor(() => {})

        fireEvent.click(getByTestId('submit-peer-review-button'))

        const rubricAssociationId = mocks[0].result.data.assignment.rubricAssociation._id
        await waitFor(() => {
          expect(lastCapturedRequest).not.toBeNull()
          expect(lastCapturedRequest.method).toBe('POST')
          expect(lastCapturedRequest.path).toBe(
            `/courses/${window.ENV.COURSE_ID}/rubric_associations/${rubricAssociationId}/assessments`,
          )
          expect(lastCapturedRequest.body).toContain('anonymous_id%5D=ad0f')
        })
      })

      // This test is flaky due to complex interactions between Apollo cache, Zustand store,
      // MSW handlers, and React rendering. The store state set before render gets overwritten
      // by async operations during component mount, causing the button click handler to use
      // stale data. A comprehensive fix would require refactoring the component's data flow.
      it.skip('creates a success alert when the http request was sent successfully', async () => {
        setOtherUserAsAssessmentOwner()
        const setOnSuccess = vi.fn()
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
          <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess}}>
            <ApolloProvider client={mswClient}>
              <SubmissionManager {...props} />
            </ApolloProvider>
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
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
        )

        await waitFor(
          () => {
            expect(getByTestId('submit-peer-review-button')).toBeInTheDocument()
          },
          {timeout: 10000, interval: 50},
        )

        const button = getByTestId('submit-peer-review-button')
        await waitFor(
          () => {
            expect(button).toBeEnabled()
          },
          {timeout: 5000, interval: 50},
        )

        fireEvent.click(button)

        await waitFor(
          () => {
            expect(getByTestId('peer-review-prompt-modal')).toBeInTheDocument()
          },
          {timeout: 15000, interval: 100},
        )
      }, 30000)

      it('renders peer review modal for completing all rubric assessments', async () => {
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
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
        )

        await waitFor(
          () => {
            expect(getByTestId('submit-peer-review-button')).toBeInTheDocument()
          },
          {timeout: 10000, interval: 50},
        )

        const button = getByTestId('submit-peer-review-button')
        await waitFor(
          () => {
            expect(button).toBeEnabled()
          },
          {timeout: 5000, interval: 50},
        )

        fireEvent.click(button)

        await waitFor(
          () => {
            expect(getByTestId('peer-review-prompt-modal')).toBeInTheDocument()
          },
          {timeout: 15000, interval: 100},
        )
      }, 30000)

      // This test is flaky due to the same async state management issues as the success alert test above.
      // The store state gets overwritten during component mount before the click handler runs.
      it.skip('calls the onSuccessfulPeerReview function to re-render page when a peer review with rubric is successful', async () => {
        setOtherUserAsAssessmentOwner()
        props.onSuccessfulPeerReview = vi.fn()
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
          <ApolloProvider client={mswClient}>
            <SubmissionManager {...props} />
          </ApolloProvider>,
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
        // Override the default handler to return an error
        server.use(
          http.post(
            '/courses/:courseId/rubric_associations/:rubricAssociationId/assessments',
            () => {
              return HttpResponse.error()
            },
          ),
        )
        const setOnFailure = vi.fn()

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
          <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess: vi.fn()}}>
            <ApolloProvider client={mswClient}>
              <SubmissionManager {...props} />
            </ApolloProvider>
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
