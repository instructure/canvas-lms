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
import {fireEvent, render, waitFor} from '@testing-library/react'
import RegenerateCriteria from '../RegenerateCriteria'

describe('RegenerateCriteria', () => {
  const defaultProps = {
    buttonColor: 'ai-primary' as const,
    onRegenerate: vi.fn(),
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders the regenerate button', () => {
    const {getByTestId} = render(<RegenerateCriteria {...defaultProps} />)
    expect(getByTestId('regenerate-criteria-button')).toBeInTheDocument()
  })

  it('opens modal when regenerate button is clicked', async () => {
    const {getByTestId, getByText} = render(<RegenerateCriteria {...defaultProps} />)

    fireEvent.click(getByTestId('regenerate-criteria-button'))

    await waitFor(() => {
      expect(getByText('Regenerate Criteria')).toBeInTheDocument()
    })
  })

  it('shows "Regenerate Criterion" title when isCriterion is true', async () => {
    const {getByTestId, getByText} = render(
      <RegenerateCriteria {...defaultProps} isCriterion={true} />,
    )

    fireEvent.click(getByTestId('regenerate-criteria-button'))

    await waitFor(() => {
      expect(getByText('Regenerate Criterion')).toBeInTheDocument()
    })
  })

  it('validates the additional prompt input - shows error for text over 1000 characters', async () => {
    const {getByTestId, getByText} = render(<RegenerateCriteria {...defaultProps} />)

    fireEvent.click(getByTestId('regenerate-criteria-button'))

    await waitFor(() => {
      expect(getByText('Regenerate Criteria')).toBeInTheDocument()
    })

    expect(getByTestId('regenerate-criteria-submit-button')).toBeEnabled()

    const additionalPromptInput = getByTestId('additional-prompt-textarea')
    const longText = 'a'.repeat(1001)

    fireEvent.change(additionalPromptInput, {target: {value: longText}})

    expect(
      getByText('Additional prompt information must be less than 1000 characters'),
    ).toBeInTheDocument()
    expect(getByTestId('regenerate-criteria-submit-button')).toBeDisabled()
  })

  it('allows submission with text under 1000 characters', async () => {
    const {getByTestId, getByText, queryByText} = render(<RegenerateCriteria {...defaultProps} />)

    fireEvent.click(getByTestId('regenerate-criteria-button'))

    await waitFor(() => {
      expect(getByText('Regenerate Criteria')).toBeInTheDocument()
    })

    const additionalPromptInput = getByTestId('additional-prompt-textarea')
    const validText = 'a'.repeat(1000)

    fireEvent.change(additionalPromptInput, {target: {value: validText}})

    expect(
      queryByText('Additional prompt information must be less than 1000 characters'),
    ).not.toBeInTheDocument()
    expect(getByTestId('regenerate-criteria-submit-button')).toBeEnabled()
  })

  it('calls onRegenerate with the additional prompt when submitted', async () => {
    const onRegenerate = vi.fn()
    const {getByTestId, getByText} = render(
      <RegenerateCriteria {...defaultProps} onRegenerate={onRegenerate} />,
    )

    fireEvent.click(getByTestId('regenerate-criteria-button'))

    await waitFor(() => {
      expect(getByText('Regenerate Criteria')).toBeInTheDocument()
    })

    const additionalPromptInput = getByTestId('additional-prompt-textarea')
    fireEvent.change(additionalPromptInput, {target: {value: 'Test prompt'}})

    fireEvent.click(getByTestId('regenerate-criteria-submit-button'))

    expect(onRegenerate).toHaveBeenCalledWith('Test prompt')
  })

  it('closes modal and clears input when cancel is clicked', async () => {
    const {getByTestId, getByText, queryByText} = render(<RegenerateCriteria {...defaultProps} />)

    fireEvent.click(getByTestId('regenerate-criteria-button'))

    await waitFor(() => {
      expect(getByText('Regenerate Criteria')).toBeInTheDocument()
    })

    const additionalPromptInput = getByTestId('additional-prompt-textarea')
    fireEvent.change(additionalPromptInput, {target: {value: 'Some text'}})

    fireEvent.click(getByTestId('regenerate-criteria-cancel-button'))

    await waitFor(() => {
      expect(queryByText('Regenerate Criteria')).not.toBeInTheDocument()
    })

    // Reopen to verify input was cleared
    fireEvent.click(getByTestId('regenerate-criteria-button'))

    await waitFor(() => {
      expect(getByText('Regenerate Criteria')).toBeInTheDocument()
    })

    expect(getByTestId('additional-prompt-textarea')).toHaveValue('')
  })

  it('disables the button when disabled prop is true', () => {
    const {getByTestId} = render(<RegenerateCriteria {...defaultProps} disabled={true} />)
    expect(getByTestId('regenerate-criteria-button')).toBeDisabled()
  })
})
