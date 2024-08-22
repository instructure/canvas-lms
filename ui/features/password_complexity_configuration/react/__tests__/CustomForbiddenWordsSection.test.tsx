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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {render, screen, waitFor} from '@testing-library/react'
import React from 'react'
import CustomForbiddenWordsSection from '../CustomForbiddenWordsSection'
import userEvent from '@testing-library/user-event'

jest.mock('@canvas/do-fetch-api-effect')
const mockedDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

describe('CustomForbiddenWordsSection', () => {
  describe('when no file is uploaded', () => {
    beforeEach(() => {
      const mockResponse = {
        json: null,
        response: {
          ok: true,
          status: 200,
          statusText: 'OK',
        } as Partial<Response> as Response,
      }
      mockedDoFetchApi.mockResolvedValueOnce(mockResponse)
    })

    it('shows “Upload” button but not “Current Custom List”', async () => {
      const consoleErrorMock = jest.spyOn(console, 'error').mockImplementation(() => {})
      render(<CustomForbiddenWordsSection />)
      const uploadButton = await screen.findByTestId('uploadButton')
      expect(uploadButton).toBeInTheDocument()
      expect(uploadButton).toBeDisabled()
      expect(screen.queryByText('Current Custom List')).not.toBeInTheDocument()
      consoleErrorMock.mockRestore()
    })
  })

  describe('when a file is uploaded', () => {
    beforeEach(() => {
      const mockResponse = {
        ok: true,
        status: 200,
        statusText: 'OK',
        text: jest.fn().mockResolvedValue(
          JSON.stringify({
            public_url: 'mock_public_url',
            filename: 'mock_filename',
          })
        ),
        headers: new Headers(),
      } as Partial<Response> as Response
      mockedDoFetchApi.mockResolvedValueOnce({
        json: {public_url: 'mock_public_url', filename: 'mock_filename'},
        response: mockResponse,
      })
    })

    it('shows “Current Custom List” and hides the “Upload” button', async () => {
      render(<CustomForbiddenWordsSection />)
      await waitFor(() => {
        expect(screen.getByText('Current Custom List')).toBeInTheDocument()
        expect(screen.getByText('mock_filename')).toBeInTheDocument()
        const linkElement = screen.getByText('mock_filename').closest('a')
        expect(linkElement).toHaveAttribute('href', 'mock_public_url')
        expect(screen.queryByTestId('uploadButton')).not.toBeInTheDocument()
      })
    })

    it('opens the file upload modal when “Upload” button is clicked after deleting the custom list', async () => {
      render(<CustomForbiddenWordsSection />)
      await waitFor(() => {
        expect(screen.getByText('Current Custom List')).toBeInTheDocument()
        expect(screen.getByText('mock_filename')).toBeInTheDocument()
      })
      const deleteButton = await waitFor(() => screen.getByText(/delete list/i).closest('button'))
      if (!deleteButton) {
        throw new Error('Delete button not found')
      }
      await userEvent.click(deleteButton)
      const uploadButton = await screen.findByTestId('uploadButton')
      expect(uploadButton).toBeInTheDocument()
      expect(uploadButton).toBeEnabled()
      await userEvent.click(uploadButton)
      expect(screen.getByText('Upload Forbidden Words/Terms List')).toBeInTheDocument()
      const checkbox = await screen.findByTestId('customForbiddenWordsCheckbox')
      await userEvent.click(checkbox)
      expect(uploadButton).toBeDisabled()
    })
  })
})
