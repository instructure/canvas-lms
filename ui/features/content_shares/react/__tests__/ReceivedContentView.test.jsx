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
import {render, fireEvent, act, waitFor} from '@testing-library/react'
import ReceivedContentView from '../ReceivedContentView'
import {assignmentShare, unreadDiscussionShare} from './test-utils'
import {setupServer} from 'msw/node'
import {http, HttpResponse, delay} from 'msw'

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

  it('renders spinner while loading', async () => {
    server.use(
      http.get('/api/v1/users/self/content_shares/received', async () => {
        await delay('infinite')
      }),
    )
    const {getByText} = render(<ReceivedContentView />)
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('hides spinner when not loading', async () => {
    server.use(http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json([])))
    const {queryByText} = render(<ReceivedContentView />)
    await waitFor(() => {
      expect(queryByText(/loading/i)).not.toBeInTheDocument()
    })
  })

  it('displays table with successful retrieval and not loading', async () => {
    const shares = [assignmentShare]
    server.use(
      http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json(shares)),
    )
    const {getByText} = render(<ReceivedContentView />)
    await waitFor(() => {
      expect(getByText(shares[0].name)).toBeInTheDocument()
    })
  })

  it('displays a message instead of a table on an empty return', async () => {
    server.use(http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json([])))
    const {queryByText, getByText} = render(<ReceivedContentView />)
    await waitFor(() => {
      expect(queryByText('Content shared by others to you')).toBeNull()
      expect(getByText(/no content has been shared with you/i)).toBeInTheDocument()
    })
  })

  it('raises an error on unsuccessful retrieval', async () => {
    server.use(
      http.get(
        '/api/v1/users/self/content_shares/received',
        () => new HttpResponse(null, {status: 500}),
      ),
    )

    // Error boundary to catch the thrown error
    class ErrorBoundary extends React.Component {
      constructor(props) {
        super(props)
        this.state = {hasError: false, error: null}
      }
      static getDerivedStateFromError(error) {
        return {hasError: true, error}
      }
      render() {
        if (this.state.hasError) {
          return <div>Error: {this.state.error.message}</div>
        }
        return this.props.children
      }
    }

    // Suppress error output for this test
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})

    const {findByText} = render(
      <ErrorBoundary>
        <ReceivedContentView />
      </ErrorBoundary>,
    )

    // Wait for the error to be thrown and caught by the error boundary
    expect(await findByText('Error: Retrieval of Received Shares failed')).toBeInTheDocument()
    spy.mockRestore()
  })

  it('shows pagination when the link header indicates there are multiple pages', async () => {
    server.use(
      http.get('/api/v1/users/self/content_shares/received', () =>
        HttpResponse.json([assignmentShare], {
          headers: {
            Link: '</api/v1/users/self/content_shares/received?page=5>; rel="last"',
          },
        }),
      ),
    )
    const {getByText} = render(<ReceivedContentView />)
    await waitFor(() => {
      expect(getByText(assignmentShare.name)).toBeInTheDocument()
    })

    // other numbers can be left out due to compact representation
    const expectedNums = ['1', '2', '3', '4', '5']
    expectedNums.forEach(n => {
      expect(getByText(n)).toBeInTheDocument()
    })
  })

  it('updates the current page when a page number is clicked', async () => {
    let requestedPage = null
    server.use(
      http.get('/api/v1/users/self/content_shares/received', ({request}) => {
        const url = new URL(request.url)
        requestedPage = url.searchParams.get('page')
        return HttpResponse.json([assignmentShare], {
          headers: {
            Link: '</api/v1/users/self/content_shares/received?page=5>; rel="last"',
          },
        })
      }),
    )
    const {getByText} = render(<ReceivedContentView />)
    await waitFor(() => {
      expect(getByText(assignmentShare.name)).toBeInTheDocument()
    })

    fireEvent.click(getByText('3'))
    await waitFor(() => {
      expect(requestedPage).toBe('3')
    })
  })

  it('displays a preview modal when requested', async () => {
    const shares = [assignmentShare]
    server.use(
      http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json(shares)),
      http.put(`/api/v1/users/self/content_shares/${assignmentShare.id}`, () =>
        HttpResponse.json({read_state: 'read', id: unreadDiscussionShare.id}),
      ),
    )
    const {getByText} = render(<ReceivedContentView />)
    await waitFor(() => {
      expect(getByText(assignmentShare.name)).toBeInTheDocument()
    })

    fireEvent.click(getByText(/manage options/i))
    fireEvent.click(getByText('Preview'))
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })
    expect(document.querySelector('iframe')).toBeInTheDocument()
  })

  it.skip('displays the import tray when requested', async () => {
    const shares = [assignmentShare]
    server.use(
      http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json(shares)),
      http.get('/users/self/manageable_courses', () => HttpResponse.json([])),
    )
    const {getByText, findByText} = render(<ReceivedContentView />)
    await waitFor(() => {
      expect(getByText(assignmentShare.name)).toBeInTheDocument()
    })

    fireEvent.click(getByText(/manage options/i))
    fireEvent.click(getByText('Import'))
    expect(await findByText(/select a course/i)).toBeInTheDocument()
  })

  it('announces when new shares are loaded', async () => {
    const shares = [assignmentShare]
    server.use(
      http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json(shares)),
    )
    const {getByText} = render(<ReceivedContentView />)
    await waitFor(() => {
      expect(getByText('1 shared item loaded.')).toBeInTheDocument()
    })
  })

  describe('mark as read', () => {
    const shares = [unreadDiscussionShare]

    beforeEach(() => {
      server.use(
        http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json(shares)),
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
      await waitFor(() => {
        expect(getByTestId('received-table-row-unread')).toBeInTheDocument()
      })
      fireEvent.click(getByTestId('received-table-row-unread'))
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(apiCalled).toBeTruthy()
    })

    it('updates the unread dot', async () => {
      const {queryByTestId, getByTestId} = render(<ReceivedContentView />)
      await waitFor(() => {
        expect(getByTestId('received-table-row-unread')).toBeInTheDocument()
      })
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
      window.confirm = vi.fn()
    })

    afterEach(() => {
      window.confirm = oldWindowConfirm
    })

    it('removes a content share when requested', async () => {
      const shares = [assignmentShare]
      server.use(
        http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json(shares)),
        http.delete(
          `/api/v1/users/self/content_shares/${assignmentShare.id}`,
          () => new HttpResponse(null, {status: 200}),
        ),
      )
      window.confirm.mockImplementation(() => true)
      const {getByText, queryByText} = render(<ReceivedContentView />)
      await waitFor(() => {
        expect(getByText(assignmentShare.name)).toBeInTheDocument()
      })
      fireEvent.click(getByText(/manage options/i))
      fireEvent.click(getByText('Remove'))
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(queryByText(assignmentShare.name)).toBeNull()
    })

    it('does nothing when user declines to remove', async () => {
      const shares = [assignmentShare]
      let deleteCalled = false
      server.use(
        http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json(shares)),
        http.delete(`/api/v1/users/self/content_shares/${assignmentShare.id}`, () => {
          deleteCalled = true
          return new HttpResponse(null, {status: 200})
        }),
      )
      window.confirm.mockImplementation(() => false)
      const {getByText} = render(<ReceivedContentView />)
      await waitFor(() => {
        expect(getByText(assignmentShare.name)).toBeInTheDocument()
      })
      fireEvent.click(getByText(/manage options/i))
      fireEvent.click(getByText('Remove'))
      // Give a moment for any async operations
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(deleteCalled).toBe(false)
      expect(getByText(assignmentShare.name)).toBeInTheDocument()
    })

    it('displays an error when the fetch fails', async () => {
      const shares = [assignmentShare]
      server.use(
        http.get('/api/v1/users/self/content_shares/received', () => HttpResponse.json(shares)),
        http.delete(
          `/api/v1/users/self/content_shares/${assignmentShare.id}`,
          () => new HttpResponse(null, {status: 401}),
        ),
      )
      window.confirm.mockImplementation(() => true)
      const {getByText, getAllByText} = render(<ReceivedContentView />)
      await waitFor(() => {
        expect(getByText(assignmentShare.name)).toBeInTheDocument()
      })
      fireEvent.click(getByText(/manage options/i))
      fireEvent.click(getByText('Remove'))
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(getAllByText(/401/)[0]).toBeInTheDocument()
    })
  })
})
