/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {render, screen, waitFor, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import React from 'react'
import ConfirmChangePassword, {type ConfirmChangePasswordProps} from '../ConfirmChangePassword'
import {assignLocation} from '@canvas/util/globalUtils'

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

describe('ConfirmChangePassword form submission', () => {
  const pseudonyms = [
    {
      id: '1',
      user_name: 'John Doe',
    },
    {
      id: '2',
      user_name: 'Jane Smith',
    },
  ]
  const singlePolicyAndPseudonym: ConfirmChangePasswordProps['passwordPoliciesAndPseudonyms'] = {
    [pseudonyms[0].id]: {
      policy: {maximum_login_attempts: '8', minimum_character_length: '8'},
      pseudonym: {unique_id: 'john.doe@mock.com', account_display_name: 'Fake Academy'},
    },
  }
  const props: ConfirmChangePasswordProps = {
    pseudonym: pseudonyms[0],
    defaultPolicy: singlePolicyAndPseudonym[pseudonyms[0].id].policy,
    cc: {
      confirmation_code: 'AJaBfD7JKTLWaBRBWGtJAtu4X',
      path: singlePolicyAndPseudonym[pseudonyms[0].id].pseudonym.unique_id,
    },
    passwordPoliciesAndPseudonyms: singlePolicyAndPseudonym,
  }
  const CONFIRM_CHANGE_PASSWORD_URL = `/pseudonyms/${pseudonyms[0].id}/change_password/${props.cc.confirmation_code}`

  const server = setupServer()

  beforeAll(() => server.listen())

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
    server.resetHandlers()
  })

  afterAll(() => server.close())

  it('should redirect to the login page after a successful password change', async () => {
    let capturedBody: any = null
    server.use(
      http.post(CONFIRM_CHANGE_PASSWORD_URL, async ({request}) => {
        capturedBody = await request.json()
        return new HttpResponse(null, {status: 200})
      }),
    )
    render(<ConfirmChangePassword {...props} />)
    const submit = screen.getByLabelText('Update Password')
    const password = screen.getByLabelText('New Password *')
    const passwordConfirmation = screen.getByLabelText('Confirm New Password *')
    const passwordValue = 'password1234'

    await userEvent.type(password, passwordValue)
    await userEvent.type(passwordConfirmation, passwordValue)
    await userEvent.click(submit)

    await waitFor(() => {
      expect(capturedBody).toEqual({
        pseudonym: {
          id: pseudonyms[0].id,
          password: passwordValue,
          password_confirmation: passwordValue,
        },
      })
      expect(assignLocation).toHaveBeenCalledWith('/login/canvas?password_changed=1')
    })
  })

  it('should redirect if the request fails due to link expiration', async () => {
    let capturedBody: any = null
    server.use(
      http.post(CONFIRM_CHANGE_PASSWORD_URL, async ({request}) => {
        capturedBody = await request.json()
        return HttpResponse.json({errors: {nonce: 'expired'}}, {status: 400})
      }),
    )
    render(<ConfirmChangePassword {...props} />)
    const submit = screen.getByLabelText('Update Password')
    const password = screen.getByLabelText('New Password *')
    const passwordConfirmation = screen.getByLabelText('Confirm New Password *')
    const passwordValue = 'password1234'

    await userEvent.type(password, passwordValue)
    await userEvent.type(passwordConfirmation, passwordValue)
    await userEvent.click(submit)

    await waitFor(() => {
      expect(capturedBody).toEqual({
        pseudonym: {
          id: pseudonyms[0].id,
          password: passwordValue,
          password_confirmation: passwordValue,
        },
      })
      expect(assignLocation).toHaveBeenCalledWith('/login/canvas')
    })
  })

  it('should show an error if the request fails due to a validation error', async () => {
    server.use(
      http.post(CONFIRM_CHANGE_PASSWORD_URL, () =>
        HttpResponse.json(
          {
            pseudonym: {
              password: [
                {
                  attribute: 'password',
                  type: 'no_symbols',
                  message: 'no_symbols',
                },
              ],
            },
          },
          {status: 400},
        ),
      ),
    )
    render(<ConfirmChangePassword {...props} />)
    const submit = screen.getByLabelText('Update Password')
    const password = screen.getByLabelText('New Password *')
    const passwordConfirmation = screen.getByLabelText('Confirm New Password *')
    const passwordValue = 'password1234'

    await userEvent.type(password, passwordValue)
    await userEvent.type(passwordConfirmation, passwordValue)
    await userEvent.click(submit)

    const errorText = await screen.findByText('Must include at least one symbol')
    expect(errorText).toBeInTheDocument()
  })

  it('should show an error alert if the request fails due to an unexpected server error', async () => {
    server.use(http.post(CONFIRM_CHANGE_PASSWORD_URL, () => new HttpResponse(null, {status: 500})))
    render(<ConfirmChangePassword {...props} />)
    const submit = screen.getByLabelText('Update Password')
    const password = screen.getByLabelText('New Password *')
    const passwordConfirmation = screen.getByLabelText('Confirm New Password *')
    const passwordValue = 'password1234'

    await userEvent.type(password, passwordValue)
    await userEvent.type(passwordConfirmation, passwordValue)
    await userEvent.click(submit)

    const errorAlerts = await screen.findAllByText(
      'An error occurred while updating your password.',
    )
    expect(errorAlerts.length).toBeTruthy()
  })
})
