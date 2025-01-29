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

import React from 'react'
import {render, screen, waitFor, cleanup} from '@testing-library/react'
import '@testing-library/jest-dom'
import PasswordComplexityConfiguration from '../PasswordComplexityConfiguration'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import userEvent from '@testing-library/user-event'

jest.mock('@canvas/do-fetch-api-effect/apiRequest')
const mockedExecuteApiRequest = executeApiRequest as jest.MockedFunction<typeof executeApiRequest>

const MOCK_MINIMUM_CHARACTER_LENGTH = '8'
const MOCK_MAXIMUM_LOGIN_ATTEMPTS = '10'

const getViewOptionsButton = async () => {
  const viewOptions = await waitFor(() => {
    const button = screen.getByText('View Options')
    return button.closest('button')
  })
  if (!viewOptions) {
    throw new Error('View Options button not found')
  }
  return viewOptions
}

describe('PasswordComplexityConfiguration Component', () => {
  beforeAll(() => {
    if (!window.ENV) {
      // @ts-expect-error
      window.ENV = {}
    }
    window.ENV.DOMAIN_ROOT_ACCOUNT_ID = '1'
  })

  afterAll(() => {
    // @ts-expect-error
    delete window.ENV.DOMAIN_ROOT_ACCOUNT_ID
  })

  afterEach(() => {
    jest.clearAllMocks()
    cleanup()
  })

  beforeEach(() => {
    mockedExecuteApiRequest.mockResolvedValue({
      status: 200,
      data: {
        password_policy: {
          minimum_character_length: MOCK_MINIMUM_CHARACTER_LENGTH,
          maximum_login_attempts: MOCK_MAXIMUM_LOGIN_ATTEMPTS,
        },
      },
    })
  })

  describe('tray Interaction', () => {
    it('opens the tray when "View Options" button is clicked', async () => {
      render(<PasswordComplexityConfiguration />)
      await userEvent.click(await getViewOptionsButton())
      expect(screen.getByText('Current Password Configuration')).toBeInTheDocument()
    })

    it('closes the tray when "Cancel" button is clicked', async () => {
      render(<PasswordComplexityConfiguration />)
      await userEvent.click(await getViewOptionsButton())
      expect(screen.getByText('Current Password Configuration')).toBeInTheDocument()
      const cancelButton = await screen.findByTestId('cancelButton')
      await userEvent.click(cancelButton)
      expect(screen.queryByText('Password Options Tray')).not.toBeInTheDocument()
    })
  })

  describe('form control UI Interaction Tests', () => {
    describe('input field states', () => {
      beforeEach(async () => {
        render(<PasswordComplexityConfiguration />)
        await userEvent.click(await getViewOptionsButton())
      })

      it('enables minimum character length input by default', async () => {
        const input = await screen.findByTestId('minimumCharacterLengthInput')
        expect(input).toBeEnabled()
      })

      it('enables custom max login attempts input by default', async () => {
        const input = await screen.findByTestId('customMaxLoginAttemptsInput')
        expect(input).toBeEnabled()
      })

      it('enables allow login suspension checkbox when custom max login attempts is checked', async () => {
        const checkbox = await screen.findByTestId('allowLoginSuspensionCheckbox')
        expect(checkbox).toBeEnabled()
      })

      it('disables custom max login attempts input and allow suspension login checkbox when its checkbox is unchecked', async () => {
        const checkbox = await screen.findByTestId('customMaxLoginAttemptsCheckbox')
        await userEvent.click(checkbox)
        const input = await screen.findByTestId('customMaxLoginAttemptsInput')
        const allowLoginSuspensionCheckbox = await screen.findByTestId(
          'allowLoginSuspensionCheckbox',
        )
        expect(input).toBeDisabled()
        expect(allowLoginSuspensionCheckbox).toBeDisabled()
      })

      it('re-enables custom max login attempts input and allow login suspension checkbox when checkbox is checked again', async () => {
        const checkbox = await screen.findByTestId('customMaxLoginAttemptsCheckbox')
        await userEvent.click(checkbox)
        await userEvent.click(checkbox)
        const input = await screen.findByTestId('customMaxLoginAttemptsInput')
        const allowLoginSuspensionCheckbox = await screen.findByTestId(
          'allowLoginSuspensionCheckbox',
        )
        expect(input).toBeEnabled()
        expect(allowLoginSuspensionCheckbox).toBeEnabled()
      })
    })
  })

  describe('API calls', () => {
    it('should handle default password_policy settings gracefully', async () => {
      render(<PasswordComplexityConfiguration />)
      await userEvent.click(await getViewOptionsButton())
      await waitFor(() => expect(screen.getByTestId('cancelButton')).toBeEnabled())
      expect(screen.getByTestId('minimumCharacterLengthInput')).toHaveValue(
        MOCK_MINIMUM_CHARACTER_LENGTH,
      )
      expect(screen.getByTestId('customMaxLoginAttemptsCheckbox')).toBeChecked()
      expect(screen.getByTestId('requireNumbersCheckbox')).not.toBeChecked()
      expect(screen.getByTestId('requireSymbolsCheckbox')).not.toBeChecked()
    })

    it('should handle missing password_policy key gracefully', async () => {
      mockedExecuteApiRequest.mockResolvedValue({
        status: 200,
        data: {},
      })
      render(<PasswordComplexityConfiguration />)
      await userEvent.click(await getViewOptionsButton())
      await waitFor(() => expect(screen.getByTestId('cancelButton')).toBeEnabled())
      expect(
        screen.queryByText('An error occurred fetching password policy settings.'),
      ).not.toBeInTheDocument()
      expect(screen.getByTestId('minimumCharacterLengthInput')).toHaveValue(
        MOCK_MINIMUM_CHARACTER_LENGTH,
      )
      expect(screen.getByTestId('requireNumbersCheckbox')).not.toBeChecked()
      expect(screen.getByTestId('requireSymbolsCheckbox')).not.toBeChecked()
    })

    it('should handle undefined password_policy key gracefully', async () => {
      mockedExecuteApiRequest.mockResolvedValue({
        status: 200,
        data: {
          password_policy: undefined,
        },
      })
      render(<PasswordComplexityConfiguration />)
      await userEvent.click(await getViewOptionsButton())
      await waitFor(() => expect(screen.getByTestId('cancelButton')).toBeEnabled())
      expect(
        screen.queryByText('An error occurred fetching password policy settings.'),
      ).not.toBeInTheDocument()
      expect(screen.getByTestId('minimumCharacterLengthInput')).toHaveValue(
        MOCK_MINIMUM_CHARACTER_LENGTH,
      )
      expect(screen.getByTestId('requireNumbersCheckbox')).not.toBeChecked()
      expect(screen.getByTestId('requireSymbolsCheckbox')).not.toBeChecked()
    })

    it('should handle completely empty password_policy', async () => {
      mockedExecuteApiRequest.mockResolvedValue({
        status: 200,
        data: {
          password_policy: {},
        },
      })
      render(<PasswordComplexityConfiguration />)
      await userEvent.click(await getViewOptionsButton())
      await waitFor(() => expect(screen.getByTestId('cancelButton')).toBeEnabled())
      expect(
        screen.queryByText('An error occurred fetching password policy settings.'),
      ).not.toBeInTheDocument()
      expect(screen.getByTestId('minimumCharacterLengthInput')).toHaveValue(
        MOCK_MINIMUM_CHARACTER_LENGTH,
      )
      expect(screen.getByTestId('requireNumbersCheckbox')).not.toBeChecked()
      expect(screen.getByTestId('requireSymbolsCheckbox')).not.toBeChecked()
    })

    it('should handle missing nested keys in password_policy', async () => {
      const minimumCharacterLength = '12'
      mockedExecuteApiRequest.mockResolvedValue({
        status: 200,
        data: {
          password_policy: {
            require_number_characters: 'true',
            allow_login_suspension: 'false',
            minimum_character_length: minimumCharacterLength,
          },
        },
      })
      render(<PasswordComplexityConfiguration />)
      await userEvent.click(await getViewOptionsButton())
      await waitFor(() => expect(screen.getByTestId('cancelButton')).toBeEnabled())
      expect(screen.getByTestId('requireSymbolsCheckbox')).not.toBeChecked()
      expect(screen.getByTestId('customMaxLoginAttemptsCheckbox')).not.toBeChecked()
      expect(screen.getByTestId('minimumCharacterLengthInput')).toHaveValue(minimumCharacterLength)
      expect(screen.getByTestId('customForbiddenWordsCheckbox')).not.toBeChecked()
    })
  })

  describe('Saving settings', () => {
    it('makes a PUT request with the correct method and path when saving all settings, including defaults', async () => {
      render(<PasswordComplexityConfiguration />)
      await userEvent.click(await getViewOptionsButton())
      const checkbox = await screen.findByTestId('requireNumbersCheckbox')
      await userEvent.click(checkbox)
      const saveButton = await screen.findByTestId('saveButton')
      await userEvent.click(saveButton)
      const putCall = mockedExecuteApiRequest.mock.calls.find(call => call[0].method === 'PUT')
      expect(putCall).toEqual([
        {
          method: 'PUT',
          body: {
            account: {
              settings: {
                password_policy: {
                  require_number_characters: true,
                  require_symbol_characters: false,
                  allow_login_suspension: false,
                  maximum_login_attempts: MOCK_MAXIMUM_LOGIN_ATTEMPTS,
                  minimum_character_length: MOCK_MINIMUM_CHARACTER_LENGTH,
                },
              },
            },
          },
          path: '/api/v1/accounts/1/',
        },
      ])
    })
  })
})
