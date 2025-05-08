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

import {fireEvent, render, screen} from '@testing-library/react'
import AddEditPseudonym, {type AddEditPseudonymProps} from '../AddEditPseudonym'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

describe('AddEditPseudonym', () => {
  const policy = {
    maximum_login_attempts: '8',
    minimum_character_length: '8',
  }
  const pseudonym = {
    account_id: 1,
    id: '5',
    unique_id: 'unique id',
    integration_id: 'integration id',
    sis_user_id: 'sis user id',
  }
  const props: AddEditPseudonymProps = {
    accountIdPasswordPolicyMap: {
      1: policy,
      2: policy,
    },
    accountSelectOptions: [
      {
        label: 'Fake Academy',
        value: 1,
      },
      {
        label: 'Site Admin',
        value: 2,
      },
    ],
    canChangePassword: false,
    canManageSis: true,
    defaultPolicy: policy,
    isDelegatedAuth: false,
    isEdit: false,
    userId: '123',
    pseudonym,
    onClose: jest.fn(),
    onSubmit: jest.fn(),
  }
  const CREATE_LOGIN_URL = `/users/${props.userId}/pseudonyms`
  const UPDATE_LOGIN_URL = `/users/${props.userId}/pseudonyms/${pseudonym.id}`

  describe('when the user editing a pseudonym', () => {
    const editProps = {
      ...props,
      isEdit: true,
    }

    it('should render the selected pseudonym', () => {
      render(<AddEditPseudonym {...editProps} />)
      const uniqueId = screen.getByLabelText('Login *')
      const integrationId = screen.getByLabelText('Integration ID')
      const sisUserId = screen.getByLabelText('SIS ID')

      expect(uniqueId).toHaveValue(pseudonym.unique_id)
      expect(integrationId).toHaveValue(pseudonym.integration_id)
      expect(sisUserId).toHaveValue(pseudonym.sis_user_id)
    })

    it('should not render integration and sis id fields', () => {
      render(<AddEditPseudonym {...editProps} canManageSis={false} />)
      const uniqueId = screen.getByLabelText('Login *')
      const integrationId = screen.queryByLabelText('Integration ID')
      const sisUserId = screen.queryByLabelText('SIS ID')

      expect(uniqueId).toBeInTheDocument()
      expect(integrationId).not.toBeInTheDocument()
      expect(sisUserId).not.toBeInTheDocument()
    })

    it('should not render the account select field', () => {
      render(<AddEditPseudonym {...editProps} />)
      const account = screen.queryByLabelText('Account')

      expect(account).not.toBeInTheDocument()
    })

    it('should render password fields', () => {
      render(<AddEditPseudonym {...editProps} canChangePassword={true} />)
      const password = screen.getByLabelText('Password')
      const passwordConfirmation = screen.getByLabelText('Confirm Password')

      expect(password).toBeInTheDocument()
      expect(passwordConfirmation).toBeInTheDocument()
    })

    it('should render the note section in case of delegated auth', () => {
      render(<AddEditPseudonym {...editProps} canChangePassword={true} isDelegatedAuth={true} />)
      const note = screen.getByText(/Note: This login's account uses delegated authentication/)

      expect(note).toBeInTheDocument()
    })

    it('should form submission work if every input is valid', async () => {
      const updatedPseudonym = {
        ...pseudonym,
        unique_id: 'updated unique id',
        integration_id: 'updated integration id',
        sis_user_id: 'updated sis user id',
      }
      fetchMock.put(
        UPDATE_LOGIN_URL,
        {status: 200, body: updatedPseudonym},
        {overwriteRoutes: true},
      )
      render(<AddEditPseudonym {...editProps} />)
      const uniqueId = screen.getByLabelText('Login *')
      const sisId = screen.getByLabelText('SIS ID')
      const integrationId = screen.getByLabelText('Integration ID')
      const submit = screen.getByTestId('add-edit-pseudonym-submit')

      fireEvent.change(uniqueId, {target: {value: updatedPseudonym.unique_id}})
      fireEvent.change(sisId, {target: {value: updatedPseudonym.sis_user_id}})
      fireEvent.change(integrationId, {target: {value: updatedPseudonym.integration_id}})
      await userEvent.click(submit)

      expect(editProps.onSubmit).toHaveBeenCalledWith(updatedPseudonym)
      const {id, ...expectedPayload} = updatedPseudonym
      expect(
        fetchMock.called(UPDATE_LOGIN_URL, {
          method: 'PUT',
          body: {pseudonym: expectedPayload},
        }),
      ).toBeTruthy()
    })
  })

  describe('when the user creating a pseudonym', () => {
    const addProps = {
      ...props,
      isEdit: false,
      isDelegatedAuth: false,
      canChangePassword: true,
      pseudonym: undefined,
    }
    it('should render all possible fields', () => {
      render(<AddEditPseudonym {...addProps} />)
      const uniqueId = screen.getByLabelText('Login *')
      const integrationId = screen.getByLabelText('Integration ID')
      const sisUserId = screen.getByLabelText('SIS ID')
      const account = screen.getByLabelText('Account')
      const password = screen.getByLabelText('Password')
      const passwordConfirmation = screen.getByLabelText('Confirm Password')

      expect(uniqueId).toBeInTheDocument()
      expect(integrationId).toBeInTheDocument()
      expect(sisUserId).toBeInTheDocument()
      expect(account).toBeInTheDocument()
      expect(account).toHaveValue(addProps.accountSelectOptions[0].label)
      expect(password).toBeInTheDocument()
      expect(passwordConfirmation).toBeInTheDocument()
    })

    it('should not render integration and sis id fields', () => {
      render(<AddEditPseudonym {...addProps} canManageSis={false} />)
      const uniqueId = screen.getByLabelText('Login *')
      const integrationId = screen.queryByLabelText('Integration ID')
      const sisUserId = screen.queryByLabelText('SIS ID')
      const account = screen.getByLabelText('Account')
      const password = screen.getByLabelText('Password')
      const passwordConfirmation = screen.getByLabelText('Confirm Password')

      expect(uniqueId).toBeInTheDocument()
      expect(integrationId).not.toBeInTheDocument()
      expect(sisUserId).not.toBeInTheDocument()
      expect(account).toBeInTheDocument()
      expect(password).toBeInTheDocument()
      expect(passwordConfirmation).toBeInTheDocument()
    })

    describe('and validating fields', () => {
      it('should show an error when the login field is empty', async () => {
        render(<AddEditPseudonym {...addProps} />)
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        await userEvent.click(submit)

        const error = await screen.findByText('Login is required.')
        expect(error).toBeInTheDocument()
      })

      it('should show an error when the value of the login field is already in use', async () => {
        fetchMock.post(
          CREATE_LOGIN_URL,
          {
            status: 400,
            body: {
              errors: {
                unique_id: [
                  {
                    attribute: 'unique_id',
                    type: 'taken',
                    message: 'ID already in use for this account and authentication provider',
                  },
                ],
              },
            },
          },
          {overwriteRoutes: true},
        )
        render(<AddEditPseudonym {...addProps} />)
        const uniqueIdValue = 'already_in_use'
        const passwordValue = 'test1234%'
        const uniqueId = screen.getByLabelText('Login *')
        const password = screen.getByLabelText('Password')
        const passwordConfirmation = screen.getByLabelText('Confirm Password')
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        fireEvent.change(uniqueId, {target: {value: uniqueIdValue}})
        fireEvent.change(password, {target: {value: passwordValue}})
        fireEvent.change(passwordConfirmation, {target: {value: passwordValue}})
        await userEvent.click(submit)

        const error = await screen.findByText('Already in use')
        expect(error).toBeInTheDocument()
      })

      it('should allow password fields to be empty', async () => {
        fetchMock.post(CREATE_LOGIN_URL, 200, {overwriteRoutes: true})
        render(<AddEditPseudonym {...addProps} />)
        const uniqueIdValue = 'unique id'
        const uniqueId = screen.getByLabelText('Login *')
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        fireEvent.change(uniqueId, {target: {value: uniqueIdValue}})
        await userEvent.click(submit)

        expect(
          fetchMock.called(CREATE_LOGIN_URL, {
            method: 'POST',
            body: {
              pseudonym: {
                unique_id: uniqueIdValue,
                sis_user_id: '',
                integration_id: '',
                account_id: addProps.accountSelectOptions[0].value,
              },
            },
          }),
        ).toBeTruthy()
      })

      it('should show and error when the password is too short', async () => {
        render(<AddEditPseudonym {...addProps} />)
        const minCharacterLength = policy.minimum_character_length
        const uniqueIdValue = 'unique id'
        const passwordValue = 't'
        const uniqueId = screen.getByLabelText('Login *')
        const password = screen.getByLabelText('Password')
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        fireEvent.change(uniqueId, {target: {value: uniqueIdValue}})
        fireEvent.change(password, {target: {value: passwordValue}})
        await userEvent.click(submit)

        const error = await screen.findByText(`Must be at least ${minCharacterLength} characters.`)
        expect(error).toBeInTheDocument()
      })

      it('should show and error when the password does not contain a symbol', async () => {
        fetchMock.post(
          CREATE_LOGIN_URL,
          {
            status: 400,
            body: {
              errors: {
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
          {overwriteRoutes: true},
        )
        render(<AddEditPseudonym {...addProps} />)
        const passwordValue = 'test12345'
        const uniqueId = screen.getByLabelText('Login *')
        const password = screen.getByLabelText('Password')
        const passwordConfirmation = screen.getByLabelText('Confirm Password')
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        fireEvent.change(uniqueId, {target: {value: 'test login'}})
        fireEvent.change(password, {target: {value: passwordValue}})
        fireEvent.change(passwordConfirmation, {target: {value: passwordValue}})
        await userEvent.click(submit)

        const error = await screen.findByText('Must include at least one symbol')
        expect(error).toBeInTheDocument()
      })

      it('should show and error if password does not match with confirm password', async () => {
        render(<AddEditPseudonym {...addProps} />)
        const uniqueId = screen.getByLabelText('Login *')
        const password = screen.getByLabelText('Password')
        const passwordConfirmation = screen.getByLabelText('Confirm Password')
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        fireEvent.change(uniqueId, {target: {value: 'test login'}})
        fireEvent.change(password, {target: {value: 'test1234%`'}})
        fireEvent.change(passwordConfirmation, {target: {value: '1234%test'}})
        await userEvent.click(submit)

        const error = await screen.findByText('Passwords do not match.')
        expect(error).toBeInTheDocument()
      })

      it('should show an error alert in case of insufficient permission', async () => {
        fetchMock.post(CREATE_LOGIN_URL, {status: 401, body: {}}, {overwriteRoutes: true})
        render(<AddEditPseudonym {...addProps} canChangePassword={false} />)
        const passwordValue = 'test12345'
        const uniqueId = screen.getByLabelText('Login *')
        const password = screen.getByLabelText('Password')
        const passwordConfirmation = screen.getByLabelText('Confirm Password')
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        fireEvent.change(uniqueId, {target: {value: 'test login'}})
        fireEvent.change(password, {target: {value: passwordValue}})
        fireEvent.change(passwordConfirmation, {target: {value: passwordValue}})
        await userEvent.click(submit)

        const alert = await screen.findAllByText(
          'You do not have sufficient privileges to make the change requested.',
        )
        expect(alert.length).toBeTruthy()
      })

      it('should show an error alert in case of unexpected server error', async () => {
        fetchMock.post(CREATE_LOGIN_URL, {status: 500, body: {}}, {overwriteRoutes: true})
        render(<AddEditPseudonym {...addProps} canChangePassword={false} />)
        const passwordValue = 'test12345'
        const uniqueId = screen.getByLabelText('Login *')
        const password = screen.getByLabelText('Password')
        const passwordConfirmation = screen.getByLabelText('Confirm Password')
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        fireEvent.change(uniqueId, {target: {value: 'test login'}})
        fireEvent.change(password, {target: {value: passwordValue}})
        fireEvent.change(passwordConfirmation, {target: {value: passwordValue}})
        await userEvent.click(submit)

        const alert = await screen.findAllByText('An error occurred while adding login.')
        expect(alert.length).toBeTruthy()
      })
    })

    it('should form submission work if every input is valid', async () => {
      fetchMock.post(CREATE_LOGIN_URL, {status: 200, body: pseudonym}, {overwriteRoutes: true})
      render(<AddEditPseudonym {...addProps} canChangePassword={false} />)
      const passwordValue = 'test1234%'
      const uniqueId = screen.getByLabelText('Login *')
      const sisId = screen.getByLabelText('SIS ID')
      const integrationId = screen.getByLabelText('Integration ID')
      const password = screen.getByLabelText('Password')
      const passwordConfirmation = screen.getByLabelText('Confirm Password')
      const submit = screen.getByTestId('add-edit-pseudonym-submit')

      fireEvent.change(uniqueId, {target: {value: pseudonym.unique_id}})
      fireEvent.change(sisId, {target: {value: pseudonym.sis_user_id}})
      fireEvent.change(integrationId, {target: {value: pseudonym.integration_id}})
      fireEvent.change(password, {target: {value: passwordValue}})
      fireEvent.change(passwordConfirmation, {target: {value: passwordValue}})
      await userEvent.click(submit)

      expect(addProps.onSubmit).toHaveBeenCalledWith(pseudonym)
      const {id, ...restOfPseudonym} = pseudonym
      const expectedPayload = {
        ...restOfPseudonym,
        password: passwordValue,
        password_confirmation: passwordValue,
      }
      expect(
        fetchMock.called(CREATE_LOGIN_URL, {
          method: 'POST',
          body: {pseudonym: expectedPayload},
        }),
      ).toBeTruthy()
    })

    describe('when the user is an admin but not a site admin (ENV.ACCOUNT_SELECT_OPTIONS and ENV.PASSWORD_POLICIES are not available)', () => {
      const addPropsForNonSiteAdmin = {
        ...addProps,
        accountSelectOptions: [],
        accountIdPasswordPolicyMap: undefined,
      }
      it('should not render the account select field', () => {
        render(<AddEditPseudonym {...addPropsForNonSiteAdmin} />)
        const account = screen.queryByLabelText('Account')

        expect(account).not.toBeInTheDocument()
      })

      it('should be able to create a login', async () => {
        fetchMock.post(CREATE_LOGIN_URL, {status: 200, body: pseudonym}, {overwriteRoutes: true})
        render(<AddEditPseudonym {...addPropsForNonSiteAdmin} />)
        const passwordValue = 'test1234%'
        const uniqueId = screen.getByLabelText('Login *')
        const password = screen.getByLabelText('Password')
        const passwordConfirmation = screen.getByLabelText('Confirm Password')
        const submit = screen.getByTestId('add-edit-pseudonym-submit')

        fireEvent.change(uniqueId, {target: {value: pseudonym.unique_id}})
        fireEvent.change(password, {target: {value: passwordValue}})
        fireEvent.change(passwordConfirmation, {target: {value: passwordValue}})
        await userEvent.click(submit)

        expect(addProps.onSubmit).toHaveBeenCalledWith(pseudonym)
        const expectedPayload = {
          unique_id: pseudonym.unique_id,
          sis_user_id: '',
          integration_id: '',
          password: passwordValue,
          password_confirmation: passwordValue,
        }
        expect(
          fetchMock.called(CREATE_LOGIN_URL, {
            method: 'POST',
            body: {pseudonym: expectedPayload},
          }),
        ).toBeTruthy()
      })
    })
  })
})
