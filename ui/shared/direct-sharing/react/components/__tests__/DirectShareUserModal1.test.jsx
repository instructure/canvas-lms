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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import useContentShareUserSearchApi from '../../effects/useContentShareUserSearchApi'
import DirectShareUserModal from '../DirectShareUserModal'

const server = setupServer()

vi.mock('../../effects/useContentShareUserSearchApi')

// Mock the lazy-loaded component to avoid issues with React.lazy
function MockDirectShareUserPanel({
  selectedUsers,
  onUserSelected,
  onUserRemoved,
  selectedUsersError,
  userSelectInputRef,
}) {
  const inputRef = React.useRef(null)

  React.useEffect(() => {
    if (userSelectInputRef && inputRef.current) {
      userSelectInputRef(inputRef.current)
    }
  }, [userSelectInputRef])

  return (
    <div data-testid="mock-user-panel">
      <label>
        Send to:
        <input
          ref={inputRef}
          data-testid="user-search-input"
          onChange={e => {
            if (e.target.value === 'abc') {
              onUserSelected({id: 'abc', name: 'abc'})
            } else if (e.target.value === 'cde') {
              onUserSelected({id: 'cde', name: 'cde'})
            }
          }}
        />
      </label>
      {selectedUsersError && <div>You must select at least one user</div>}
      {selectedUsers.map(user => (
        <button type="button" key={user.id} onClick={() => onUserRemoved(user)}>
          {user.name}
        </button>
      ))}
    </div>
  )
}

vi.mock('../DirectShareUserPanel', () => ({
  default: MockDirectShareUserPanel,
}))

describe('DirectShareUserModal', () => {
  let ariaLive
  let lastRequestBody

  beforeAll(() => {
    server.listen()
    window.ENV = {COURSE_ID: '42'}
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    server.close()
    delete window.ENV
    if (ariaLive) ariaLive.remove()
  })

  beforeEach(() => {
    lastRequestBody = undefined
    useContentShareUserSearchApi.mockImplementation(() => {
      // Mock implementation - not used with the mocked DirectShareUserPanel
    })
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })

  async function selectUser(getByText, findByLabelText, name = 'abc') {
    const input = await findByLabelText(/send to:/i)
    fireEvent.change(input, {target: {value: name}})
    // Wait for the user to be selected and appear as a tag
    await waitFor(() => getByText(name))
  }

  it('starts a share operation and reports status', async () => {
    server.use(
      http.post('/api/v1/users/self/content_shares', async ({request}) => {
        lastRequestBody = await request.json()
        return new HttpResponse(null, {status: 200})
      }),
    )
    const onDismiss = vi.fn()
    const {getByText, getAllByText, findByLabelText} = render(
      <DirectShareUserModal
        open={true}
        courseId="1"
        contentShare={{content_type: 'discussion_topic', content_id: '42'}}
        onDismiss={onDismiss}
      />,
    )
    await selectUser(getByText, findByLabelText)
    fireEvent.click(getByText('Send'))
    await waitFor(() => {
      expect(lastRequestBody).toMatchObject({
        receiver_ids: ['abc'],
        content_type: 'discussion_topic',
        content_id: '42',
      })
    })
    expect(getAllByText(/start/i)).not.toHaveLength(0)
    await waitFor(() => {
      expect(getAllByText(/success/i)).toHaveLength(2) // visible and sr alert
    })
    expect(onDismiss).toHaveBeenCalled()
  })

  it('clears user selection when the modal is closed', async () => {
    server.use(
      http.get('*', () => {
        return HttpResponse.json([{id: 'abc', name: 'abc'}])
      }),
    )
    const {queryByText, getByText, findByLabelText, rerender} = render(
      <DirectShareUserModal open={true} courseId="1" />,
    )
    await selectUser(getByText, findByLabelText)
    rerender(<DirectShareUserModal open={false} courseId="1" />)
    rerender(<DirectShareUserModal open={true} courseId="1" />)
    expect(queryByText('abc')).toBeNull()
  })

  describe('errors', () => {
    beforeEach(() => {
      vi.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore()
    })

    it('reports an error if the fetch fails', async () => {
      server.use(
        http.post('/api/v1/users/self/content_shares', () => {
          return new HttpResponse(null, {status: 400})
        }),
      )
      const {getByText, findByLabelText} = render(
        <DirectShareUserModal
          open={true}
          courseId="1"
          contentShare={{content_type: 'discussion_topic', content_id: '42'}}
        />,
      )
      await selectUser(getByText, findByLabelText)
      fireEvent.click(getByText('Send'))
      await waitFor(() => {
        expect(getByText(/error/i)).toBeInTheDocument()
      })
      expect(getByText('Send').closest('button').getAttribute('disabled')).toBeNull()
    })
  })
})
