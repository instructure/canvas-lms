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
import {render, fireEvent, waitFor, act} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import useContentShareUserSearchApi from '../../effects/useContentShareUserSearchApi'
import DirectShareUserModal from '../DirectShareUserModal'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('../../effects/useContentShareUserSearchApi')

// Mock the lazy-loaded component to avoid issues with React.lazy and fake timers
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

const flushAllTimersAndPromises = async () => {
  while (vi.getTimerCount() > 0) {
    await act(async () => {
      vi.runAllTimers()
    })
  }
}

describe('DirectShareUserModal', () => {
  let ariaLive

  beforeAll(() => {
    fakeENV.setup({COURSE_ID: '42'})
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    fakeENV.teardown()
    if (ariaLive) ariaLive.remove()
  })

  beforeEach(() => {
    vi.useFakeTimers()

    useContentShareUserSearchApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
  })

  afterEach(async () => {
    await flushAllTimersAndPromises()
    fetchMock.restore()
  })

  async function selectUser(getByText, findByLabelText, name = 'abc') {
    fireEvent.change(await findByLabelText(/send to:/i), {target: {value: name}})
  }

  describe('Validation call to action', () => {
    describe('when the feature flag is enabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          COURSE_ID: '42',
          FEATURES: {validate_call_to_action: true},
        })
      })

      it('does not disable the send button immediately', () => {
        const {getByText} = render(<DirectShareUserModal open={true} courseId="1" />)
        expect(getByText('Send').closest('button').getAttribute('disabled')).toBeNull()
      })

      it('displays an error message when no user is selected', async () => {
        const {getByText, findByLabelText} = render(
          <DirectShareUserModal open={true} courseId="1" />,
        )
        await findByLabelText(/send to:/i)
        fireEvent.click(getByText('Send'))
        expect(getByText('You must select at least one user')).toBeInTheDocument()
      })

      it('disables the send button when a search has started UNDER TEST', async () => {
        fetchMock.postOnce('/api/v1/users/self/content_shares', 200)
        const {getByText, findByLabelText} = render(
          <DirectShareUserModal open={true} courseId="1" onDismiss={Function.prototype} />,
        )
        await selectUser(getByText, findByLabelText)
        fireEvent.click(getByText('Send'))
        expect(getByText('Send').closest('button').getAttribute('disabled')).toBe('')
      })

      it('focuses on user select after error', async () => {
        const {getByText, findByLabelText} = render(
          <DirectShareUserModal open={true} courseId="1" />,
        )
        const input = await findByLabelText(/send to:/i)
        // Click the send button to trigger the error
        fireEvent.click(getByText('Send'))
        // Wait for the focus to be applied
        await waitFor(() => {
          expect(input).toHaveFocus()
        })
      })
    })

    describe('when the feature flag is disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          COURSE_ID: '42',
          FEATURES: {validate_call_to_action: false},
        })
      })

      it('disables the send button immediately', () => {
        const {getByText} = render(<DirectShareUserModal open={true} courseId="1" />)
        expect(getByText('Send').closest('button').getAttribute('disabled')).toBe('')
      })

      it('enables the send button only when a user is selected UNDER TEST', async () => {
        const {getByText, getAllByText, findByLabelText} = render(
          <DirectShareUserModal open={true} courseId="1" />,
        )
        await selectUser(getByText, findByLabelText)
        expect(getByText('Send').closest('button').getAttribute('disabled')).toBe(null)
        // remove the selected user from the list
        fireEvent.click(getAllByText('abc')[0])
        expect(getByText('Send').closest('button').getAttribute('disabled')).toBe('')
      })
    })
  })
})
