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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {SuggestionsEnabledToggleSection} from '../SuggestionsEnabledToggleSection'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('@canvas/do-fetch-api-effect')

describe('SuggestionsEnabledToggleSection', () => {
  const defaultProps = {
    checked: true,
    onChange: jest.fn(),
  }

  const setup = (props = {}) => {
    const mergedProps = {...defaultProps, ...props}
    return render(<SuggestionsEnabledToggleSection {...mergedProps} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
    ;(doFetchApi as jest.Mock).mockResolvedValue({})
  })

  describe('Rendering Tests', () => {
    it('renders toggle with label text', () => {
      setup()

      expect(screen.getByTestId('suggestions-toggle-label')).toHaveTextContent(
        'Show suggestions when typing',
      )
    })

    it('renders checkbox with screen reader label', () => {
      setup()

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      expect(checkbox).toBeInTheDocument()
    })

    it('renders with checked state when checked is true', () => {
      setup({checked: true})

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      expect(checkbox).toBeChecked()
    })

    it('renders with unchecked state when checked is false', () => {
      setup({checked: false})

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      expect(checkbox).not.toBeChecked()
    })

    it('renders with correct test id', () => {
      setup()

      expect(screen.getByTestId('comment-suggestions-when-typing')).toBeInTheDocument()
    })
  })

  describe('User Interaction Tests', () => {
    it('calls onChange with true when unchecked checkbox is clicked', async () => {
      const user = userEvent.setup()
      const onChange = jest.fn()
      setup({checked: false, onChange})

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      await user.click(checkbox)

      expect(onChange).toHaveBeenCalledWith(true)
    })

    it('calls onChange with false when checked checkbox is clicked', async () => {
      const user = userEvent.setup()
      const onChange = jest.fn()
      setup({checked: true, onChange})

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      await user.click(checkbox)

      expect(onChange).toHaveBeenCalledWith(false)
    })
  })

  describe('API Integration Tests', () => {
    it('calls API with correct settings when toggled on', async () => {
      const user = userEvent.setup()
      setup({checked: false})

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      await user.click(checkbox)

      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/api/v1/users/self/settings',
        method: 'PUT',
        body: {comment_library_suggestions_enabled: true},
      })
    })

    it('calls API with correct settings when toggled off', async () => {
      const user = userEvent.setup()
      setup({checked: true})

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      await user.click(checkbox)

      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/api/v1/users/self/settings',
        method: 'PUT',
        body: {comment_library_suggestions_enabled: false},
      })
    })
  })

  describe('Error Handling Tests', () => {
    it('shows error flash alert when API call fails', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = jest.spyOn(FlashAlert, 'showFlashAlert')
      ;(doFetchApi as jest.Mock).mockRejectedValue(new Error('API error'))

      setup({checked: false})

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      await user.click(checkbox)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Error saving suggestion preference',
          type: 'error',
        })
      })
    })

    it('still calls onChange callback even when API fails', async () => {
      const user = userEvent.setup()
      const onChange = jest.fn()
      ;(doFetchApi as jest.Mock).mockRejectedValue(new Error('API error'))

      setup({checked: false, onChange})

      const checkbox = screen.getByTestId('suggestions-when-typing-toggle')
      await user.click(checkbox)

      expect(onChange).toHaveBeenCalledWith(true)
    })
  })
})
