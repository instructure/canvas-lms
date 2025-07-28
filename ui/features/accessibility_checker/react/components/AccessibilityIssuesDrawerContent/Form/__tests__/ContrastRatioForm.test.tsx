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
import {render, screen, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ContrastRatioForm from '../ContrastRatioForm'

describe('ContrastRatioForm', () => {
  const mockOnChange = jest.fn()

  const user = userEvent.setup()
  const defaultProps = {
    label: 'Color Contrast Ratio',
    inputLabel: 'New Color',
    backgroundColor: '#000000',
    foregroundColor: '#FFFFFF',
    contrastRatio: 8.55,
    onChange: mockOnChange,
  }

  beforeEach(() => {
    mockOnChange.mockClear()
  })

  it('renders the component with labels and contrast ratio', async () => {
    render(<ContrastRatioForm {...defaultProps} />)

    expect(screen.getByText('Color Contrast Ratio')).toBeInTheDocument()
    expect(screen.getByText('8.55:1')).toBeInTheDocument()
    expect(screen.getByText('New Color')).toBeInTheDocument()
  })

  it('renders background and foreground with correct color codes', () => {
    render(<ContrastRatioForm {...defaultProps} />)

    expect(screen.getByText('#000000')).toBeInTheDocument()
    expect(screen.getByText('#FFFFFF')).toBeInTheDocument()
  })

  it('calls onChange when ColorPicker changes color', async () => {
    render(<ContrastRatioForm {...defaultProps} />)

    const input = screen.getByLabelText(/new color/i)
    await user.clear(input)
    await user.type(input, '#ff0000')

    expect(mockOnChange).toHaveBeenCalledWith('#ff0000')
  })

  it('renders text types based on options', async () => {
    const options = ['normal', 'large']

    render(<ContrastRatioForm {...defaultProps} options={options} />)

    const normal = await screen.findByText(/NORMAL TEXT/i)
    const large = screen.getByText(/LARGE TEXT/i)

    expect(normal).toBeInTheDocument()
    expect(large).toBeInTheDocument()
  })

  it('reacts to foregroundColor prop change', () => {
    const {rerender} = render(<ContrastRatioForm {...defaultProps} />)

    expect(screen.getByText('#FFFFFF')).toBeInTheDocument()

    rerender(<ContrastRatioForm {...defaultProps} foregroundColor="#123456" />)

    expect(screen.getByText('#123456')).toBeInTheDocument()
  })

  it('displays the error message when an error is provided', () => {
    const propsWithError = {
      ...defaultProps,
      messages: [{text: 'Error message', type: 'newError' as const}],
    }
    render(<ContrastRatioForm {...propsWithError} />)
    expect(screen.getByText('Error message')).toBeInTheDocument()
  })

  it('focuses the input when the form is refocused', () => {
    const {container} = render(<ContrastRatioForm {...defaultProps} />)
    const input = container.querySelector('input')
    expect(input).not.toHaveFocus()
    input?.focus()
    expect(input).toHaveFocus()
  })
})
