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
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'
import {fireEvent, render, waitForElement} from '@testing-library/react'

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

    fireEvent.click(submitButton)
    expect(cb.mock.calls.length).toBe(1)
    expect(cb.mock.calls[0][0]).toEqual({assetString: ''})

    fireEvent.change(assetStringInput, {target: {value: 'user_123'}})
    fireEvent.click(submitButton)
    expect(cb.mock.calls.length).toBe(2)
    expect(cb.mock.calls[1][0]).toEqual({assetString: 'user_123'})
  })
})

describe('AuditLogResults', () => {
  const mocks = [
    {
      request: {
        query: MUTATION_LOG_QUERY,
        variables: {
          assetString: 'user_123'
        }
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
                    __typename: 'User'
                  },
                  realUser: null,
                  params: {},
                  __typename: 'MutationLog'
                }
              ],
              __typename: 'MutationLogConnection'
            },
            __typename: 'AuditLogs'
          }
        }
      }
    },
    {
      request: {
        query: MUTATION_LOG_QUERY,
        variables: {
          assetString: 'user_456'
        }
      },
      result: {
        data: {
          auditLogs: {
            mutationLogs: {
              nodes: [],
              __typename: 'MutationLogConnection'
            },
            __typename: 'AuditLogs'
          }
        }
      }
    },
    {
      request: {
        query: MUTATION_LOG_QUERY,
        variables: {
          assetString: 'error_1'
        }
      },
      error: new Error('uh oh')
    }
  ]

  it('renders', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <AuditLogResults assetString="user_123" />
      </MockedProvider>
    )

    // renders loading state first
    expect(getByText(/Loading/)).toBeInTheDocument()

    // results
    expect(await waitForElement(() => getByText('Professor'))).toBeInTheDocument()
  })

  it('says when there are no results', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <AuditLogResults assetString="user_456" />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByText(/no results/i))).toBeInTheDocument()
  })

  it('handles errors', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <AuditLogResults assetString="error_1" />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByText(/went wrong/))).toBeInTheDocument()
  })
})
