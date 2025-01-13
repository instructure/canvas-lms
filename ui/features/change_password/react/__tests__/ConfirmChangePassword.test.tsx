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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import React from 'react'
import ConfirmChangePassword, {type ConfirmChangePasswordProps} from '../ConfirmChangePassword'

describe('ConfirmChangePassword', () => {
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
  const multiplePoliciesAndPseudonyms: ConfirmChangePasswordProps['passwordPoliciesAndPseudonyms'] =
    {
      ...singlePolicyAndPseudonym,
      [pseudonyms[1].id]: {
        policy: {maximum_login_attempts: '8', minimum_character_length: '8'},
        pseudonym: {unique_id: 'jane.smith@mock.com', account_display_name: 'Site Admin'},
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

  afterEach(() => {
    fetchMock.reset()
  })

  it('should render the user name in the title', async () => {
    render(<ConfirmChangePassword {...props} />)
    const title = screen.getByText(`Change login password for ${props.pseudonym.user_name}`)

    expect(title).toBeInTheDocument()
  })

  it('should render without select if only one password pseudonym is provided', async () => {
    render(<ConfirmChangePassword {...props} />)
    const ccPath = screen.getByText(props.cc.path)
    const select = screen.queryByLabelText('Which login to change')

    expect(ccPath).toBeInTheDocument()
    expect(select).not.toBeInTheDocument()
  })

  it('should render with select if more than one password pseudonyms are provided', async () => {
    render(
      <ConfirmChangePassword
        {...props}
        passwordPoliciesAndPseudonyms={multiplePoliciesAndPseudonyms}
      />,
    )
    const select = screen.getByLabelText('Which login to change')

    expect(select).toBeInTheDocument()
  })

  it("should render the select's options correctly", async () => {
    render(
      <ConfirmChangePassword
        {...props}
        passwordPoliciesAndPseudonyms={multiplePoliciesAndPseudonyms}
      />,
    )
    const select = screen.getByLabelText('Which login to change')

    await userEvent.click(select)

    Object.values(multiplePoliciesAndPseudonyms).forEach(({pseudonym}) => {
      const option = screen.getByText(`${pseudonym.unique_id} - ${pseudonym.account_display_name}`)

      expect(option).toBeInTheDocument()
    })
  })

  it('should show an error if the new password is too short', async () => {
    render(<ConfirmChangePassword {...props} />)
    const submit = screen.getByLabelText('Update Password')

    await userEvent.click(submit)

    const minCharacterLength =
      singlePolicyAndPseudonym[pseudonyms[0].id].policy.minimum_character_length
    const errorText = await screen.findByText(`Must be at least ${minCharacterLength} characters.`)
    expect(errorText).toBeInTheDocument()
  })

  it('should show an error if passwords do not match', async () => {
    render(<ConfirmChangePassword {...props} />)
    const submit = screen.getByLabelText('Update Password')
    const password = screen.getByLabelText('New Password *')
    const passwordConfirmation = screen.getByLabelText('Confirm New Password *')

    await userEvent.type(password, 'password1234')
    await userEvent.type(passwordConfirmation, 'password123')
    await userEvent.click(submit)

    const errorText = await screen.findByText('Passwords do not match.')
    expect(errorText).toBeInTheDocument()
  })

  it('should redirect to the login page after a successful password change', async () => {
    fetchMock.post(CONFIRM_CHANGE_PASSWORD_URL, 200, {overwriteRoutes: true})
    render(<ConfirmChangePassword {...props} />)
    const submit = screen.getByLabelText('Update Password')
    const password = screen.getByLabelText('New Password *')
    const passwordConfirmation = screen.getByLabelText('Confirm New Password *')
    const passwordValue = 'password1234'

    await userEvent.type(password, passwordValue)
    await userEvent.type(passwordConfirmation, passwordValue)
    await userEvent.click(submit)

    await waitFor(() => {
      expect(
        fetchMock.called(CONFIRM_CHANGE_PASSWORD_URL, {
          method: 'POST',
          body: {
            pseudonym: {
              id: pseudonyms[0].id,
              password: passwordValue,
              password_confirmation: passwordValue,
            },
          },
        }),
      ).toBe(true)
    })
  })

  it('should redirect if the request fails due to link expiration', async () => {
    fetchMock.post(
      CONFIRM_CHANGE_PASSWORD_URL,
      {status: 400, body: {errors: {nonce: 'expired'}}},
      {
        overwriteRoutes: true,
      },
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
      expect(
        fetchMock.called(CONFIRM_CHANGE_PASSWORD_URL, {
          method: 'POST',
          body: {
            pseudonym: {
              id: pseudonyms[0].id,
              password: passwordValue,
              password_confirmation: passwordValue,
            },
          },
        }),
      ).toBe(true)
    })
  })

  it('should show an error if the request fails due to a validation error', async () => {
    fetchMock.post(
      CONFIRM_CHANGE_PASSWORD_URL,
      {
        status: 400,
        body: {
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
      },
      {
        overwriteRoutes: true,
      },
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
    fetchMock.post(CONFIRM_CHANGE_PASSWORD_URL, 500, {
      overwriteRoutes: true,
    })
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
