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
import {render, waitFor, within} from '@testing-library/react'
import {QueryClientProvider} from '@tanstack/react-query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {AssignmentMocks} from '@canvas/assignments/graphql/student/Assignment'
import {RUBRIC_QUERY} from '@canvas/assignments/graphql/student/Queries'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import fakeENV from '@canvas/test-utils/fakeENV'
import StudentContent from '../StudentContent'
import ContextModuleApi from '../../apis/ContextModuleApi'

injectGlobalAlertContainers()

vi.mock('../AttemptSelect')

vi.mock('../../apis/ContextModuleApi')

vi.mock('../../../../../shared/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: vi.fn(),
  }
})

vi.mock('@canvas/assignments/react/AssignmentExternalTools', () => ({
  __esModule: true,
  default: {
    attach: vi.fn(),
  },
}))

describe('StudentContent Non-Digital Submissions', () => {
  let props

  beforeEach(async () => {
    fakeENV.setup({current_user: {id: '1'}})
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
    props = await mockAssignmentAndSubmission({
      Assignment: {
        ...AssignmentMocks.onPaper,
        name: 'this is my assignment',
      },
      Submission: {},
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders the assignment details', async () => {
    const {getAllByText} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    expect(getAllByText(/this is my assignment/)).not.toHaveLength(0)
  })

  it('does not render the interface for submitting to the assignment', async () => {
    const {queryByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    expect(queryByTestId('assignment-2-student-content-tabs')).not.toBeInTheDocument()
  })

  it('renders only View Submission link when assignment accepts lti tool submissions and the submission is graded but LTI_TOOL is falsy', async () => {
    props.assignment.submissionTypes = ['external_tool']
    props.submission.state = 'graded'
    // in this case, LTI_TOOL is null

    const {getByTestId, queryByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    const submissionDetailsLink = getByTestId('view-submission-link')
    expect(submissionDetailsLink).toBeInTheDocument()
    expect(queryByTestId('lti-external-tool')).not.toBeInTheDocument()
  })

  it('only the LTI tool iframe LTI_TOOL is true and the submission is not graded', async () => {
    window.ENV.LTI_TOOL = 'true'
    props.submission.state = 'unsubmitted'

    const {queryByTestId, getByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )

    expect(queryByTestId('view-submission-link')).not.toBeInTheDocument()
    expect(getByTestId('lti-external-tool')).toBeInTheDocument()
  })

  it('neither renders the View Submission link nor the LTI iframe when LTI_TOOL is false, and assignment does not accept external_tool', async () => {
    props.submission.state = 'graded'
    props.assignment.submissionTypes = ['file_upload']

    const {queryByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )

    expect(queryByTestId('view-submission-link')).not.toBeInTheDocument()
    expect(queryByTestId('lti-external-tool')).not.toBeInTheDocument()
  })

  it('both LTI Iframe and submission link when all their requirements are true', async () => {
    props.assignment.submissionTypes = ['external_tool']
    props.submission.state = 'graded'
    window.ENV.LTI_TOOL = 'true'
    const {getByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    const lti_external_tool = getByTestId('lti-external-tool')
    expect(lti_external_tool).toBeInTheDocument()
    const view_submission_link = getByTestId('view-submission-link')
    expect(view_submission_link).toBeInTheDocument()
  })

  it('renders a "Mark as Done" button if the assignment is part of a module with a mark-as-done requirement', async () => {
    window.ENV.CONTEXT_MODULE_ITEM = {
      done: false,
      id: '123',
      module_id: '456',
    }

    const {getByRole} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    expect(getByRole('button', {name: 'Mark as done'})).toBeInTheDocument()
  })

  it('does not render a "Mark as Done" button if the assignment lacks mark-as-done requirements', async () => {
    const {queryByRole} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    expect(queryByRole('button', {name: 'Mark as done'})).not.toBeInTheDocument()
  })

  // Skipped: GraphQL mock timing issue in Vitest - rubric query doesn't resolve before assertion
  it.skip('renders the rubric if the assignment has one', async () => {
    window.ENV.ASSIGNMENT_ID = '1'
    window.ENV.COURSE_ID = '1'
    window.ENV.current_user = {id: '2'}
    props.assignment.rubric = {}

    const variables = {
      courseID: '1',
      assignmentLid: '1',
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
      <QueryClientProvider client={queryClient}>
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      </QueryClientProvider>,
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
        <MockedQueryProvider>
          <StudentContent {...props} />
        </MockedQueryProvider>,
      )
      await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())

      const footer = getByTestId('student-footer')
      expect(within(footer).getByRole('link', {name: /Previous/})).toBeInTheDocument()
      expect(within(footer).getByRole('link', {name: /Next/})).toBeInTheDocument()
    })

    it('does not render module links if no next/previous modules exist for the assignment', async () => {
      ContextModuleApi.getContextModuleData.mockResolvedValue({})

      const {queryByRole} = render(
        <MockedQueryProvider>
          <StudentContent {...props} />
        </MockedQueryProvider>,
      )
      await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())

      expect(queryByRole('link', {name: /Previous/})).not.toBeInTheDocument()
      expect(queryByRole('link', {name: /Next/})).not.toBeInTheDocument()
    })
  })
})
