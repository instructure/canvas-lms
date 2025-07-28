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
import {render, screen} from '@testing-library/react'
import ForbiddenWordsFileUpload, {createFolder} from '../ForbiddenWordsFileUpload'
import userEvent from '@testing-library/user-event'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('../apiClient')

describe('ForbiddenWordsFileUpload Component', () => {
  const defaultProps = {
    open: true,
    onDismiss: jest.fn(),
    onSave: jest.fn(),
    setForbiddenWordsUrl: jest.fn(),
    setForbiddenWordsFilename: jest.fn(),
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('Rendering', () => {
    it('renders the modal with the correct heading', () => {
      // @ts-expect-error
      render(<ForbiddenWordsFileUpload {...defaultProps} />)
      expect(screen.getByText('Upload Forbidden Words/Terms List')).toBeInTheDocument()
      expect(screen.getByText('Upload File')).toBeInTheDocument()
    })

    it('displays the FileDrop component when no file is uploaded', () => {
      // @ts-expect-error
      render(<ForbiddenWordsFileUpload {...defaultProps} />)
      expect(screen.getByText('Upload File')).toBeInTheDocument()
      expect(screen.getByText('Drag and drop, or upload from your computer')).toBeInTheDocument()
    })
  })

  describe('Modal Interactions', () => {
    it('resets state on cancel and does not call prop functions', async () => {
      // @ts-expect-error
      render(<ForbiddenWordsFileUpload {...defaultProps} />)
      const cancelButton = screen.getByText('Cancel').closest('button')
      if (!cancelButton) {
        throw new Error('Cancel button not found')
      }
      await userEvent.click(cancelButton)
      expect(defaultProps.setForbiddenWordsFilename).not.toHaveBeenCalled()
      expect(defaultProps.setForbiddenWordsUrl).not.toHaveBeenCalled()
      expect(defaultProps.onDismiss).toHaveBeenCalled()
    })
  })

  describe('createFolder', () => {
    it('should create a folder and return its ID on a successful API call', async () => {
      const mockResponse = {
        response: {status: 200},
        text: JSON.stringify({id: 123}),
      }
      // @ts-expect-error
      doFetchApi.mockResolvedValue(mockResponse)
      const result = await createFolder()
      expect(result).toBe(123)
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'POST',
        path: `/api/v1/accounts/${ENV.DOMAIN_ROOT_ACCOUNT_ID}/folders`,
        body: expect.any(FormData),
      })
    })

    it('should return null if the API call fails', async () => {
      const mockErrorResponse = {
        response: {status: 500},
        text: 'Internal Server Error',
      }
      // @ts-expect-error
      doFetchApi.mockResolvedValue(mockErrorResponse)
      const result = await createFolder()
      expect(result).toBeNull()
      expect(doFetchApi).toHaveBeenCalled()
    })

    it('should return null if an error is thrown during execution', async () => {
      // @ts-expect-error
      doFetchApi.mockImplementation(() => {
        throw new Error('Network Error')
      })
      const result = await createFolder()
      expect(result).toBeNull()
      expect(doFetchApi).toHaveBeenCalled()
    })
  })
})
