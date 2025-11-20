/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import PeerReviewsStudentView from '../PeerReviewsStudentView'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

jest.mock('@canvas/util/jquery/apiUserContent', () => ({
  convert: (html: string) => html,
}))

const {executeQuery} = require('@canvas/graphql')
const mockExecuteQuery = executeQuery as jest.MockedFunction<typeof executeQuery>

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('PeerReviewsStudentView', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders loading state initially', () => {
    mockExecuteQuery.mockImplementation(() => new Promise(() => {}))

    const {getByText} = render(
      <QueryClientProvider client={new QueryClient()}>
        <PeerReviewsStudentView assignmentId="1" />
      </QueryClientProvider>,
    )

    expect(getByText('Loading assignment details')).toBeInTheDocument()
  })

  it('renders error state when query fails', async () => {
    mockExecuteQuery.mockRejectedValueOnce(new Error('Failed to fetch'))

    const Wrapper = createWrapper()
    const {getByText} = render(
      <Wrapper>
        <PeerReviewsStudentView assignmentId="1" />
      </Wrapper>,
    )

    await waitFor(() => {
      expect(getByText('Failed to load assignment details')).toBeInTheDocument()
    })
  })

  it('renders assignment details successfully', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '1',
        name: 'Test Peer Review Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>This is the assignment description</p>',
      },
    })

    const Wrapper = createWrapper()
    const {getByTestId, getByText} = render(
      <Wrapper>
        <PeerReviewsStudentView assignmentId="1" />
      </Wrapper>,
    )

    await waitFor(() => {
      expect(getByTestId('title')).toHaveTextContent('Test Peer Review Assignment')
    })

    expect(getByTestId('due-date')).toBeInTheDocument()
    expect(getByText('Assignment Details')).toBeInTheDocument()
  })

  it('renders assignment without due date', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '2',
        name: 'Assignment Without Due Date',
        dueAt: null,
        description: '<p>Description here</p>',
      },
    })

    const Wrapper = createWrapper()
    const {getByTestId, queryByTestId} = render(
      <Wrapper>
        <PeerReviewsStudentView assignmentId="2" />
      </Wrapper>,
    )

    await waitFor(() => {
      expect(getByTestId('title')).toHaveTextContent('Assignment Without Due Date')
    })

    expect(queryByTestId('due-date')).not.toBeInTheDocument()
  })

  it('renders assignment without description', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '3',
        name: 'Assignment Without Description',
        dueAt: '2025-12-31T23:59:59Z',
        description: null,
      },
    })

    const Wrapper = createWrapper()
    const {getByTestId, getByText} = render(
      <Wrapper>
        <PeerReviewsStudentView assignmentId="3" />
      </Wrapper>,
    )

    await waitFor(() => {
      expect(getByTestId('title')).toHaveTextContent('Assignment Without Description')
    })

    expect(getByText('No additional details were added for this assignment.')).toBeInTheDocument()
  })

  it('renders both tabs', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '5',
        name: 'Test Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Description</p>',
      },
    })

    const Wrapper = createWrapper()
    const {getByText} = render(
      <Wrapper>
        <PeerReviewsStudentView assignmentId="5" />
      </Wrapper>,
    )

    await waitFor(() => {
      expect(getByText('Assignment Details')).toBeInTheDocument()
    })

    expect(getByText('Submission')).toBeInTheDocument()
  })
})
