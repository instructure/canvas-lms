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
import {fireEvent, render} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
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

describe('StudentContent Comments Tray', () => {
  beforeEach(() => {
    fakeENV.setup({current_user: {id: '1'}})
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  const makeMocks = async () => {
    const variables = {submissionAttempt: 0, submissionId: '1'}
    const overrides = {
      Node: {__typename: 'Submission'},
      SubmissionCommentConnection: {nodes: []},
    }
    const result = await mockQuery(SUBMISSION_COMMENT_QUERY, overrides, variables)
    return [
      {
        request: {
          query: SUBMISSION_COMMENT_QUERY,
          variables,
        },
        result,
      },
    ]
  }

  it('renders Comments', async () => {
    const mocks = await makeMocks()
    const props = await mockAssignmentAndSubmission()
    const {findByText} = render(
      <MockedProvider mocks={mocks}>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    fireEvent.click(await findByText(/add comment/i))
    expect(await findByText(/attempt 1 feedback/i)).toBeInTheDocument()
  })

  it('renders spinner while lazy loading comments', async () => {
    const mocks = await makeMocks()
    const props = await mockAssignmentAndSubmission()
    const {getAllByTitle, getByText} = render(
      <MockedProvider mocks={mocks}>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    fireEvent.click(getByText('Add Comment'))
    expect(getAllByTitle('Loading')[0]).toBeInTheDocument()
  })
})
