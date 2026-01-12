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
import {act, fireEvent, render, screen, waitFor, cleanup} from '@testing-library/react'
import React from 'react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import SubmissionManager from '../SubmissionManager'
import store from '../stores'
import {setupServer} from 'msw/node'
import {graphql, http, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

vi.mock('@canvas/rce/RichContentEditor')

vi.mock('../../apis/ContextModuleApi')

const server = setupServer()

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
      value: hasValue ? 5 : undefined,
    },
  }
}

function resetStore() {
  store.setState({
    displayedAssessment: null,
    isSavingRubricAssessment: false,
    selfAssessment: null,
  })
}

describe('SubmissionManager', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    vi.resetAllMocks()
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
    mswClient.cache.reset()
    resetStore()

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

  afterEach(() => {
    cleanup()
    server.resetHandlers()
    mswClient.cache.reset()
    vi.clearAllMocks()
    resetStore()
  })

  describe('peer reviews without rubrics', () => {
    it('does not render a submit button', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true

      render(
        <ApolloProvider client={mswClient}>
          <SubmissionManager {...props} />
        </ApolloProvider>,
      )

      expect(screen.queryByText('Submit Assignment')).not.toBeInTheDocument()
    })
  })
})

describe('SubmissionManager peer reviews with rubrics - submit button states', () => {
  let props
  let mocks

  async function setupRubricMocks() {
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

    server.use(
      graphql.query('GetRubric', () => {
        return HttpResponse.json(fetchRubricResult)
      }),
    )

    mocks = [
      {
        request: {query: RUBRIC_QUERY, variables},
        result: fetchRubricResult,
      },
    ]
  }

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(async () => {
    vi.resetAllMocks()
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
    mswClient.cache.reset()
    resetStore()

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
      http.post('/courses/:courseId/rubric_associations/:rubricAssociationId/assessments', () => {
        return HttpResponse.json({})
      }),
    )

    fakeENV.setup({COURSE_ID: '4', current_user: {id: '4'}})
    await setupRubricMocks()
    const rubricData = mocks[0].result.data

    props = await mockAssignmentAndSubmission()
    props.assignment.rubric = rubricData.assignment.rubric
    props.assignment.rubric.criteria.push({...props.assignment.rubric.criteria[0], id: '2'})
    props.assignment.env.peerReviewModeEnabled = true
    props.assignment.env.peerReviewAvailable = true
    props.assignment.env.revieweeId = '4'
  })

  afterEach(() => {
    cleanup()
    server.resetHandlers()
    mswClient.cache.reset()
    vi.clearAllMocks()
    fakeENV.teardown()
    resetStore()
  })

  it('renders a submit button when the assessment has not been submitted', async () => {
    store.setState({
      displayedAssessment: {
        score: 5,
        data: [
          generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
          generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
        ],
      },
    })

    render(
      <ApolloProvider client={mswClient}>
        <SubmissionManager {...props} />
      </ApolloProvider>,
    )

    await waitFor(() => {
      expect(screen.queryByText('Submit')).toBeInTheDocument()
    })
  })

  it('does not render a submit button when the assessment has been submitted', async () => {
    fakeENV.setup({COURSE_ID: '4', current_user: {id: '2'}})
    store.setState({
      displayedAssessment: mocks[0].result.data.submission.rubricAssessmentsConnection.nodes[0],
    })

    render(
      <ApolloProvider client={mswClient}>
        <SubmissionManager {...props} />
      </ApolloProvider>,
    )

    await waitFor(() => {
      expect(screen.queryByText('Submit')).not.toBeInTheDocument()
    })
  })

  it('renders an enabled submit button when every criterion has a comment', async () => {
    store.setState({
      displayedAssessment: {
        score: 5,
        data: [
          generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
          generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
        ],
      },
    })

    render(
      <ApolloProvider client={mswClient}>
        <SubmissionManager {...props} />
      </ApolloProvider>,
    )

    const button = await screen.findByTestId('submit-peer-review-button')
    expect(button).toBeEnabled()
  })

  it('renders an enabled submit button when every criterion has a valid point', async () => {
    store.setState({
      displayedAssessment: {
        score: 5,
        data: [
          generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasValue: true}),
          generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasValue: true}),
        ],
      },
    })

    render(
      <ApolloProvider client={mswClient}>
        <SubmissionManager {...props} />
      </ApolloProvider>,
    )

    const button = await screen.findByTestId('submit-peer-review-button')
    expect(button).toBeEnabled()
  })

  it('renders a disabled submit button when at least one criterion has an invalid points value', async () => {
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

    render(
      <ApolloProvider client={mswClient}>
        <SubmissionManager {...props} />
      </ApolloProvider>,
    )

    const button = await screen.findByTestId('submit-peer-review-button')
    expect(button).toBeDisabled()
  })
})

