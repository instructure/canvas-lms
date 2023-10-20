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

import {AuditLogForm, AuditLogResults, MUTATION_LOG_QUERY} from '../MutationAuditLog'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {fireEvent, render, waitFor} from '@testing-library/react'

describe('AuditLogForm', () => {
  it('renders', () => {
    const {getByLabelText, getByText} = render(<AuditLogForm onSubmit={() => {}} />)
    expect(getByLabelText(/Asset String/)).toBeInTheDocument()
    expect(getByText(/Find/)).toBeInTheDocument()
  })

  it('calls onSubmit when clicked', () => {
    const cb = jest.fn()
    const {getByLabelText, getByText} = render(<AuditLogForm onSubmit={cb} />)

    const assetStringInput = getByLabelText(/Asset/)
    const submitButton = getByText(/Find/)

    // doesn't fire when assetString is blank
    fireEvent.click(submitButton)
    expect(cb.mock.calls.length).toBe(0)

    fireEvent.change(assetStringInput, {target: {value: 'user_123'}})
    fireEvent.click(submitButton)
    expect(cb.mock.calls.length).toBe(1)
    expect(cb.mock.calls[0][0]).toEqual({assetString: 'user_123', startDate: null, endDate: null})
  })
})

describe('AuditLogResults', () => {
  const mocks = [
    {
      request: {
        query: MUTATION_LOG_QUERY,
        variables: {
          assetString: 'user_123',
          startDate: undefined,
          endDate: undefined,
          first: 1,
        },
      },
      result: {
        data: {
          auditLogs: {
            mutationLogs: {
              nodes: [
                {
                  assetString: 'user_123',
                  mutationId: 'ASDFASDFASDF',
                  mutationName: 'BlahBlahBlah',
                  timestamp: new Date().toISOString(),
                  user: {
                    _id: '1',
                    name: 'Professor',
                    __typename: 'User',
                  },
                  realUser: null,
                  params: {
                    test: 'I AM A PARAMETER',
                  },
                  __typename: 'MutationLog',
                },
              ],
              pageInfo: {
                hasNextPage: true,
                endCursor: 'cursor1',
                __typename: 'PageInfo',
              },
              __typename: 'MutationLogConnection',
            },
            __typename: 'AuditLogs',
          },
        },
      },
    },
    {
      request: {
        query: MUTATION_LOG_QUERY,
        variables: {
          assetString: 'user_123',
          startDate: undefined,
          endDate: undefined,
          first: 1,
          after: 'cursor1',
        },
      },
      result: {
        data: {
          auditLogs: {
            mutationLogs: {
              nodes: [
                {
                  assetString: 'user_123',
                  mutationId: 'ZXCVZXCV',
                  mutationName: 'FooBarBaz',
                  timestamp: new Date().toISOString(),
                  user: {
                    _id: '2',
                    name: 'Doctor',
                    __typename: 'User',
                  },
                  realUser: null,
                  params: {},
                  __typename: 'MutationLog',
                },
              ],
              pageInfo: {
                hasNextPage: false,
                endCursor: 'cursor2',
                __typename: 'PageInfo',
              },
              __typename: 'MutationLogConnection',
            },
            __typename: 'AuditLogs',
          },
        },
      },
    },
    {
      request: {
        query: MUTATION_LOG_QUERY,
        variables: {
          assetString: 'user_456',
          startDate: undefined,
          endDate: undefined,
          first: 100,
        },
      },
      result: {
        data: {
          auditLogs: {
            mutationLogs: {
              nodes: [],
              pageInfo: {
                hasNextPage: false,
                endCursor: 'endCursor',
                __typename: 'PageInfo',
              },
              __typename: 'MutationLogConnection',
            },
            __typename: 'AuditLogs',
          },
        },
      },
    },
    {
      request: {
        query: MUTATION_LOG_QUERY,
        variables: {
          assetString: 'error_1',
          startDate: undefined,
          endDate: undefined,
          first: 100,
        },
      },
      error: new Error('uh oh'),
    },
  ]

  it('renders (flaky)', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <AuditLogResults assetString="user_123" pageSize={1} />
      </MockedProvider>
    )

    // renders loading state first
    expect(getByText(/Loading/)).toBeInTheDocument()

    // results
    expect(await waitFor(() => getByText('Professor'))).toBeInTheDocument()
  })

  it('paginates', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <AuditLogResults assetString="user_123" pageSize={1} />
      </MockedProvider>
    )
    const loadMoreButton = await waitFor(() => getByText(/load more/i))
    expect(loadMoreButton).toBeInTheDocument()

    fireEvent.click(loadMoreButton)
    expect(await waitFor(() => getByText('Doctor'))).toBeInTheDocument()
    expect(getByText(/No more/)).toBeInTheDocument()
  })

  it('says when there are no results', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <AuditLogResults assetString="user_456" pageSize={100} />
      </MockedProvider>
    )

    expect(await waitFor(() => getByText(/no results/i))).toBeInTheDocument()
  })

  it('handles errors', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <AuditLogResults assetString="error_1" pageSize={100} />
      </MockedProvider>
    )

    expect(await waitFor(() => getByText(/went wrong/))).toBeInTheDocument()
  })

  it('expands parameters', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <AuditLogResults assetString="user_123" pageSize={1} />
      </MockedProvider>
    )

    const showParamsBtn = await waitFor(() => getByText('Show params'))
    expect(showParamsBtn).toBeInTheDocument()

    fireEvent.click(showParamsBtn)
    const shownParameters = getByText(/A PARAMETER/)
    expect(shownParameters).toBeInTheDocument()

    const hideParamsBtn = getByText('Hide params')
    fireEvent.click(hideParamsBtn)
    expect(shownParameters).not.toBeInTheDocument()
  })
})
