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
import PasswordComplexityConfiguration from '../PasswordComplexityConfiguration'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import fakeEnv from '@canvas/test-utils/fakeENV'

const MOCK_MINIMUM_CHARACTER_LENGTH = '8'
const MOCK_MAXIMUM_LOGIN_ATTEMPTS = '10'

// Track PUT requests for verification
let lastPutRequest: {method: string; path: string; body: any} | null = null

const defaultPasswordPolicy = {
  minimum_character_length: MOCK_MINIMUM_CHARACTER_LENGTH,
  maximum_login_attempts: MOCK_MAXIMUM_LOGIN_ATTEMPTS,
}

const server = setupServer(
  http.get('/api/v1/accounts/:accountId/settings', () => {
    return HttpResponse.json({
      password_policy: defaultPasswordPolicy,
    })
  }),
  http.put('/api/v1/accounts/:accountId/', async ({request}) => {
    const body = await request.json()
    lastPutRequest = {
      method: 'PUT',
      path: new URL(request.url).pathname,
      body,
    }
    return HttpResponse.json({})
  }),
)

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
    server.listen()
    fakeEnv.setup({DOMAIN_ROOT_ACCOUNT_ID: '1'})
  })

  afterAll(() => {
    server.close()
    fakeEnv.teardown()
  })

  afterEach(() => {
    server.resetHandlers()
    cleanup()
  })

  beforeEach(() => {
    lastPutRequest = null
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
      server.use(
        http.get('/api/v1/accounts/:accountId/settings', () => {
          return HttpResponse.json({})
        }),
      )
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
      server.use(
        http.get('/api/v1/accounts/:accountId/settings', () => {
          return HttpResponse.json({
            password_policy: undefined,
          })
        }),
      )
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
      server.use(
        http.get('/api/v1/accounts/:accountId/settings', () => {
          return HttpResponse.json({
            password_policy: {},
          })
        }),
      )
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
      server.use(
        http.get('/api/v1/accounts/:accountId/settings', () => {
          return HttpResponse.json({
            password_policy: {
              require_number_characters: 'true',
              allow_login_suspension: 'false',
              minimum_character_length: minimumCharacterLength,
            },
          })
        }),
      )
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
      await waitFor(() => {
        expect(lastPutRequest).not.toBeNull()
      })
      expect(lastPutRequest).toEqual({
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
      })
    })
  })
})
