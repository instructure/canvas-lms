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
import useContentShareUserSearchApi from '../../effects/useContentShareUserSearchApi'
import DirectShareUserModal from '../DirectShareUserModal'

vi.mock('../../effects/useContentShareUserSearchApi')

const usersList = [
  {
    id: '123',
    name: 'Teacher3 Middle LastName3',
    created_at: '2019-10-28T15:45:32-06:00',
    sortable_name: 'LastName3, Teacher3 Middle',
    short_name: 'Teacher3 Middle LastName3',
    sis_user_id: null,
    integration_id: null,
    login_id: 'Teacher3@mail.com',
    email: 'Teacher3@mail.com',
  },
  {
    id: '456',
    name: 'Teacher4 Middle LastName4',
    created_at: '2019-10-28T15:45:57-06:00',
    sortable_name: 'LastName4, Teacher4 Middle',
    short_name: 'Teacher4 Middle LastName4',
    sis_user_id: null,
    integration_id: null,
    login_id: 'Teacher4@mail.com',
    email: 'Teacher4@mail.com',
  },
]

describe('DirectShareSendToDialog', () => {
  let ariaLive

  beforeAll(() => {
    window.ENV = {COURSE_ID: '123', FEATURES: {validate_call_to_action: false}}
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    delete window.ENV
    if (ariaLive) ariaLive.remove()
  })

  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('dialog controls', () => {
    it('handles error when fetching users api fails', async () => {
      // Use real timers for Suspense to resolve
      vi.useRealTimers()
      // Initial render mock - component needs this to exit loading state
      useContentShareUserSearchApi.mockImplementationOnce(({success}) => {
        success(null)
      })
      const {getByText, findByLabelText} = render(
        <DirectShareUserModal open={true} courseId="123" />,
      )
      const input = await findByLabelText(/send to:/i)
      // Switch back to fake timers for debounced search
      vi.useFakeTimers()
      useContentShareUserSearchApi.mockImplementationOnce(({error}) =>
        error([{status: 400, body: 'error'}]),
      )
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  describe('share with', () => {
    beforeEach(() => {
      useContentShareUserSearchApi.mockImplementationOnce(({success}) => {
        success(usersList)
      })
    })

    it('displays loading state when fetching user list', async () => {
      // Use real timers for Suspense to resolve
      vi.useRealTimers()
      const {getByRole, findByLabelText} = render(<DirectShareUserModal open={true} />)
      const input = await findByLabelText(/send to:/i)
      // Switch back to fake timers for debounced search
      vi.useFakeTimers()
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})
      const alertContainer = getByRole('alert')

      expect(alertContainer).toHaveTextContent(/Loading options.../i)
    })

    // These tests are skipped due to conflicts between React.lazy(), fake timers, and InstUI
    // components. The lazy-loaded component requires real timers to resolve, but the debounced
    // search requires fake timers. InstUI's position listeners create infinite timer loops.
    // A comprehensive fix would require refactoring the component to not use lazy loading in tests.
    it.skip('displays user search results', async () => {
      // Use real timers for Suspense to resolve
      vi.useRealTimers()
      const {getByText, findByLabelText} = render(
        <DirectShareUserModal open={true} courseId="123" />,
      )
      const input = await findByLabelText(/send to:/i)
      // Switch back to fake timers for debounced search
      vi.useFakeTimers()
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})
      // Use advanceTimersByTime to avoid infinite loop from InstUI position listeners
      act(() => vi.advanceTimersByTime(500))

      expect(getByText(/Teacher3 Middle LastName3/i)).toBeInTheDocument()
      expect(getByText(/Teacher4 Middle LastName4/i)).toBeInTheDocument()
    })

    it.skip('adds recipients to final list', async () => {
      // Use real timers for Suspense to resolve
      vi.useRealTimers()
      const {getByText, getByTitle, findByLabelText, queryByTitle} = render(
        <DirectShareUserModal open={true} />,
      )
      const input = await findByLabelText(/send to:/i)
      // Switch back to fake timers for debounced search
      vi.useFakeTimers()
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})
      // Use advanceTimersByTime to avoid infinite loop from InstUI position listeners
      act(() => vi.advanceTimersByTime(500))
      fireEvent.click(getByText('Teacher3 Middle LastName3'))

      expect(getByTitle(/Remove Teacher3 Middle LastName3/i)).toBeInTheDocument()
      expect(queryByTitle(/Teacher4 Middle LastName4/i)).toBeNull()
    })

    it.skip('allows removal of recipient from final list', async () => {
      // Use real timers for Suspense to resolve
      vi.useRealTimers()
      const {getByText, getByTitle, findByLabelText, queryByTitle} = render(
        <DirectShareUserModal open={true} />,
      )
      const input = await findByLabelText(/send to:/i)
      // Switch back to fake timers for debounced search
      vi.useFakeTimers()
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})
      // Use advanceTimersByTime to avoid infinite loop from InstUI position listeners
      act(() => vi.advanceTimersByTime(500))
      fireEvent.click(getByText('Teacher3 Middle LastName3'))
      expect(getByTitle(/Remove Teacher3 Middle LastName3/i)).toBeInTheDocument()
      const removeUserButton = getByTitle(/Remove Teacher3 Middle LastName3/i).closest('button')
      fireEvent.click(removeUserButton)

      expect(queryByTitle(/Remove Teacher3 Middle LastName3/i)).toBeNull()
    })

    it('disables Send button when no recipient is selected', () => {
      const {getByText} = render(<DirectShareUserModal open={true} courseId="123" />)

      expect(getByText('Send').closest('button').getAttribute('disabled')).toBe('')
    })
  })
})
