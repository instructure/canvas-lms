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

import {render} from '@testing-library/react'
import {clickOrFail} from '../../__tests__/interactionHelpers'
import {ToolDetailsInner} from '../ToolDetails'
import {
  mockRegistrationWithAllInformation,
  mockSiteAdminRegistration,
} from '../../manage/__tests__/helpers'
import {BrowserRouter} from 'react-router-dom'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ZDeveloperKeyId} from '../../../model/developer_key/DeveloperKeyId'

const server = setupServer()

describe('ToolDetailsInner', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  const renderToolDetailsInner = (
    registration = mockRegistrationWithAllInformation({n: 'test', i: 1}),
  ) => {
    return render(
      <BrowserRouter>
        <QueryClientProvider client={new QueryClient()}>
          <ToolDetailsInner registration={registration} accountId={registration.account_id} />
        </QueryClientProvider>
      </BrowserRouter>,
    )
  }

  it('renders Delete and Copy Client ID buttons', async () => {
    const wrapper = renderToolDetailsInner()

    expect(wrapper.queryByText('Copy Client ID')).toBeInTheDocument()
    expect(wrapper.queryByText('Delete App')).toBeInTheDocument()
  })

  it('calls the delete API endpoint when the delete button is clicked', async () => {
    let capturedUrl = ''
    let capturedMethod = ''
    server.use(
      http.delete('/api/v1/accounts/:accountId/lti_registrations/:registrationId', ({request}) => {
        capturedUrl = request.url
        capturedMethod = request.method
        return HttpResponse.json({
          __type: 'Success',
          data: {},
        })
      }),
    )

    const wrapper = renderToolDetailsInner()
    const deleteBtn = await wrapper.getByText('Delete App').closest('button')
    await clickOrFail(deleteBtn)
    const confirmationModalAcceptBtn = await wrapper.getByText('Delete').closest('button')
    await clickOrFail(confirmationModalAcceptBtn)

    expect(capturedUrl).toContain('/api/v1/accounts/1/lti_registrations/1')
    expect(capturedMethod).toBe('DELETE')
  })

  it('shows the delete button on a site admin registration', async () => {
    const wrapper = renderToolDetailsInner()
    const deleteButton = wrapper.getByTestId('delete-app')
    expect(deleteButton).not.toHaveAttribute('disabled')
  })

  it('disables the delete button on a site admin registration', async () => {
    const registration = mockSiteAdminRegistration('site admin', 1)

    const wrapper = renderToolDetailsInner(registration)
    const deleteButton = wrapper.getByTestId('delete-app')
    expect(deleteButton).toHaveAttribute('disabled')
  })

  it('shows the "Migrate from LTI 2.0" button when turnitinAPClientId matches developer_key_id', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        developer_key_id: ZDeveloperKeyId.parse('12345'),
      },
    })
    window.ENV.turnitinAPClientId = '12345'

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Migrate from LTI 2.0')).toBeInTheDocument()

    delete window.ENV.turnitinAPClientId
  })

  it('does not show the "Migrate from LTI 2.0" button when turnitinAPClientId does not match', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        developer_key_id: ZDeveloperKeyId.parse('12345'),
      },
    })
    window.ENV.turnitinAPClientId = '99999'

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Migrate from LTI 2.0')).not.toBeInTheDocument()

    delete window.ENV.turnitinAPClientId
  })

  it('shows the "Reinstall App" button when dynamic_registration_url is present and reinstall is not disabled', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        dynamic_registration_url: 'https://example.com/register',
        reinstall_disabled: false,
      },
    })

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Reinstall App')).toBeInTheDocument()
  })

  it('does not show the "Reinstall App" button when reinstall_disabled is true', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        dynamic_registration_url: 'https://example.com/register',
        reinstall_disabled: true,
      },
    })

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Reinstall App')).not.toBeInTheDocument()
  })

  it('does not show the "Reinstall App" button when dynamic_registration_url is not present', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        dynamic_registration_url: null,
        reinstall_disabled: false,
      },
    })

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Reinstall App')).not.toBeInTheDocument()
  })
})
