/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {cleanup, render, screen} from '@testing-library/react'
import {GenerateButton} from '../GenerateButton'

describe('GenerateButton', () => {
  afterEach(() => {
    cleanup()
  })

  const defaultProps = {
    handleGenerateClick: vi.fn(),
    isLoading: false,
    buttonLabels: {initial: 'Generate', loading: 'Generating...', loaded: 'Regenerate'},
    pendoId: 'AiAltTextButtonPushed' as const,
    selectedItem: null,
    ruleId: 'test-rule',
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the generate button', () => {
    render(<GenerateButton {...defaultProps} />)
    expect(screen.getByTestId('generate-button')).toBeInTheDocument()
  })

  describe('helperTextId prop', () => {
    it('renders aria-describedby when helperTextId is provided', () => {
      render(<GenerateButton {...defaultProps} helperTextId="helper-123" />)
      expect(screen.getByTestId('generate-button')).toHaveAttribute(
        'aria-describedby',
        'helper-123',
      )
    })

    it('does not render aria-describedby when helperTextId is not provided', () => {
      render(<GenerateButton {...defaultProps} />)
      expect(screen.getByTestId('generate-button')).not.toHaveAttribute('aria-describedby')
    })
  })

  describe('pendoId prop', () => {
    it('renders data-pendo attribute with the pendoId value', () => {
      render(<GenerateButton {...defaultProps} pendoId="AiAltTextButtonPushed" />)

      const button = screen.getByTestId('generate-button')
      expect(button).toHaveAttribute('data-pendo', 'AiAltTextButtonPushed')
    })
  })
})
