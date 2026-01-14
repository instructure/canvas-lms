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
import {cleanup, fireEvent, render, waitFor} from '@testing-library/react'
import CreateOrUpdateUserModal from '../CreateOrUpdateUserModal'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'

const CREATE_URL = '/accounts/2/users'

const defaultProps = {
  createOrUpdate: 'create' as 'create' | 'update',
  url: CREATE_URL,
  afterSave: vi.fn(),
  onClose: vi.fn(),
  open: true,
}

const newUser = {
  user: {
    id: '12345',
    name: 'John Doe',
  },
}

const existingUser = {
  name: 'Jane Smith',
  sortable_name: 'Smith, Jane',
  short_name: 'Jane Smith',
  email: 'jane.smith@example.com',
  time_zone: 'Hawaii',
}

describe('CreateOrUpdateUserModal', () => {
  afterEach(() => {
    cleanup()
  })
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    fetchMock.restore()
    fakeENV.teardown()
  })

  it('runs onClose when modal is closed', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<CreateOrUpdateUserModal {...defaultProps} />)

    // close the modal
    await user.click(getByTestId('cancel-button'))

    expect(defaultProps.onClose).toHaveBeenCalled()
  })

  describe('create', () => {
    it('creates a user when form is submitted', async () => {
      const user = userEvent.setup()
      fetchMock.post(CREATE_URL, {
        body: {user: newUser},
        status: 200,
      })
      const {getByTestId} = render(<CreateOrUpdateUserModal {...defaultProps} />)

      fireEvent.change(getByTestId('full-name'), {target: {value: 'John Doe'}})
      fireEvent.change(getByTestId('unique-id'), {target: {value: 'john.doe@example.com'}})

      // submit
      await user.click(getByTestId('submit-button'))

      await waitFor(() => {
        expect(defaultProps.afterSave).toHaveBeenCalled()
        expect(fetchMock.called(CREATE_URL)).toBe(true)
      })
      const userData = fetchMock.lastCall(CREATE_URL)?.[1]?.body
      expect(userData).toEqual(
        JSON.stringify({
          user: {
            name: 'John Doe',
            sortable_name: 'Doe, John',
            short_name: 'John Doe',
          },

          pseudonym: {
            send_confirmation: true,
            unique_id: 'john.doe@example.com',
          },
        }),
      )
    })

    it('runs validation before submitting', async () => {
      const user = userEvent.setup()
      const {getByTestId, getByText} = render(<CreateOrUpdateUserModal {...defaultProps} />)

      expect(getByText('Add a New User')).toBeInTheDocument()
      // submit without filling in fields
      await user.click(getByTestId('submit-button'))

      // expect validation errors
      expect(getByText('Name is required')).toBeInTheDocument()
      expect(getByText('Email is required')).toBeInTheDocument()
    })

    it('renders additional fields when enabled', async () => {
      fakeENV.setup({
        SHOW_SIS_ID_IN_NEW_USER_FORM: true,
        delegated_authentication: true,
        customized_login_handle_name: 'Fake HANDLE',
      })
      const {getByTestId, getByText} = render(<CreateOrUpdateUserModal {...defaultProps} />)

      expect(getByText('Add a New User')).toBeInTheDocument()

      // check for SIS fields
      expect(getByTestId('sis-id')).toBeInTheDocument()
      expect(getByTestId('path')).toBeInTheDocument()
      expect(getByText('Fake HANDLE')).toBeInTheDocument()
    })

    it('displays errors in form fields when API returns errors', async () => {
      // example case: another user already exists with the same SIS ID
      const user = userEvent.setup()
      fetchMock.post(CREATE_URL, {
        body: {
          errors: {
            user: {
              pseudonyms: [
                {
                  attribute: 'pseudonyms',
                  message: 'is invalid',
                  type: 'invalid',
                },
              ],
            },
            pseudonym: {
              sis_user_id: [
                {
                  attribute: 'sis_user_id',
                  message: 'SIS ID "11" is already in use',
                  type: 'taken',
                },
              ],
            },
          },
        },
        status: 400,
      })
      fakeENV.setup({
        SHOW_SIS_ID_IN_NEW_USER_FORM: true,
        delegated_authentication: false,
        customized_login_handle_name: null,
      })
      const {getByTestId, getByText} = render(<CreateOrUpdateUserModal {...defaultProps} />)

      fireEvent.change(getByTestId('full-name'), {target: {value: 'John Doe'}})
      fireEvent.change(getByTestId('unique-id'), {target: {value: 'john.doe@example.com'}})
      fireEvent.change(getByTestId('sis-id'), {target: {value: '100'}})
      await user.click(getByTestId('submit-button'))

      expect(fetchMock.called(CREATE_URL)).toBe(true)
      expect(defaultProps.afterSave).not.toHaveBeenCalled()
      await waitFor(() => {
        expect(getByText('The SIS ID is already in use')).toBeInTheDocument()
      })
    })
  })

  describe('update', () => {
    const updateProps = {
      ...defaultProps,
      createOrUpdate: 'update' as 'create' | 'update',
      url: '/accounts/2/users/12345',
      user: existingUser,
    }

    it('renders existing user data in the form', async () => {
      const {getByTestId, getByText} = render(<CreateOrUpdateUserModal {...updateProps} />)

      expect(getByText('Edit User Details')).toBeInTheDocument()

      expect(getByTestId('full-name')).toHaveValue(existingUser.name)
      expect(getByTestId('sortable-name')).toHaveValue(existingUser.sortable_name)
      expect(getByTestId('short-name')).toHaveValue(existingUser.short_name)
      expect(getByTestId('email')).toHaveValue(existingUser.email)
      const timeZoneValue = (getByTestId('time-zone') as HTMLSelectElement).value
      // value of the timezone dropdown includes name and time difference; just check the name part
      expect(timeZoneValue).toContain(existingUser.time_zone)
    })

    it('exclude email if field is blank on submit', async () => {
      const userWithBlankEmail = {...existingUser, email: ''}
      const blankEmailProps = {
        ...updateProps,
        user: userWithBlankEmail,
      }
      fetchMock.put(updateProps.url, {
        body: {user: userWithBlankEmail},
        status: 200,
      })
      const user = userEvent.setup()
      const {getByTestId, getByText} = render(<CreateOrUpdateUserModal {...blankEmailProps} />)

      expect(getByText('Edit User Details')).toBeInTheDocument()

      await user.click(getByTestId('submit-button'))

      expect(defaultProps.afterSave).toHaveBeenCalled()
      expect(fetchMock.called(updateProps.url)).toBe(true)
      const userData = fetchMock.lastCall(updateProps.url)?.[1]?.body
      expect(userData).toEqual(
        JSON.stringify({
          user: {
            name: userWithBlankEmail.name,
            sortable_name: userWithBlankEmail.sortable_name,
            short_name: userWithBlankEmail.short_name,
            time_zone: userWithBlankEmail.time_zone,
          },
        }),
      )
    })

    it('updates user when form is submitted', async () => {
      const updatedUser = {
        ...existingUser,
        sortable_name: 'Updated Name',
        email: 'updated.email@example.com',
      }
      fetchMock.put(updateProps.url, {
        body: {user: updatedUser},
        status: 200,
      })
      const user = userEvent.setup()
      const {getByTestId, getByText} = render(<CreateOrUpdateUserModal {...updateProps} />)

      expect(getByText('Edit User Details')).toBeInTheDocument()

      fireEvent.change(getByTestId('sortable-name'), {target: {value: 'Updated Name'}})
      fireEvent.change(getByTestId('email'), {target: {value: 'updated.email@example.com'}})

      await user.click(getByTestId('submit-button'))

      expect(defaultProps.afterSave).toHaveBeenCalled()
      expect(fetchMock.called(updateProps.url)).toBe(true)
      const userData = fetchMock.lastCall(updateProps.url)?.[1]?.body
      expect(userData).toEqual(
        JSON.stringify({
          user: {
            name: updatedUser.name,
            sortable_name: updatedUser.sortable_name,
            short_name: updatedUser.short_name,
            email: updatedUser.email,
            time_zone: updatedUser.time_zone,
          },
        }),
      )
    })

    it('runs validation before submitting', async () => {
      const user = userEvent.setup()
      const {getByTestId, getByText} = render(<CreateOrUpdateUserModal {...updateProps} />)

      expect(getByText('Edit User Details')).toBeInTheDocument()
      const fullNameInput = getByTestId('full-name')
      expect(getByTestId('full-name')).toHaveValue('Jane Smith')
      fireEvent.change(fullNameInput, {target: {value: ''}})

      await user.click(getByTestId('submit-button'))

      expect(getByText('Name is required')).toBeInTheDocument()
    })

    it('validates if an email if misformatted', async () => {
      const user = userEvent.setup()
      const {getByTestId, getByText} = render(<CreateOrUpdateUserModal {...updateProps} />)

      expect(getByText('Edit User Details')).toBeInTheDocument()
      const emailInput = getByTestId('email')
      fireEvent.change(emailInput, {target: {value: 'not-an-email'}})

      await user.click(getByTestId('submit-button'))

      expect(getByText('Email is invalid')).toBeInTheDocument()
    })
  })
})
