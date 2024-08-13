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
import doFetchApi from '@canvas/do-fetch-api-effect'
import PasswordComplexityConfiguration from '../PasswordComplexityConfiguration'
import userEvent from '@testing-library/user-event'

jest.mock('@canvas/do-fetch-api-effect/apiRequest')
jest.mock('@canvas/do-fetch-api-effect')

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
    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: {
        public_url: 'mock_public_url',
        filename: 'mock_filename',
      },
    })
  })

  it('opens the Tray when "View Options" button is clicked', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    expect(screen.getByText('Current Password Configuration')).toBeInTheDocument()
  })

  it('toggles all checkboxes with defaults set', async () => {
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

  it('toggles input fields when checkbox is checked', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    let checkbox = await screen.findByTestId('minimumCharacterLengthCheckbox')
    let input = await screen.findByTestId('minimumCharacterLengthInput')
    expect(input).toBeEnabled()
    checkbox = await screen.findByTestId('customMaxLoginAttemptsCheckbox')
    await userEvent.click(checkbox)
    input = await screen.findByTestId('customMaxLoginAttemptsInput')
    expect(input).toBeEnabled()
  })

  it('opens the file upload modal when “Upload” button is clicked', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    const checkbox = await screen.findByTestId('customForbiddenWordsCheckbox')
    await userEvent.click(checkbox)
    await userEvent.click(await screen.findByTestId('uploadButton'))
    expect(screen.getByText('Upload Forbidden Words/Terms List')).toBeInTheDocument()
  })

  it('shows “Upload” button but not “Current Custom List” when no file is uploaded', async () => {
    doFetchApi.mockResolvedValueOnce({
      response: {ok: true},
      json: null,
    })
    const consoleErrorMock = jest.spyOn(console, 'error').mockImplementation(() => {})
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    const uploadButton = await screen.findByTestId('uploadButton')
    expect(uploadButton).toBeInTheDocument()
    expect(screen.queryByText('Current Custom List')).not.toBeInTheDocument()
    consoleErrorMock.mockRestore()
  })

  it('shows "Current Custom List" when a file is uploaded', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    const uploadButton = await screen.findByTestId('uploadButton')
    expect(uploadButton).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getByText('Current Custom List')).toBeInTheDocument()
      expect(screen.getByText('mock_filename')).toBeInTheDocument()
      const linkElement = screen.getByText('mock_filename').closest('a')
      expect(linkElement).toHaveAttribute('href', 'mock_public_url')
    })
  })

  it('closes the Tray when "Cancel" button is clicked', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    const cancelButton = await screen.findByTestId('cancelButton')
    await userEvent.click(cancelButton)
    expect(screen.queryByText('Password Options Tray')).not.toBeInTheDocument()
  })

  it('makes a PUT request with the correct method and path', async () => {
    render(<PasswordComplexityConfiguration />)
    await userEvent.click(await getViewOptionsButton())
    const saveButton = await screen.findByTestId('saveButton')
    await userEvent.click(saveButton)
    expect(executeApiRequest).toHaveBeenCalledWith({
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
      path: '/api/v1/accounts/undefined/',
    })
  })
})
