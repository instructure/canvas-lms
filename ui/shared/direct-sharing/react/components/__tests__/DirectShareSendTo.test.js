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
import useContentShareUserSearchApi from '../../effects/useContentShareUserSearchApi'
import DirectShareUserModal from '../DirectShareUserModal'

jest.mock('../../effects/useContentShareUserSearchApi')

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

  beforeAll(async () => {
    window.ENV = {COURSE_ID: '123'}
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
    // There is currently a conflict between Lazy loading promises and jest timers being out of sync
    // so this is a temp way to bypass that state until it is fixed in jest
    jest.useFakeTimers()
    const {unmount} = render(<DirectShareUserModal open={true} />)
    await Promise.resolve().then(() => jest.runAllTimers())
    unmount()
  })

  afterAll(() => {
    delete window.ENV
    if (ariaLive) ariaLive.remove()
  })

  describe('dialog controls', () => {
    it('handles error when fetching users api fails', () => {
      const {getByText, getByLabelText} = render(
        <DirectShareUserModal open={true} courseId="123" />
      )
      useContentShareUserSearchApi.mockImplementationOnce(({error}) =>
        error([{status: 400, body: 'error'}])
      )
      const input = getByLabelText(/send to:/i)
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

    it('displays loading state when fetching user list', () => {
      const {getByRole, getByLabelText} = render(<DirectShareUserModal open={true} />)
      const input = getByLabelText(/send to:/i)
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})
      const alertContainer = getByRole('alert')

      expect(alertContainer).toHaveTextContent(/Loading options.../i)
    })

    it('displays user search results', () => {
      const {getByText, getByLabelText} = render(
        <DirectShareUserModal open={true} courseId="123" />
      )
      const input = getByLabelText(/send to:/i)
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})
      act(() => jest.runAllTimers())

      expect(getByText(/Teacher3 Middle LastName3/i)).toBeInTheDocument()
      expect(getByText(/Teacher4 Middle LastName4/i)).toBeInTheDocument()
    })

    it('adds recipients to final list', () => {
      const {getByText, getByTitle, getByLabelText, queryByTitle} = render(
        <DirectShareUserModal open={true} />
      )
      const input = getByLabelText(/send to:/i)
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})
      act(() => jest.runAllTimers())
      fireEvent.click(getByText('Teacher3 Middle LastName3'))

      expect(getByTitle(/Remove Teacher3 Middle LastName3/i)).toBeInTheDocument()
      expect(queryByTitle(/Teacher4 Middle LastName4/i)).toBeNull()
    })

    it('allows removal of recipient from final list', () => {
      const {getByText, getByTitle, getByLabelText, queryByTitle} = render(
        <DirectShareUserModal open={true} />
      )
      const input = getByLabelText(/send to:/i)
      fireEvent.focus(input)
      fireEvent.change(input, {target: {value: 'teac'}})
      act(() => jest.runAllTimers())
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