describe('SubmissionManager peer reviews with rubrics - modal and error handling', () => {
  let props
  let mocks

  async function setupRubricMocks() {
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

    server.use(
      graphql.query('GetRubric', () => {
        return HttpResponse.json(fetchRubricResult)
      }),
    )

    mocks = [
      {
        request: {query: RUBRIC_QUERY, variables},
        result: fetchRubricResult,
      },
    ]
  }

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(async () => {
    vi.resetAllMocks()
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
    mswClient.cache.reset()
    resetStore()

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

    fakeENV.setup({COURSE_ID: '4', current_user: {id: '4'}})
    await setupRubricMocks()
    const rubricData = mocks[0].result.data

    props = await mockAssignmentAndSubmission()
    props.assignment.rubric = rubricData.assignment.rubric
    props.assignment.rubric.criteria.push({...props.assignment.rubric.criteria[0], id: '2'})
    props.assignment.env.peerReviewModeEnabled = true
    props.assignment.env.peerReviewAvailable = true
    props.assignment.env.revieweeId = '4'
  })

  afterEach(() => {
    cleanup()
    server.resetHandlers()
    mswClient.cache.reset()
    vi.clearAllMocks()
    fakeENV.teardown()
    resetStore()
  })

  it('renders peer review modal when submit button is clicked', async () => {
    let postRequestCompleted = false

    // Reset cache to ensure fresh GraphQL query
    mswClient.cache.reset()

    server.use(
      graphql.query('GetRubric', () => {
        return HttpResponse.json(mocks[0].result)
      }),
      http.post(
        '/courses/:courseId/rubric_associations/:rubricAssociationId/assessments',
        async () => {
          postRequestCompleted = true
          return HttpResponse.json({})
        },
      ),
    )

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
          assetId: 'some-other-user-id',
          workflowState: 'assigned',
          assetSubmissionType: 'online-text',
        },
      ],
    }
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

    render(
      <ApolloProvider client={mswClient}>
        <SubmissionManager {...props} />
      </ApolloProvider>,
    )

    // Wait for the submit button to be enabled (indicates component is ready)
    const button = await screen.findByTestId('submit-peer-review-button')
    await waitFor(() => {
      expect(button).toBeEnabled()
    })

    // Give time for rubricData to be fetched and set in component state
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 100))
    })

    await act(async () => {
      fireEvent.click(button)
    })

    // Wait for the POST request to complete
    await waitFor(() => {
      expect(postRequestCompleted).toBe(true)
    })

    // Wait for modal to appear
    await waitFor(() => {
      expect(screen.getByTestId('peer-review-prompt-modal')).toBeInTheDocument()
    })
  })

  it('creates an error alert when the http request fails', async () => {
    // Reset cache to ensure fresh GraphQL query
    mswClient.cache.reset()

    server.use(
      http.post('/courses/:courseId/rubric_associations/:rubricAssociationId/assessments', () => {
        return HttpResponse.error()
      }),
    )
    const setOnFailure = vi.fn()

    store.setState({
      displayedAssessment: {
        score: 5,
        data: [
          generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
          generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
        ],
      },
    })

    render(
      <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess: vi.fn()}}>
        <ApolloProvider client={mswClient}>
          <SubmissionManager {...props} />
        </ApolloProvider>
      </AlertManagerContext.Provider>,
    )

    // Wait for submit button to be enabled (indicates component is ready)
    const submitButton = await screen.findByTestId('submit-peer-review-button')
    await waitFor(() => {
      expect(submitButton).toBeEnabled()
    })

    // Give time for rubricData to be fetched and set in component state
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 100))
    })

    await act(async () => {
      fireEvent.click(submitButton)
    })

    await waitFor(() => {
      expect(setOnFailure).toHaveBeenCalledWith('Error submitting rubric')
    })
  })
})
