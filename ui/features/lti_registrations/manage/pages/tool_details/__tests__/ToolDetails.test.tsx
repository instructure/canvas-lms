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
import {render} from '@testing-library/react'
import {clickOrFail} from '../../__tests__/interactionHelpers'
import {ToolDetailsInner} from '../ToolDetails'
import {mockRegistrationWithAllInformation, mockSiteAdminRegistration} from '../../manage/__tests__/helpers'
import {BrowserRouter} from 'react-router-dom'
import fetchMock from 'fetch-mock'

describe('ToolDetailsInner', () => {
  const renderToolDetailsInner = () => {
    const refresh = jest.fn()
    const stale = false
    const registration = mockRegistrationWithAllInformation({n: 'test', i: 1})

    return {
      refresh,
      stale,
      wrapper: render(
        <BrowserRouter>
          <ToolDetailsInner
            registration={registration}
            accountId={registration.account_id}
            stale={stale}
            refreshRegistration={refresh}
          />
        </BrowserRouter>
      ),
    }
  }

  it('renders Delete and Copy Client ID buttons', async () => {
    const {wrapper} = renderToolDetailsInner()

    expect(wrapper.queryByText('Copy Client ID')).toBeInTheDocument()
    expect(wrapper.queryByText('Delete App')).toBeInTheDocument()
  })

  it('calls the delete API endpoint when the delete button is clicked', async () => {
    fetchMock.delete('/api/v1/accounts/1/lti_registrations/1', {
      __type: 'Success',
      data: {}
    })

    const {wrapper} = renderToolDetailsInner()
    const deleteBtn = await wrapper.getByText('Delete App').closest('button')
    await clickOrFail(deleteBtn)
    const confirmationModalAcceptBtn = await wrapper.getByText('Delete').closest('button')
    await clickOrFail(confirmationModalAcceptBtn)

    const response = fetchMock.calls()[0]
    const responseUrl = response[0]
    const responseHeaders = response[1]
    expect(responseUrl).toBe('/api/v1/accounts/1/lti_registrations/1')
    expect(responseHeaders).toMatchObject({
      method: 'DELETE'
    })
  })

  it('shows the delete button on a site admin registration', async () => {
    const {wrapper} = renderToolDetailsInner()
    const deleteButton = await wrapper.getByTestId('delete-app')
    expect(deleteButton).not.toHaveAttribute('disabled')
  })

  it('disables the delete button on a site admin registration', async () => {
    const refresh = jest.fn()
    const stale = false
    const registration = mockSiteAdminRegistration('site admin', 1)

    const wrapper = render(
      <BrowserRouter>
        <ToolDetailsInner
          registration={registration}
          accountId={registration.account_id}
          stale={stale}
          refreshRegistration={refresh}
        />
      </BrowserRouter>
    )
    const deleteButton = await wrapper.getByTestId('delete-app')
    expect(deleteButton).toHaveAttribute('disabled')
  })
})

