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
import {render, screen, waitFor} from '@testing-library/react'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import PasswordComplexityConfiguration from '../PasswordComplexityConfiguration'
import userEvent from '@testing-library/user-event'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')
const mockedDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

jest.mock('@canvas/do-fetch-api-effect/apiRequest')
const mockedExecuteApiRequest = executeApiRequest as jest.MockedFunction<typeof executeApiRequest>

beforeAll(() => {
  if (!window.ENV) {
    window.ENV = {}
  }

  window.ENV.DOMAIN_ROOT_ACCOUNT_ID = '1'
})

afterAll(() => {
  delete window.ENV.DOMAIN_ROOT_ACCOUNT_ID
})

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

describe('PasswordComplexityConfiguration', () => {
  beforeEach(() => {
    mockedDoFetchApi.mockResolvedValue({
      json: {url: 'http://example.com/mockfile.txt', display_name: 'mockfile.txt'},
      response: {
        ok: true,
        status: 200,
        statusText: 'OK',
        text: jest.fn().mockResolvedValue('{}'),
        headers: new Headers(),
      } as Partial<Response> as Response,
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it.skip('opens the Tray when “View Options” button is clicked', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    expect(screen.getByText('Current Password Configuration')).toBeInTheDocument()
  })

  it.skip('toggles all checkboxes with defaults set', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    let checkbox = await screen.findByTestId('minimumCharacterLengthCheckbox')
    await userEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()
    checkbox = await screen.findByTestId('requireNumbersCheckbox')
    await userEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()
    checkbox = await screen.findByTestId('requireSymbolsCheckbox')
    await userEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()
    checkbox = await screen.findByTestId('customForbiddenWordsCheckbox')
    await userEvent.click(checkbox)
    expect(checkbox).toBeChecked()
    await userEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
  })

  it.skip('toggles input fields when checkbox is checked', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    let input = await screen.findByTestId('minimumCharacterLengthInput')
    expect(input).toBeEnabled()
    const checkbox = await screen.findByTestId('customMaxLoginAttemptsCheckbox')
    await userEvent.click(checkbox)
    input = await screen.findByTestId('customMaxLoginAttemptsInput')
    expect(input).toBeEnabled()
  })

  it.skip('closes the Tray when “Cancel” button is clicked', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    const cancelButton = await screen.findByTestId('cancelButton')
    await userEvent.click(cancelButton)
    expect(screen.queryByText('Password Options Tray')).not.toBeInTheDocument()
  })

  it.skip('makes a GET request to fetch settings when the component is rendered', async () => {
    mockedExecuteApiRequest.mockResolvedValueOnce({
      status: 200,
      data: {
        password_policy: {
          require_number_characters: 'true',
          require_symbol_characters: 'true',
          minimum_character_length: 12,
        },
        common_passwords_attachment_id: 12345,
        password_policy_folder_id: 67890,
      },
    })
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    expect(mockedExecuteApiRequest).toHaveBeenCalledWith({
      method: 'GET',
      path: '/api/v1/accounts/1/settings',
    })
  })

  it.skip('makes a PUT request with the correct method and path when saving settings', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    const saveButton = await screen.findByTestId('saveButton')
    await userEvent.click(saveButton)
    expect(mockedExecuteApiRequest).toHaveBeenCalledWith({
      method: 'PUT',
      body: {
        account: {
          settings: {
            password_policy: {
              allow_login_suspension: false,
              minimum_character_length: 8,
              require_number_characters: true,
              require_symbol_characters: true,
            },
          },
        },
      },
      path: '/api/v1/accounts/1/',
    })
  })

  it.skip('fetches and sets commonPasswordsAttachmentId and commonPasswordsFolderId', async () => {
    mockedExecuteApiRequest.mockResolvedValueOnce({
      status: 200,
      data: {
        password_policy: {
          require_number_characters: 'true',
          require_symbol_characters: 'true',
          minimum_character_length: 12,
          common_passwords_attachment_id: 12345,
          password_policy_folder_id: 67890,
        },
      },
    })
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    await waitFor(() => {
      expect(mockedExecuteApiRequest).toHaveBeenCalledWith({
        path: '/api/v1/accounts/1/settings',
        method: 'GET',
      })
    })
    await waitFor(() => {
      const checkbox = screen.getByTestId('customForbiddenWordsCheckbox')
      expect(checkbox).toBeInTheDocument()
      expect(screen.getByText('Current Custom List')).toBeInTheDocument()
    })
  })

  it.skip('does not make an API call if commonPasswordsAttachmentId is null', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    expect(mockedDoFetchApi).not.toHaveBeenCalled()
  })
})
