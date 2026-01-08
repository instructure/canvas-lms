/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import UserSuspendLink from '../UserSuspendLink'

const server = setupServer()

const allSuspended = {
  pseudonyms: [
    {id: 5, workflow_state: 'suspended', unique_id: 'suspended'},
    {id: 6, workflow_state: 'suspended', unique_id: 'also suspended'},
  ],
}

const allActive = {
  pseudonyms: [
    {id: 5, workflow_state: 'active', unique_id: 'active'},
    {id: 6, workflow_state: 'active', unique_id: 'also active'},
  ],
}

const mixedStates = {
  pseudonyms: [
    {id: 5, workflow_state: 'suspended', unique_id: 'suspended'},
    {id: 6, workflow_state: 'active', unique_id: 'active'},
  ],
}

const USER_ID = '31337'
const PERMISSIONS = {can_manage_sis_pseudonyms: true}

describe('UserSuspendLink::', () => {
  let savedUserId
  let capturedRequests

  beforeAll(() => {
    server.listen()
    savedUserId = ENV.USER_ID
    ENV.USER_ID = USER_ID
    ENV.PERMISSIONS = PERMISSIONS
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    delete ENV.user_suspend_status
    delete ENV.PERMISSIONS
    ENV.USER_ID = savedUserId
  })

  describe('Link display', () => {
    it('shows both links if pseudonyms are mixed suspended/active', () => {
      ENV.user_suspend_status = mixedStates
      const {getByText} = render(<UserSuspendLink />)
      expect(getByText(/suspend user/i)).toBeInTheDocument()
      expect(getByText(/reactivate user/i)).toBeInTheDocument()
    })

    it('shows only suspend link if pseudonyms are all active', () => {
      ENV.user_suspend_status = allActive
      const {queryByText} = render(<UserSuspendLink />)
      expect(queryByText(/suspend user/i)).toBeInTheDocument()
      expect(queryByText(/reactivate user/i)).toBeNull()
    })

    it('shows only reactivate link if pseudonyms are all suspended', () => {
      ENV.user_suspend_status = allSuspended
      const {queryByText} = render(<UserSuspendLink />)
      expect(queryByText(/reactivate user/i)).toBeInTheDocument()
      expect(queryByText(/suspend user/i)).toBeNull()
    })
  })

  describe('Confirmation modals', () => {
    beforeAll(() => {
      ENV.user_suspend_status = mixedStates
    })

    it('brings up a Reactivate modal if reactivate is clicked', async () => {
      const {getByText, findByText} = render(<UserSuspendLink />)
      const button = getByText(/reactivate user/i)
      fireEvent.click(button)
      expect(await findByText(/Confirm reactivation/)).toBeInTheDocument()
    })

    it('brings up a Reactivate modal with info text if user is unauthorized', async () => {
      ENV.PERMISSIONS.can_manage_sis_pseudonyms = false
      const {getByText, findByText} = render(<UserSuspendLink />)
      const button = getByText(/reactivate user/i)
      fireEvent.click(button)
      expect(await findByText(/You must be authorized/)).toBeInTheDocument()
    })

    it('brings up a Suspend modal if reactivate is clicked', async () => {
      const {getByText, findByText} = render(<UserSuspendLink />)
      const button = getByText(/suspend user/i)
      fireEvent.click(button)
      expect(await findByText(/Confirm suspension/)).toBeInTheDocument()
    })

    it('brings up a Suspend modal with info text if user is unauthorized', async () => {
      ENV.PERMISSIONS.can_manage_sis_pseudonyms = false
      const {getByText, findByText} = render(<UserSuspendLink />)
      const button = getByText(/suspend user/i)
      fireEvent.click(button)
      expect(await findByText(/You must be authorized/)).toBeInTheDocument()
    })
  })

  describe('API calls', () => {
    beforeEach(() => {
      capturedRequests = []
      ENV.user_suspend_status = mixedStates
      server.use(
        http.put(`/api/v1/users/${USER_ID}`, async ({request}) => {
          const body = await request.json()
          capturedRequests.push(body)
          return HttpResponse.json({}, {status: 200})
        }),
      )
    })

    it('makes no API call if the modal is canceled', async () => {
      const {getByText, findByTestId} = render(<UserSuspendLink />)
      let button = getByText(/suspend user/i)
      fireEvent.click(button)
      button = await findByTestId('cancel-button')
      fireEvent.click(button)
      expect(capturedRequests).toHaveLength(0)
    })

    it('makes the proper call for suspending', async () => {
      const {getByText, findByTestId} = render(<UserSuspendLink />)
      let button = getByText(/suspend user/i)
      fireEvent.click(button)
      button = await findByTestId('action-button')
      fireEvent.click(button)
      await vi.waitFor(() => {
        expect(capturedRequests).toHaveLength(1)
        expect(capturedRequests[0]).toEqual({user: {event: 'suspend'}})
      })
    })

    it('makes the proper call for reactivating', async () => {
      const {getByText, findByTestId} = render(<UserSuspendLink />)
      let button = getByText(/reactivate user/i)
      fireEvent.click(button)
      button = await findByTestId('action-button')
      fireEvent.click(button)
      await vi.waitFor(() => {
        expect(capturedRequests).toHaveLength(1)
        expect(capturedRequests[0]).toEqual({user: {event: 'unsuspend'}})
      })
    })
  })
})
