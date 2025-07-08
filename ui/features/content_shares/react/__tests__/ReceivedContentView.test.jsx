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

import React from 'react'
import {render, fireEvent, act} from '@testing-library/react'
import useFetchApi from '@canvas/use-fetch-api-hook'
import ReceivedContentView from '../ReceivedContentView'
import {assignmentShare, unreadDiscussionShare} from './test-utils'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

jest.mock('@canvas/use-fetch-api-hook')

const server = setupServer()

describe('view of received content', () => {
  let liveRegion

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  afterEach(() => {
    if (liveRegion) liveRegion.remove()
  })

  it('renders spinner while loading', () => {
    useFetchApi.mockImplementationOnce(({loading}) => loading(true))
    const {getByText} = render(<ReceivedContentView />)
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('hides spinner when not loading', () => {
    useFetchApi.mockImplementationOnce(({loading}) => loading(false))
    const {queryByText} = render(<ReceivedContentView />)
    expect(queryByText(/loading/i)).not.toBeInTheDocument()
  })

  it('displays table with successful retrieval and not loading', () => {
    const shares = [assignmentShare]
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success(shares)
    })
    const {getByText} = render(<ReceivedContentView />)
    expect(getByText(shares[0].name)).toBeInTheDocument()
  })

  it('displays a message instead of a table on an empty return', () => {
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success([])
    })
    const {queryByText, getByText} = render(<ReceivedContentView />)
    expect(queryByText('Content shared by others to you')).toBeNull()
    expect(getByText(/no content has been shared with you/i)).toBeInTheDocument()
  })

  it('raises an error on unsuccessful retrieval', () => {
    useFetchApi.mockImplementationOnce(({loading, error}) => {
      loading(false)
      error('fetch error')
    })
    expect(() => {
      render(<ReceivedContentView />)
    }).toThrow('Retrieval of Received Shares failed')
  })

  it('shows pagination when the link header indicates there are multiple pages', () => {
    useFetchApi.mockImplementationOnce(({success, meta}) => {
      const link = {
        last: {page: '5', url: 'last'},
      }
      meta({link})
      success([assignmentShare])
    })
    const {getByText} = render(<ReceivedContentView />)

    // other numbers can be left out due to compact representation
    const expectedNums = ['1', '2', '3', '4', '5']
    expectedNums.forEach(n => {
      expect(getByText(n)).toBeInTheDocument()
    })
  })

  it('updates the current page when a page number is clicked', () => {
    useFetchApi.mockImplementationOnce(({success, meta}) => {
      const link = {
        last: {page: '5', url: 'last'},
      }
      meta({link})
      success([assignmentShare])
    })
    const {getByText} = render(<ReceivedContentView />)
    fireEvent.click(getByText('3'))
    const lastFetchCall = useFetchApi.mock.calls.pop()
    expect(lastFetchCall[0]).toMatchObject({params: {page: 3}})
  })

  it('displays a preview modal when requested', async () => {
    const shares = [assignmentShare]
    server.use(
      http.put(`/api/v1/users/self/content_shares/${assignmentShare.id}`, () =>
        HttpResponse.json({read_state: 'read', id: unreadDiscussionShare.id}),
      ),
    )
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success(shares)
    })
    const {getByText} = render(<ReceivedContentView />)
    fireEvent.click(getByText(/manage options/i))
    fireEvent.click(getByText('Preview'))
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })
    expect(document.querySelector('iframe')).toBeInTheDocument()
  })

  it('displays the import tray when requested', async () => {
    const shares = [assignmentShare]
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success(shares)
    })
    const {getByText, findByText} = render(<ReceivedContentView />)
    fireEvent.click(getByText(/manage options/i))
    fireEvent.click(getByText('Import'))
    expect(await findByText(/select a course/i)).toBeInTheDocument()
  })

  it('announces when new shares are loaded', () => {
    const shares = [assignmentShare]
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success(shares)
    })
    const {getByText} = render(<ReceivedContentView />)
    expect(getByText('1 shared item loaded.')).toBeInTheDocument()
  })

  describe('mark as read', () => {
    const shares = [unreadDiscussionShare]

    beforeEach(() => {
      useFetchApi.mockImplementationOnce(({loading, success}) => {
        loading(false)
        success(shares)
      })
      server.use(
        http.put(`/api/v1/users/self/content_shares/${unreadDiscussionShare.id}`, () =>
          HttpResponse.json({read_state: 'read', id: unreadDiscussionShare.id}),
        ),
      )
    })

    it('makes an update API call', async () => {
      let apiCalled = false
      server.use(
        http.put(`/api/v1/users/self/content_shares/${unreadDiscussionShare.id}`, () => {
          apiCalled = true
          return HttpResponse.json({read_state: 'read', id: unreadDiscussionShare.id})
        }),
      )
      const {getByTestId} = render(<ReceivedContentView />)
      fireEvent.click(getByTestId('received-table-row-unread'))
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(apiCalled).toBeTruthy()
    })

    it('updates the unread dot', async () => {
      const {queryByTestId, getByTestId} = render(<ReceivedContentView />)
      fireEvent.click(getByTestId('received-table-row-unread'))
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(queryByTestId('received-table-row-unread')).toBeNull()
    })
  })

  describe('remove', () => {
    const oldWindowConfirm = window.confirm

    beforeEach(() => {
      window.confirm = jest.fn()
    })

    afterEach(() => {
      window.confirm = oldWindowConfirm
    })

    it('removes a content share when requested', async () => {
      const shares = [assignmentShare]
      useFetchApi.mockImplementationOnce(({loading, success}) => {
        loading(false)
        success(shares)
      })
      server.use(
        http.delete(
          `/api/v1/users/self/content_shares/${assignmentShare.id}`,
          () => new HttpResponse(null, {status: 200}),
        ),
      )
      window.confirm.mockImplementation(() => true)
      const {getByText, queryByText} = render(<ReceivedContentView />)
      fireEvent.click(getByText(/manage options/i))
      fireEvent.click(getByText('Remove'))
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(queryByText(assignmentShare.name)).toBeNull()
    })

    it('does nothing when user declines to remove', async () => {
      const shares = [assignmentShare]
      useFetchApi.mockImplementationOnce(({loading, success}) => {
        loading(false)
        success(shares)
      })
      window.confirm.mockImplementation(() => false)
      jest.spyOn(window, 'fetch')
      const {getByText} = render(<ReceivedContentView />)
      fireEvent.click(getByText(/manage options/i))
      fireEvent.click(getByText('Remove'))
      expect(window.fetch).not.toHaveBeenCalled()
      expect(getByText(assignmentShare.name)).toBeInTheDocument()
    })

    it('displays an error when the fetch fails', async () => {
      const shares = [assignmentShare]
      useFetchApi.mockImplementationOnce(({loading, success}) => {
        loading(false)
        success(shares)
      })
      server.use(
        http.delete(
          `/api/v1/users/self/content_shares/${assignmentShare.id}`,
          () => new HttpResponse(null, {status: 401}),
        ),
      )
      window.confirm.mockImplementation(() => true)
      const {getByText, getAllByText} = render(<ReceivedContentView />)
      fireEvent.click(getByText(/manage options/i))
      fireEvent.click(getByText('Remove'))
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(getAllByText(/401/)[0]).toBeInTheDocument()
    })
  })
})
